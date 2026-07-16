# Build Fabric Pipeline Dashboard - Table View
# Reads pipeline JSON files and creates interactive HTML table

$pipelineFiles = Get-ChildItem -Path ".\pipelines" -Filter "*.json"
Write-Host "=== Building Pipeline Dashboard (Table View) ===" -ForegroundColor Cyan
Write-Host "Found $($pipelineFiles.Count) pipeline definitions" -ForegroundColor White

$pipelines = @()

# Parse each pipeline
foreach ($file in $pipelineFiles) {
    try {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        
        # Decode base64 content
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
        
        # Determine category
        $category = "utility"
        $name = $json.metadata.name.ToLower()
        if ($name -match "master|orchestrat|process_all") { $category = "orchestrator" }
        elseif ($name -match "bronze") { $category = "bronze" }
        elseif ($name -match "silver") { $category = "silver" }
        elseif ($name -match "gold") { $category = "gold" }
        elseif ($name -match "extract") { $category = "extract" }
        
        # Simplify activities
        $simplifiedActivities = @()
        foreach ($act in $activities) {
            $deps = @()
            if ($act.dependsOn) {
                $deps = @($act.dependsOn | ForEach-Object { $_.activity })
            }
            $simplifiedActivities += @{
                name = $act.name
                type = $act.type
                dependsOn = ,$deps
            }
        }
        
        # Count pipeline invocations
        $pipelineCallCount = 0
        foreach ($act in $activities) {
            if ($act.type -eq "ExecutePipeline" -or $act.type -eq "InvokePipeline") {
                $pipelineCallCount++
            }
        }
        
        $pipelines += @{
            id = $json.metadata.id
            name = $json.metadata.name
            category = $category
            activityCount = $activities.Count
            pipelineCallCount = $pipelineCallCount
            activities = $simplifiedActivities
            schedule = $schedule
        }
    } catch {
        Write-Host "Error processing $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Host "Parsed $($pipelines.Count) pipelines" -ForegroundColor Green

# Build relationships (incoming connections)
$incomingCounts = @{}
foreach ($p in $pipelines) {
    $incomingCounts[$p.name] = 0
}

foreach ($p in $pipelines) {
    foreach ($act in $p.activities) {
        if ($act.type -eq "ExecutePipeline" -or $act.type -eq "InvokePipeline") {
            # Find the target pipeline name
            $targetName = $null
            $originalActivity = ($p.activities | Where-Object { $_.name -eq $act.name })[0]
            
            # This is simplified - we'd need to parse the actual pipeline JSON to get real references
            # For now, just count invocations
        }
    }
}

# Convert to JSON for embedding
$pipelinesJson = $pipelines | ConvertTo-Json -Depth 10 -Compress

Write-Host "Building HTML dashboard..." -ForegroundColor White

# Create HTML
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fabric Pipeline Dashboard - Table View</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #1e1e1e;
            color: #d4d4d4;
        }
        #header {
            background: #2d2d30;
            padding: 15px 20px;
            border-bottom: 1px solid #3e3e42;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        h1 {
            font-size: 18px;
            font-weight: 600;
            color: #4fc3f7;
        }
        #controls {
            display: flex;
            gap: 10px;
            align-items: center;
            margin-top: 10px;
            flex-wrap: wrap;
        }
        .filter-btn {
            padding: 6px 14px;
            border: 1px solid #3e3e42;
            background: #252526;
            color: #d4d4d4;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            transition: background 0.2s;
        }
        .filter-btn:hover { background: #1177bb; }
        .filter-btn.active { background: #007acc; box-shadow: 0 0 10px rgba(0,122,204,0.5); }
        #search {
            padding: 6px 12px;
            border: 1px solid #3e3e42;
            background: #252526;
            color: #d4d4d4;
            border-radius: 4px;
            font-size: 12px;
            width: 300px;
        }
        #container {
            display: flex;
            height: calc(100vh - 120px);
        }
        #table-container {
            flex: 1;
            overflow: auto;
            padding: 20px;
        }
        #sidebar {
            width: 380px;
            background: #252526;
            padding: 20px;
            overflow-y: auto;
            border-left: 1px solid #3e3e42;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: #252526;
        }
        thead {
            position: sticky;
            top: 0;
            background: #1e1e1e;
            z-index: 10;
        }
        th {
            padding: 12px;
            text-align: left;
            font-size: 11px;
            font-weight: 600;
            color: #ffffff;
            background: #1e1e1e;
            text-transform: uppercase;
            border-bottom: 2px solid #007acc;
            cursor: pointer;
            user-select: none;
        }
        th:hover {
            background: #2d2d30;
            color: #4fc3f7;
        }
        th.sortable::after {
            content: '';
            opacity: 0.5;
            font-size: 10px;
            margin-left: 4px;
        }
        th.sort-asc::after {
            content: ' ASC';
            opacity: 1;
            color: #4fc3f7;
        }
        th.sort-desc::after {
            content: ' DESC';
            opacity: 1;
            color: #4fc3f7;
        }
        td {
            padding: 10px 12px;
            font-size: 13px;
            border-bottom: 1px solid #3e3e42;
        }
        tr.pipeline-row {
            cursor: pointer;
            transition: background 0.2s;
        }
        tr.pipeline-row:hover {
            background: #2d2d30;
        }
        tr.pipeline-row.expanded {
            background: #094771;
        }
        tr.activity-row {
            background: #1e1e1e;
            display: none;
        }
        tr.activity-row.visible {
            display: table-row;
        }
        tr.activity-row {
            cursor: pointer;
        }
        tr.activity-row td {
            padding: 8px 12px 8px 50px;
            font-size: 12px;
            color: #b0b0b0;
            border-bottom: 1px solid #2d2d30;
        }
        tr.activity-row:hover {
            background: #252526;
        }
        tr.activity-row.selected-activity {
            background: #2d4a5e;
        }
        .expand-icon {
            display: inline-block;
            width: 16px;
            height: 16px;
            margin-right: 8px;
            color: #858585;
            font-weight: bold;
            text-align: center;
            line-height: 16px;
            font-family: monospace;
        }
        .expand-icon.collapsed::before {
            content: '+';
            font-size: 16px;
        }
        .expand-icon.expanded::before {
            content: '-';
            font-size: 16px;
        }
        .activity-row-number {
            color: #ffeb3b;
            font-weight: bold;
            margin-right: 8px;
        }
        .activity-row-name {
            color: #4fc3f7;
        }
        .activity-row-deps {
            color: #9575cd;
            font-size: 10px;
            font-style: italic;
            display: block;
            margin-top: 4px;
            padding-left: 24px;
        }
        .notebook-badge {
            display: inline-block;
            padding: 2px 6px;
            background: #0e639c;
            color: #fff;
            border-radius: 3px;
            font-size: 10px;
            margin-left: 8px;
        }
        .category-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 10px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .cat-orchestrator { background: #ff6b6b; color: #fff; }
        .cat-bronze { background: #cd7f32; color: #fff; }
        .cat-silver { background: #c0c0c0; color: #000; }
        .cat-gold { background: #ffd700; color: #000; }
        .cat-extract { background: #9b59b6; color: #fff; }
        .cat-utility { background: #95a5a6; color: #fff; }
        .schedule-text {
            font-size: 11px;
            color: #858585;
        }
        .info-section {
            margin-bottom: 20px;
        }
        .info-label {
            color: #858585;
            font-size: 11px;
            text-transform: uppercase;
            margin-bottom: 5px;
        }
        .info-value {
            color: #d4d4d4;
            font-size: 14px;
        }
        #stats {
            margin-left: auto;
            font-size: 12px;
            color: #858585;
        }
    </style>
</head>
<body>
    <div id="header">
        <h1>[PIPELINES] Fabric Pipeline Dashboard - dev-prescriptions-process</h1>
        <div id="controls">
            <input type="text" id="search" placeholder="Search by name...">
            <button class="filter-btn active" data-category="all">All</button>
            <button class="filter-btn" data-category="orchestrator">Orchestrators</button>
            <button class="filter-btn" data-category="bronze">Bronze</button>
            <button class="filter-btn" data-category="silver">Silver</button>
            <button class="filter-btn" data-category="gold">Gold</button>
            <button class="filter-btn" data-category="extract">Extracts</button>
            <button class="filter-btn" data-category="utility">Utilities</button>
            <span id="stats">Showing: <span id="stat-visible">0</span> / <span id="stat-total">0</span></span>
        </div>
    </div>
    <div id="container">
        <div id="table-container">
            <table id="pipeline-table">
                <thead>
                    <tr>
                        <th class="sortable" data-sort="name">Pipeline Name</th>
                        <th class="sortable" data-sort="category">Category</th>
                        <th class="sortable" data-sort="activityCount">Activities</th>
                        <th class="sortable" data-sort="pipelineCallCount">Calls</th>
                        <th class="sortable" data-sort="schedule">Schedule</th>
                    </tr>
                </thead>
                <tbody id="table-body">
                </tbody>
            </table>
        </div>
        <div id="sidebar">
            <h2>Information</h2>
            <div id="sidebar-content">
                <div class="info-section">
                    <div class="info-label">How to Use</div>
                    <div class="info-value" style="font-size: 12px; line-height: 1.6;">
                        <p style="margin-bottom: 10px;">* <strong>Click pipeline rows</strong> to expand/collapse activities</p>
                        <p style="margin-bottom: 10px;">* <strong>Click activity rows</strong> to see details here</p>
                        <p style="margin-bottom: 10px;">* <strong>Click column headers</strong> to sort</p>
                        <p style="margin-bottom: 10px;">* <strong>Use search</strong> to filter by name</p>
                        <p style="margin-bottom: 10px;">* <strong>Category buttons</strong> filter by type</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        const pipelines = $pipelinesJson;
        
        let currentFilter = 'all';
        let currentSort = { column: 'name', direction: 'asc' };
        let expandedPipelines = new Set();
        let selectedActivityId = null;

        const categoryColors = {
            orchestrator: '#ff6b6b',
            bronze: '#cd7f32',
            silver: '#c0c0c0',
            gold: '#ffd700',
            extract: '#9b59b6',
            utility: '#95a5a6'
        };

        // Extract all notebook names from pipelines
        function extractNotebooks() {
            const notebooks = new Set();
            pipelines.forEach(p => {
                if (p.activities) {
                    p.activities.forEach(act => {
                        if (act.type === 'TridentNotebook') {
                            notebooks.add(act.name);
                        }
                    });
                }
            });
            return Array.from(notebooks).sort();
        }

        const allNotebooks = extractNotebooks();

        function renderTable() {
            const searchTerm = document.getElementById('search').value.toLowerCase();
            
            // Filter pipelines
            let filtered = pipelines.filter(p => {
                const categoryMatch = currentFilter === 'all' || p.category === currentFilter;
                const searchMatch = !searchTerm || p.name.toLowerCase().includes(searchTerm);
                return categoryMatch && searchMatch;
            });

            // Sort pipelines
            filtered.sort((a, b) => {
                let aVal = a[currentSort.column];
                let bVal = b[currentSort.column];
                
                if (currentSort.column === 'schedule') {
                    aVal = a.schedule ? a.schedule.configuration.type : 'zzz';
                    bVal = b.schedule ? b.schedule.configuration.type : 'zzz';
                }
                
                if (typeof aVal === 'string') {
                    return currentSort.direction === 'asc' ? 
                        aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
                } else {
                    return currentSort.direction === 'asc' ? aVal - bVal : bVal - aVal;
                }
            });

            // Render rows
            const tbody = document.getElementById('table-body');
            tbody.innerHTML = '';
            
            filtered.forEach(p => {
                const isExpanded = expandedPipelines.has(p.id);
                
                // Main pipeline row
                const tr = document.createElement('tr');
                tr.className = 'pipeline-row' + (isExpanded ? ' expanded' : '');
                tr.dataset.pipelineId = p.id;
                
                const scheduleText = p.schedule ? 
                    p.schedule.configuration.type + (p.schedule.configuration.times ? ' ' + p.schedule.configuration.times.join(', ') : '') :
                    'Manual';
                
                tr.innerHTML = '<td><span class="expand-icon ' + (isExpanded ? 'expanded' : 'collapsed') + '"></span>' + p.name + '</td>' +
                    '<td><span class="category-badge cat-' + p.category + '">' + p.category + '</span></td>' +
                    '<td>' + p.activityCount + '</td>' +
                    '<td>' + p.pipelineCallCount + '</td>' +
                    '<td class="schedule-text">' + scheduleText + '</td>';
                
                tr.addEventListener('click', () => togglePipeline(p.id));
                tbody.appendChild(tr);
                
                // Activity rows
                if (p.activities && p.activities.length > 0) {
                    p.activities.forEach((act, idx) => {
                        const actRow = document.createElement('tr');
                        const activityId = p.id + '_' + idx;
                        actRow.className = 'activity-row' + (isExpanded ? ' visible' : '') + (selectedActivityId === activityId ? ' selected-activity' : '');
                        actRow.dataset.parentId = p.id;
                        actRow.dataset.activityId = activityId;
                        
                        const deps = Array.isArray(act.dependsOn) ? act.dependsOn : (act.dependsOn ? [act.dependsOn] : []);
                        const depsText = deps.length > 0 ? '<div class="activity-row-deps">Depends on: ' + deps.join(', ') + '</div>' : '';
                        
                        const notebookBadge = act.type === 'TridentNotebook' ? '<span class="notebook-badge">NOTEBOOK</span>' : '';
                        
                        actRow.innerHTML = '<td colspan="5">' +
                            '<span class="activity-row-number">#' + (idx + 1) + '</span>' +
                            '<span class="activity-row-name">' + act.name + '</span>' +
                            notebookBadge +
                            '<span style="color: #858585; margin-left: 15px;">(' + act.type + ')</span>' +
                            depsText +
                            '</td>';
                        
                        actRow.addEventListener('click', (e) => {
                            e.stopPropagation();
                            selectActivity(activityId, act, p);
                        });
                        
                        tbody.appendChild(actRow);
                    });
                }
            });

            // Update stats
            document.getElementById('stat-visible').textContent = filtered.length;
            document.getElementById('stat-total').textContent = pipelines.length;
        }

        function togglePipeline(pipelineId) {
            if (expandedPipelines.has(pipelineId)) {
                expandedPipelines.delete(pipelineId);
            } else {
                expandedPipelines.add(pipelineId);
            }
            renderTable();
        }

        function selectActivity(activityId, activity, pipeline) {
            selectedActivityId = activityId;
            renderTable();
            
            const sidebar = document.getElementById('sidebar-content');
            const deps = Array.isArray(activity.dependsOn) ? activity.dependsOn : (activity.dependsOn ? [activity.dependsOn] : []);
            
            let content = '<div class="info-section">' +
                '<div class="info-label">Activity Details</div>' +
                '<h3 style="color: #4fc3f7; margin: 10px 0;">' + activity.name + '</h3>' +
                '</div>';
            
            content += '<div class="info-section">' +
                '<div class="info-label">Type</div>' +
                '<div class="info-value">' + activity.type + '</div>' +
                '</div>';
            
            content += '<div class="info-section">' +
                '<div class="info-label">Pipeline</div>' +
                '<div class="info-value" style="font-size: 12px;">' + pipeline.name + '</div>' +
                '</div>';
            
            if (deps.length > 0) {
                content += '<div class="info-section">' +
                    '<div class="info-label">Dependencies</div>' +
                    '<div class="info-value" style="font-size: 12px;">';
                deps.forEach(dep => {
                    content += '<div style="margin-bottom: 5px; color: #9575cd;">' + dep + '</div>';
                });
                content += '</div></div>';
            }
            
            if (activity.type === 'TridentNotebook') {
                content += '<div class="info-section">' +
                    '<div class="info-label">Notebook Information</div>' +
                    '<div class="info-value" style="font-size: 12px;">' +
                    '<p style="margin-bottom: 10px;">This activity executes a Fabric Notebook.</p>' +
                    '<p style="color: #4fc3f7;"><strong>' + activity.name + '</strong></p>' +
                    '</div></div>';
                
                // Find other pipelines using this notebook
                const otherUsages = [];
                pipelines.forEach(p => {
                    if (p.id !== pipeline.id && p.activities) {
                        p.activities.forEach(a => {
                            if (a.type === 'TridentNotebook' && a.name === activity.name) {
                                otherUsages.push(p.name);
                            }
                        });
                    }
                });
                
                if (otherUsages.length > 0) {
                    content += '<div class="info-section">' +
                        '<div class="info-label">Also Used By</div>' +
                        '<div class="info-value" style="font-size: 11px;">';
                    otherUsages.forEach(usage => {
                        content += '<div style="margin-bottom: 3px; color: #858585;">' + usage + '</div>';
                    });
                    content += '</div></div>';
                }
            }
            
            if (activity.type === 'InvokePipeline' || activity.type === 'ExecutePipeline') {
                content += '<div class="info-section">' +
                    '<div class="info-label">Pipeline Invocation</div>' +
                    '<div class="info-value" style="font-size: 12px;">' +
                    '<p>This activity calls another pipeline in the workspace.</p>' +
                    '</div></div>';
            }
            
            sidebar.innerHTML = content;
        }

        // Filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter = btn.dataset.category;
                renderTable();
            });
        });

        // Search
        document.getElementById('search').addEventListener('input', renderTable);

        // Sort
        document.querySelectorAll('th.sortable').forEach(th => {
            th.addEventListener('click', () => {
                const column = th.dataset.sort;
                if (currentSort.column === column) {
                    currentSort.direction = currentSort.direction === 'asc' ? 'desc' : 'asc';
                } else {
                    currentSort.column = column;
                    currentSort.direction = 'asc';
                }
                
                // Update sort indicators
                document.querySelectorAll('th.sortable').forEach(h => {
                    h.classList.remove('sort-asc', 'sort-desc');
                });
                th.classList.add('sort-' + currentSort.direction);
                
                renderTable();
            });
        });

        // Initial render
        renderTable();
    </script>
</body>
</html>
"@

$outputPath = ".\pipeline-dashboard-table.html"
$htmlContent | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[OK] Table dashboard created: $outputPath" -ForegroundColor Green
Write-Host "Open in browser to view tabular visualization" -ForegroundColor White
