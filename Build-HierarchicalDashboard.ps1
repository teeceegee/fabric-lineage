<#
.SYNOPSIS
    Creates hierarchical pipeline dashboard with sequential layout
#>

param(
    [string]$PipelineDir = ".\pipelines\",
    [string]$OutputFile = ".\pipeline-dashboard.html"
)

Write-Host "=== Building Hierarchical Pipeline Dashboard ===" -ForegroundColor Cyan

$pipelineFiles = Get-ChildItem -Path $PipelineDir -Filter "*.json" | 
    Where-Object { $_.Name -notin @("export_summary.json", "pipeline_inventory.json") }

$pipelines = @()

foreach ($file in $pipelineFiles) {
    try {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        
        $contentPart = $json.definition.parts | Where-Object { $_.path -eq "pipeline-content.json" }
        $schedulePart = $json.definition.parts | Where-Object { $_.path -eq ".schedules" }
        
        $activities = @()
        $schedule = $null
        
        if ($contentPart) {
            $contentBytes = [System.Convert]::FromBase64String($contentPart.payload)
            $contentJson = [System.Text.Encoding]::UTF8.GetString($contentBytes) | ConvertFrom-Json
            $activities = $contentJson.properties.activities
        }
        
        if ($schedulePart) {
            $scheduleBytes = [System.Convert]::FromBase64String($schedulePart.payload)
            $scheduleJson = [System.Text.Encoding]::UTF8.GetString($scheduleBytes) | ConvertFrom-Json
            if ($scheduleJson.schedules -and $scheduleJson.schedules.Count -gt 0) {
                $schedule = $scheduleJson.schedules[0]
            }
        }
        
        $references = @()
        for ($i = 0; $i -lt $activities.Count; $i++) {
            $activity = $activities[$i]
            # Check for both ExecutePipeline and InvokePipeline activity types
            if ($activity.type -eq "ExecutePipeline" -or $activity.type -eq "InvokePipeline") {
                $dependsOnList = @()
                if ($activity.dependsOn) {
                    foreach ($dep in $activity.dependsOn) {
                        $dependsOnList += $dep.activity
                    }
                }
                
                # Get target pipeline ID - different structure for ExecutePipeline vs InvokePipeline
                $targetId = $null
                if ($activity.type -eq "ExecutePipeline") {
                    $targetId = $activity.typeProperties.pipeline.referenceName
                }
                elseif ($activity.type -eq "InvokePipeline") {
                    $targetId = $activity.typeProperties.pipelineId
                }
                
                if ($targetId) {
                    $references += @{
                        targetId = $targetId
                        activityName = $activity.name
                        dependsOn = $dependsOnList
                        order = ($i + 1)
                    }
                }
            }
        }
        
        $pipelines += @{
            id = $json.metadata.id
            name = $json.metadata.name
            type = $json.metadata.type
            activityCount = $activities.Count
            activities = $activities
            references = $references
            schedule = $schedule
        }
        
    } catch {
        Write-Warning "Failed to parse $($file.Name): $_"
    }
}

Write-Host "Parsed $($pipelines.Count) pipelines" -ForegroundColor Green

$pipelineNameLookup = @{}
foreach ($p in $pipelines) {
    $pipelineNameLookup[$p.id] = $p.name
}

$nodes = @()
$links = @()

foreach ($p in $pipelines) {
    $category = "utility"
    if ($p.name -match "bronze") { $category = "bronze" }
    elseif ($p.name -match "silver") { $category = "silver" }
    elseif ($p.name -match "gold") { $category = "gold" }
    elseif ($p.name -match "master|_all$") { $category = "orchestrator" }
    elseif ($p.name -match "BAU|extract") { $category = "extract" }
    
    $scheduleType = "none"
    if ($p.schedule) {
        $scheduleType = $p.schedule.configuration.type
    }
    
    $nodes += @{
        id = $p.id
        name = $p.name
        category = $category
        activityCount = $p.activityCount
        scheduleType = $scheduleType
        schedule = $p.schedule
    }
    
    foreach ($ref in $p.references) {
        $targetName = $pipelineNameLookup[$ref.targetId]
        if ($targetName) {
            $links += @{
                source = $p.id
                target = $ref.targetId
                activityName = $ref.activityName
                dependsOn = $ref.dependsOn
                order = $ref.order
            }
        }
    }
}

$nodesJson = $nodes | ConvertTo-Json -Depth 10 -Compress
$linksJson = $links | ConvertTo-Json -Depth 10 -Compress

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fabric Pipeline Dashboard - Hierarchical View</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #1e1e1e;
            color: #d4d4d4;
            overflow: hidden;
        }
        #header {
            background: #2d2d30;
            padding: 15px 20px;
            border-bottom: 2px solid #007acc;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        h1 {
            color: #4fc3f7;
            font-size: 24px;
            font-weight: 300;
        }
        #controls {
            display: flex;
            gap: 15px;
            align-items: center;
        }
        .filter-btn {
            background: #0e639c;
            border: none;
            color: white;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 13px;
            transition: background 0.2s;
        }
        .filter-btn:hover { background: #1177bb; }
        .filter-btn.active { background: #007acc; box-shadow: 0 0 10px rgba(0,122,204,0.5); }
        #search {
            padding: 8px 12px;
            border: 1px solid #3e3e42;
            background: #252526;
            color: #d4d4d4;
            border-radius: 4px;
            font-size: 13px;
            width: 250px;
        }
        .layout-toggle {
            background: #2d2d30;
            border: 1px solid #007acc;
            color: #4fc3f7;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 13px;
        }
        .layout-toggle:hover { background: #3e3e42; }
        #container {
            display: flex;
            height: calc(100vh - 65px);
        }
        #graph {
            flex: 1;
            position: relative;
        }
        #sidebar {
            width: 350px;
            background: #252526;
            border-left: 1px solid #3e3e42;
            overflow-y: auto;
            padding: 20px;
        }
        #sidebar h2 {
            color: #4fc3f7;
            font-size: 18px;
            margin-bottom: 15px;
            font-weight: 400;
        }
        .info-section {
            margin-bottom: 20px;
        }
        .info-label {
            color: #858585;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 5px;
        }
        .info-value {
            color: #d4d4d4;
            font-size: 14px;
            margin-bottom: 12px;
        }
        .legend {
            position: absolute;
            top: 20px;
            left: 20px;
            background: rgba(45, 45, 48, 0.95);
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #3e3e42;
        }
        .legend-title {
            color: #4fc3f7;
            font-size: 14px;
            margin-bottom: 10px;
            font-weight: 500;
        }
        .legend-item {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 8px;
            font-size: 12px;
        }
        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 50%;
        }
        .stats {
            position: absolute;
            bottom: 20px;
            left: 20px;
            background: rgba(45, 45, 48, 0.95);
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #3e3e42;
            font-size: 12px;
        }
        .stat-item {
            margin-bottom: 5px;
        }
        .stat-label {
            color: #858585;
        }
        .stat-value {
            color: #4fc3f7;
            font-weight: 500;
        }
        svg {
            width: 100%;
            height: 100%;
        }
        .node {
            cursor: pointer;
            stroke: #1e1e1e;
            stroke-width: 2px;
        }
        .node:hover {
            stroke: #4fc3f7;
            stroke-width: 3px;
        }
        .node.selected {
            stroke: #ffeb3b;
            stroke-width: 4px;
        }
        .link {
            stroke: #3e3e42;
            stroke-opacity: 0.6;
            stroke-width: 2px;
            fill: none;
        }
        .link.highlighted {
            stroke: #4fc3f7;
            stroke-opacity: 1;
            stroke-width: 3px;
        }
        .node-label {
            fill: #d4d4d4;
            font-size: 11px;
            pointer-events: none;
            text-anchor: middle;
        }
        .sequence-label {
            fill: #ffeb3b;
            font-size: 14px;
            font-weight: bold;
            pointer-events: none;
            text-anchor: middle;
            stroke: #1e1e1e;
            stroke-width: 0.5px;
            paint-order: stroke;
        }
        .empty-state {
            color: #858585;
            font-style: italic;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <div id="header">
        <h1>[PIPELINES] Fabric Pipeline Dashboard - Hierarchical View</h1>
        <div id="controls">
            <button class="layout-toggle" onclick="toggleLayout()">Toggle Layout</button>
            <input type="text" id="search" placeholder="Search pipelines...">
            <button class="filter-btn active" data-category="all">All</button>
            <button class="filter-btn" data-category="orchestrator">Orchestrators</button>
            <button class="filter-btn" data-category="bronze">Bronze</button>
            <button class="filter-btn" data-category="silver">Silver</button>
            <button class="filter-btn" data-category="gold">Gold</button>
            <button class="filter-btn" data-category="extract">Extracts</button>
        </div>
    </div>
    <div id="container">
        <div id="graph">
            <div class="legend">
                <div class="legend-title">Pipeline Types</div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #ff6b6b;"></div>
                    <span>Orchestrator</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #cd7f32;"></div>
                    <span>Bronze Layer</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #c0c0c0;"></div>
                    <span>Silver Layer</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #ffd700;"></div>
                    <span>Gold Layer</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #4fc3f7;"></div>
                    <span>Extract</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #9575cd;"></div>
                    <span>Utility</span>
                </div>
            </div>
            <div class="stats">
                <div class="stat-item">
                    <span class="stat-label">Total Pipelines: </span>
                    <span class="stat-value" id="stat-total">0</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Visible: </span>
                    <span class="stat-value" id="stat-visible">0</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Dependencies: </span>
                    <span class="stat-value" id="stat-links">0</span>
                </div>
            </div>
        </div>
        <div id="sidebar">
            <h2>Pipeline Details</h2>
            <div class="empty-state">Select a pipeline node to view details</div>
        </div>
    </div>

    <script>
        const nodes = $nodesJson;
        const links = $linksJson;
        
        const categoryColors = {
            orchestrator: '#ff6b6b',
            bronze: '#cd7f32',
            silver: '#c0c0c0',
            gold: '#ffd700',
            extract: '#4fc3f7',
            utility: '#9575cd'
        };

        let currentFilter = 'all';
        let selectedNode = null;
        let useHierarchical = true;

        const container = d3.select('#graph');
        const width = container.node().clientWidth;
        const height = container.node().clientHeight;

        const svg = container.append('svg').attr('width', width).attr('height', height);
        const g = svg.append('g');

        const zoom = d3.zoom().scaleExtent([0.1, 4]).on('zoom', (event) => {
            g.attr('transform', event.transform);
        });
        svg.call(zoom);

        // Create simulation
        let simulation;
        
        function initSimulation(hierarchical) {
            if (hierarchical) {
                // Hierarchical layout - vertical
                simulation = d3.forceSimulation(nodes)
                    .force('link', d3.forceLink(links).id(d => d.id).distance(200))
                    .force('charge', d3.forceManyBody().strength(-1000))
                    .force('y', d3.forceY(d => {
                        // Position based on category
                        if (d.category === 'orchestrator') return height * 0.15;
                        if (d.category === 'bronze') return height * 0.35;
                        if (d.category === 'silver') return height * 0.55;
                        if (d.category === 'gold') return height * 0.75;
                        if (d.category === 'extract') return height * 0.45;
                        return height * 0.85;
                    }).strength(0.8))
                    .force('x', d3.forceX(width / 2).strength(0.1))
                    .force('collision', d3.forceCollide().radius(50));
            } else {
                // Force-directed layout
                simulation = d3.forceSimulation(nodes)
                    .force('link', d3.forceLink(links).id(d => d.id).distance(150))
                    .force('charge', d3.forceManyBody().strength(-800))
                    .force('center', d3.forceCenter(width / 2, height / 2))
                    .force('collision', d3.forceCollide().radius(40));
            }
        }

        initSimulation(true);

        const link = g.append('g').selectAll('path').data(links).join('path')
            .attr('class', 'link')
            .attr('marker-end', 'url(#arrowhead)');

        svg.append('defs').append('marker').attr('id', 'arrowhead')
            .attr('viewBox', '0 -5 10 10').attr('refX', 25).attr('refY', 0)
            .attr('markerWidth', 6).attr('markerHeight', 6).attr('orient', 'auto')
            .append('path').attr('d', 'M0,-5L10,0L0,5').attr('fill', '#3e3e42');

        const node = g.append('g').selectAll('circle').data(nodes).join('circle')
            .attr('class', 'node')
            .attr('r', d => 15 + (d.activityCount * 0.5))
            .attr('fill', d => categoryColors[d.category])
            .call(d3.drag()
                .on('start', dragstarted)
                .on('drag', dragged)
                .on('end', dragended))
            .on('click', (event, d) => { event.stopPropagation(); selectNode(d); });

        const label = g.append('g').selectAll('text').data(nodes).join('text')
            .attr('class', 'node-label').attr('dy', 35)
            .text(d => d.name.length > 25 ? d.name.substring(0, 25) + '...' : d.name);

        // Add sequence numbers to links
        const sequenceLabel = g.append('g').selectAll('text').data(links).join('text')
            .attr('class', 'sequence-label')
            .text((d, i) => d.order !== undefined ? (d.order + 1) : '');

        simulation.on('tick', () => {
            link.attr('d', d => {
                const dx = d.target.x - d.source.x;
                const dy = d.target.y - d.source.y;
                const dr = Math.sqrt(dx * dx + dy * dy);
                return `M${d.source.x},${d.source.y}A${dr},${dr} 0 0,1 ${d.target.x},${d.target.y}`;
            });
            node.attr('cx', d => d.x).attr('cy', d => d.y);
            label.attr('x', d => d.x).attr('y', d => d.y);
            sequenceLabel
                .attr('x', d => (d.source.x + d.target.x) / 2)
                .attr('y', d => (d.source.y + d.target.y) / 2);
        });

        function dragstarted(event, d) {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x; d.fy = d.y;
        }
        function dragged(event, d) { d.fx = event.x; d.fy = event.y; }
        function dragended(event, d) {
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null; d.fy = null;
        }

        function selectNode(d) {
            selectedNode = d;
            node.classed('selected', n => n.id === d.id);
            link.classed('highlighted', l => l.source.id === d.id || l.target.id === d.id);
            updateSidebar(d);
        }

        function updateSidebar(d) {
            const sidebar = d3.select('#sidebar');
            const scheduleText = d.schedule ? 
                `${d.schedule.configuration.type} - ${d.schedule.configuration.times ? d.schedule.configuration.times.join(', ') : 'N/A'}` :
                'No schedule';
            const incoming = links.filter(l => l.target.id === d.id).length;
            const outgoing = links.filter(l => l.source.id === d.id).length;
            
            sidebar.html(`
                <h2>${d.name}</h2>
                <div class="info-section">
                    <div class="info-label">Category</div>
                    <div class="info-value" style="color: ${categoryColors[d.category]}">${d.category.toUpperCase()}</div>
                </div>
                <div class="info-section">
                    <div class="info-label">Activities</div>
                    <div class="info-value">${d.activityCount} activities</div>
                </div>
                <div class="info-section">
                    <div class="info-label">Dependencies</div>
                    <div class="info-value">${incoming} incoming, ${outgoing} outgoing</div>
                </div>
                <div class="info-section">
                    <div class="info-label">Schedule</div>
                    <div class="info-value">${scheduleText}</div>
                </div>
                <div class="info-section">
                    <div class="info-label">Pipeline ID</div>
                    <div class="info-value" style="font-size: 10px; word-break: break-all;">${d.id}</div>
                </div>
            `);
        }

        function toggleLayout() {
            useHierarchical = !useHierarchical;
            nodes.forEach(n => { n.fx = null; n.fy = null; });
            initSimulation(useHierarchical);
            simulation.on('tick', () => {
                link.attr('d', d => {
                    const dx = d.target.x - d.source.x;
                    const dy = d.target.y - d.source.y;
                    const dr = Math.sqrt(dx * dx + dy * dy);
                    return `M${d.source.x},${d.source.y}A${dr},${dr} 0 0,1 ${d.target.x},${d.target.y}`;
                });
                node.attr('cx', d => d.x).attr('cy', d => d.y);
                label.attr('x', d => d.x).attr('y', d => d.y);
                sequenceLabel
                    .attr('x', d => (d.source.x + d.target.x) / 2)
                    .attr('y', d => (d.source.y + d.target.y) / 2);
            });
            simulation.alpha(1).restart();
        }

        d3.selectAll('.filter-btn').on('click', function() {
            const category = d3.select(this).attr('data-category');
            d3.selectAll('.filter-btn').classed('active', false);
            d3.select(this).classed('active', true);
            currentFilter = category;
            applyFilter();
        });

        d3.select('#search').on('input', applyFilter);

        function applyFilter() {
            const searchTerm = d3.select('#search').property('value').toLowerCase();
            node.style('opacity', d => {
                const categoryMatch = currentFilter === 'all' || d.category === currentFilter;
                const searchMatch = !searchTerm || d.name.toLowerCase().includes(searchTerm);
                return (categoryMatch && searchMatch) ? 1 : 0.1;
            });
            label.style('opacity', d => {
                const categoryMatch = currentFilter === 'all' || d.category === currentFilter;
                const searchMatch = !searchTerm || d.name.toLowerCase().includes(searchTerm);
                return (categoryMatch && searchMatch) ? 1 : 0.1;
            });
            const visibleCount = nodes.filter(d => {
                const categoryMatch = currentFilter === 'all' || d.category === currentFilter;
                const searchMatch = !searchTerm || d.name.toLowerCase().includes(searchTerm);
                return categoryMatch && searchMatch;
            }).length;
            d3.select('#stat-visible').text(visibleCount);
        }

        svg.on('click', () => {
            node.classed('selected', false);
            link.classed('highlighted', false);
            d3.select('#sidebar').html('<h2>Pipeline Details</h2><div class="empty-state">Select a pipeline node to view details</div>');
        });

        d3.select('#stat-total').text(nodes.length);
        d3.select('#stat-visible').text(nodes.length);
        d3.select('#stat-links').text(links.length);
    </script>
</body>
</html>
"@

$html | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "[OK] Hierarchical dashboard created: $OutputFile" -ForegroundColor Green
