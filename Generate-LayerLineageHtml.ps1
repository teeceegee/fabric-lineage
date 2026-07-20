<#
.SYNOPSIS
    Generates a standalone HTML view for browsing pipeline lineage across layers.
#>

param(
    [string]$PipelineDir = ".\pipelines\",
    [string]$OutputFile = ".\pipeline-lineage.html"
)

function Get-PipelineCategory {
    param([string]$Name)

    if ($Name -match "bronze") { return "bronze" }
    if ($Name -match "silver") { return "silver" }
    if ($Name -match "gold") { return "gold" }
    if ($Name -match "master|_all$") { return "orchestrator" }
    if ($Name -match "BAU|extract") { return "extract" }
    return "utility"
}

function Get-DomainName {
    param([string]$Name)

    $rules = @(
        @{ Pattern = "finance"; Name = "Finance" },
        @{ Pattern = "eps"; Name = "EPS" },
        @{ Pattern = "llf"; Name = "LLF" },
        @{ Pattern = "cip"; Name = "CIP" },
        @{ Pattern = "mys"; Name = "MYS" },
        @{ Pattern = "etp"; Name = "ETP" },
        @{ Pattern = "epact"; Name = "ePACT" },
        @{ Pattern = "sow11"; Name = "SOW11" },
        @{ Pattern = "sow4"; Name = "SOW4" },
        @{ Pattern = "semantic model"; Name = "Semantic Model" },
        @{ Pattern = "table maintenance"; Name = "Maintenance" },
        @{ Pattern = "csv"; Name = "CSV Utility" },
        @{ Pattern = "bau"; Name = "BAU Extracts" }
    )

    foreach ($rule in $rules) {
        if ($Name -match $rule.Pattern) {
            return $rule.Name
        }
    }

    return "Shared or Utility"
}

function Get-ReferenceTargetId {
    param($Activity)

    if ($Activity.type -eq "ExecutePipeline" -and $Activity.typeProperties.pipeline.referenceName) {
        return $Activity.typeProperties.pipeline.referenceName
    }

    if ($Activity.type -eq "InvokePipeline" -and $Activity.typeProperties.pipelineId) {
        return $Activity.typeProperties.pipelineId
    }

    return $null
}

function Get-LayerRank {
    param([string]$Category)

    switch ($Category) {
        "extract" { return 1 }
        "orchestrator" { return 2 }
        "bronze" { return 3 }
        "silver" { return 4 }
        "gold" { return 5 }
        default { return 9 }
    }
}

function Decode-PipelineActivities {
    param($PipelineJson)

    $contentPart = $PipelineJson.definition.parts | Where-Object { $_.path -eq "pipeline-content.json" } | Select-Object -First 1
    if (-not $contentPart) {
        return @()
    }

    $contentBytes = [System.Convert]::FromBase64String($contentPart.payload)
    $contentJson = [System.Text.Encoding]::UTF8.GetString($contentBytes) | ConvertFrom-Json
    return @($contentJson.properties.activities)
}

Write-Host "=== Generating Layer Lineage HTML ===" -ForegroundColor Cyan

$pipelineFiles = Get-ChildItem -Path $PipelineDir -Filter "*.json" |
    Where-Object { $_.Name -notin @("export_summary.json", "pipeline_inventory.json") }

$pipelines = @()

foreach ($file in $pipelineFiles) {
    try {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $activities = Decode-PipelineActivities -PipelineJson $json
        $references = @()

        for ($i = 0; $i -lt $activities.Count; $i++) {
            $activity = $activities[$i]
            if ($activity.type -in @("ExecutePipeline", "InvokePipeline")) {
                $targetId = Get-ReferenceTargetId -Activity $activity
                if ($targetId) {
                    $references += [pscustomobject]@{
                        ActivityName = $activity.name
                        TargetId = $targetId
                        Order = $i + 1
                    }
                }
            }
        }

        $pipelines += [pscustomobject]@{
            Id = $json.metadata.id
            Name = $json.metadata.name
            FileName = $file.Name
            Category = Get-PipelineCategory -Name $json.metadata.name
            Domain = Get-DomainName -Name $json.metadata.name
            ActivityCount = $activities.Count
            Activities = $activities
            References = $references
        }
    }
    catch {
        Write-Warning "Failed to parse $($file.Name): $_"
    }
}

$pipelineLookup = @{}
foreach ($pipeline in $pipelines) {
    $pipelineLookup[$pipeline.Id] = $pipeline
}

$links = @()
foreach ($pipeline in $pipelines) {
    foreach ($reference in $pipeline.References) {
        if ($pipelineLookup.ContainsKey($reference.TargetId)) {
            $target = $pipelineLookup[$reference.TargetId]
            $links += [pscustomobject]@{
                SourceName = $pipeline.Name
                SourceCategory = $pipeline.Category
                SourceDomain = $pipeline.Domain
                TargetName = $target.Name
                TargetCategory = $target.Category
                TargetDomain = $target.Domain
                ActivityName = $reference.ActivityName
                Order = $reference.Order
            }
        }
    }
}

$categoryCounts = $pipelines | Group-Object Category | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{
        category = $_.Name
        count = $_.Count
    }
}

$transitionCounts = $links |
    Where-Object { $_.SourceCategory -ne $_.TargetCategory } |
    Group-Object SourceCategory, TargetCategory |
    Sort-Object Name |
    ForEach-Object {
        $parts = $_.Name -split ", "
        [pscustomobject]@{
            source = $parts[0]
            target = $parts[1]
            count = $_.Count
            samples = @($_.Group | Select-Object -First 3 | ForEach-Object { "$($_.SourceName) -> $($_.TargetName)" })
        }
    }

$domains = @()
foreach ($group in ($pipelines | Group-Object Domain | Sort-Object Name)) {
    $domainPipelines = @($group.Group | Sort-Object { Get-LayerRank -Category $_.Category }, Name)
    $domainLinks = @($links | Where-Object { $_.SourceDomain -eq $group.Name -or $_.TargetDomain -eq $group.Name } | Sort-Object Order, SourceName, TargetName)
    $hasExplicitLinks = $domainLinks.Count -gt 0
    $connectedNames = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($link in $domainLinks) {
        [void]$connectedNames.Add($link.SourceName)
        [void]$connectedNames.Add($link.TargetName)
    }

    $graphNames = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($pipeline in $domainPipelines) { [void]$graphNames.Add($pipeline.Name) }
    foreach ($link in $domainLinks) {
        [void]$graphNames.Add($link.SourceName)
        [void]$graphNames.Add($link.TargetName)
    }

    $graphPipelines = @($pipelines |
        Where-Object {
            $_.Category -in @("extract", "orchestrator", "bronze", "silver", "gold") -and
            (
                ((-not $hasExplicitLinks) -and $graphNames.Contains($_.Name)) -or
                ($hasExplicitLinks -and $connectedNames.Contains($_.Name))
            )
        } |
        Sort-Object { Get-LayerRank -Category $_.Category }, Name)
    $inferredPath = @($domainPipelines | Where-Object { $_.Category -in @("extract", "orchestrator", "bronze", "silver", "gold") } | ForEach-Object { $_.Category } | Select-Object -Unique)
    $lineagePipelines = @($domainPipelines |
        Where-Object {
            if ($hasExplicitLinks) {
                return $connectedNames.Contains($_.Name)
            }

            return $_.Category -in @("extract", "orchestrator", "bronze", "silver", "gold")
        } |
        Sort-Object { Get-LayerRank -Category $_.Category }, Name)
    $supportingPipelines = @($domainPipelines |
        Where-Object { $lineagePipelines.Name -notcontains $_.Name } |
        Sort-Object { Get-LayerRank -Category $_.Category }, Name)
    $gapPipelines = @($domainPipelines |
        Where-Object {
            $_.Category -in @("bronze", "silver", "gold") -and
            $_.References.Count -eq 0 -and
            ($_.Activities | Where-Object { $_.type -in @("Lookup", "ForEach", "TridentNotebook") }).Count -gt 0
        } |
        Sort-Object Name |
        ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
                category = $_.Category
                activityTypes = @($_.Activities | ForEach-Object { $_.type } | Select-Object -Unique)
            }
        })

    $domains += [pscustomobject]@{
        name = $group.Name
        inferredPath = $inferredPath
        lineagePipelines = @($lineagePipelines | ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
                category = $_.Category
                activityCount = $_.ActivityCount
                fileName = $_.FileName
            }
        })
        supportingPipelines = @($supportingPipelines | ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
                category = $_.Category
                activityCount = $_.ActivityCount
                fileName = $_.FileName
            }
        })
        graphPipelines = @($graphPipelines | ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
                category = $_.Category
                domain = $_.Domain
                activityCount = $_.ActivityCount
            }
        })
        links = @($domainLinks | ForEach-Object {
            [pscustomobject]@{
                sourceName = $_.SourceName
                sourceCategory = $_.SourceCategory
                targetName = $_.TargetName
                targetCategory = $_.TargetCategory
                activityName = $_.ActivityName
            }
        })
        gapPipelines = $gapPipelines
    }
}

$pageData = [pscustomobject]@{
    generatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    pipelineCount = $pipelines.Count
    linkCount = $links.Count
    categories = $categoryCounts
    transitions = $transitionCounts
    domains = $domains
}

$pageDataJson = $pageData | ConvertTo-Json -Depth 12 -Compress

$html = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pipeline Layer Lineage</title>
    <style>
        :root {
            --bg: #f0f4f5;
            --panel: #ffffff;
            --panel-2: #e7f1f8;
            --panel-3: #f9fbfc;
            --text: #212b32;
            --muted: #5f6b73;
            --line: #d8dde0;
            --accent: #005eb8;
            --accent-dark: #003087;
            --extract: #4d7cfe;
            --orchestrator: #00857c;
            --bronze: #b26a2d;
            --silver: #7b8794;
            --gold: #b58900;
            --utility: #6f7782;
            --danger: #c43d2f;
            --shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        * { box-sizing: border-box; }
        html { scroll-behavior: smooth; }
        body {
            margin: 0;
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            background: var(--bg);
            color: var(--text);
        }

        a { color: inherit; }

        .shell {
            max-width: 1480px;
            margin: 0 auto;
            padding: 0 20px 28px 20px;
        }

        .hero {
            background: var(--panel);
            border-bottom: 2px solid var(--accent-dark);
            border-left: 1px solid var(--line);
            border-right: 1px solid var(--line);
            border-radius: 0 0 10px 10px;
            padding: 18px 20px 20px 20px;
            box-shadow: var(--shadow);
            position: static;
            margin-bottom: 20px;
        }

        .hero-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 22px;
            align-items: start;
        }

        .eyebrow {
            color: var(--accent);
            font-size: 11px;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            margin-bottom: 8px;
            font-weight: 600;
        }

        h1 {
            margin: 0;
            font-size: 18px;
            line-height: 1.2;
            font-weight: 600;
            color: var(--accent);
        }

        .subtitle {
            color: var(--muted);
            font-size: 13px;
            line-height: 1.55;
            margin-top: 10px;
            max-width: 88ch;
        }

        .meta {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-top: 18px;
        }

        .meta-chip {
            background: #ffffff;
            border: 1px solid var(--line);
            color: var(--muted);
            border-radius: 999px;
            padding: 8px 12px;
            font-size: 12px;
        }

        .summary-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }

        .summary-card {
            background: var(--panel-3);
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 16px;
        }

        .summary-card strong {
            display: block;
            font-size: 24px;
            margin-bottom: 6px;
            color: var(--accent);
        }

        .summary-card span {
            color: var(--muted);
            font-size: 13px;
        }

        .legend,
        .transition-grid,
        .domain-nav,
        .domain-list {
            margin-top: 22px;
        }

        .legend {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }

        .legend-chip,
        .jump-link,
        .path-chip,
        .badge {
            border-radius: 4px;
            padding: 8px 12px;
            font-size: 12px;
            border: 1px solid transparent;
        }

        .legend-chip {
            background: #ffffff;
            color: var(--text);
        }

        .legend-chip[data-category="extract"] { border-color: rgba(77, 124, 254, 0.55); }
        .legend-chip[data-category="orchestrator"] { border-color: rgba(32, 180, 134, 0.55); }
        .legend-chip[data-category="bronze"] { border-color: rgba(185, 122, 61, 0.55); }
        .legend-chip[data-category="silver"] { border-color: rgba(184, 195, 209, 0.55); }
        .legend-chip[data-category="gold"] { border-color: rgba(226, 185, 59, 0.55); }
        .legend-chip[data-category="utility"] { border-color: rgba(138, 147, 164, 0.55); }

        .transition-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
            gap: 14px;
        }

        .transition-card {
            background: #ffffff;
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 16px;
            box-shadow: var(--shadow);
        }

        .transition-card h3 {
            margin: 0 0 6px 0;
            font-size: 16px;
        }

        .transition-card .count {
            color: var(--accent);
            font-size: 24px;
            font-weight: 600;
        }

        .transition-card p {
            color: var(--muted);
            margin: 10px 0 0 0;
            font-size: 13px;
            line-height: 1.5;
            overflow-wrap: anywhere;
        }

        .domain-nav {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }

        .jump-link {
            background: #ffffff;
            border-color: var(--line);
            text-decoration: none;
            color: var(--text);
        }

        .jump-link:hover {
            border-color: var(--accent);
            background: var(--panel-2);
            transform: translateY(-1px);
        }

        .domain-list {
            display: grid;
            gap: 24px;
            padding-bottom: 40px;
        }

        .domain-card {
            background: #ffffff;
            border: 1px solid var(--line);
            border-radius: 8px;
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .domain-head {
            padding: 24px 24px 0 24px;
            display: flex;
            justify-content: space-between;
            gap: 18px;
            align-items: flex-start;
        }

        .domain-head h2 {
            margin: 0;
            font-size: 18px;
            color: var(--accent);
        }

        .domain-head p {
            margin: 8px 0 0 0;
            color: var(--muted);
            font-size: 14px;
        }

        .path {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            justify-content: flex-end;
        }

        .path-chip {
            background: #ffffff;
            border-color: var(--line);
            color: var(--text);
        }

        .domain-body {
            display: grid;
            grid-template-columns: 1.7fr 1fr;
            gap: 18px;
            padding: 20px 24px 24px 24px;
        }

        .side-stack {
            display: grid;
            gap: 18px;
            align-content: start;
        }

        .panel {
            background: #ffffff;
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 18px;
        }

        .panel h3 {
            margin: 0 0 14px 0;
            font-size: 16px;
            letter-spacing: 0.01em;
        }

        .panel p,
        .empty-note {
            color: var(--muted);
            font-size: 14px;
            line-height: 1.6;
            margin: 0;
        }

        .diagram-wrap {
            overflow: auto;
            border-radius: 6px;
            border: 1px solid var(--line);
            background: #f9fbfc;
            min-height: 320px;
        }

        .diagram-wrap.compact {
            min-height: 0;
        }

        .generic-diagram {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 14px;
            padding: 14px;
            min-height: 0;
            background: #f9fbfc;
        }

        .generic-node {
            background: #ffffff;
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 14px;
            min-height: 118px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .generic-node .node-title {
            font-size: 14px;
            font-weight: 600;
            color: var(--text);
            line-height: 1.35;
        }

        .generic-node .node-meta {
            margin-top: auto;
            font-size: 12px;
            color: var(--muted);
            line-height: 1.45;
        }

        .diagram-wrap svg {
            display: block;
            width: 100%;
        }

        .pipeline-grid,
        .link-list,
        .gap-list {
            display: grid;
            gap: 10px;
        }

        .section-note {
            color: var(--muted);
            font-size: 12px;
            margin: -4px 0 12px 0;
            line-height: 1.5;
        }

        .pipeline-item,
        .link-item,
        .gap-item {
            background: #ffffff;
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 12px 14px;
        }

        .pipeline-item strong,
        .link-item strong,
        .gap-item strong {
            display: block;
            font-size: 14px;
            margin-bottom: 6px;
            overflow-wrap: anywhere;
        }

        .pipeline-meta,
        .gap-meta,
        .link-meta {
            color: var(--muted);
            font-size: 12px;
            line-height: 1.5;
        }

        .badge {
            display: inline-block;
            padding: 5px 9px;
            margin-right: 8px;
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            font-size: 11px;
        }

        .badge.extract { background: #eef3ff; color: #254eda; }
        .badge.orchestrator { background: #e5f6f2; color: #00655f; }
        .badge.bronze { background: #f7eee7; color: #8c4d16; }
        .badge.silver { background: #edf1f4; color: #4b5968; }
        .badge.gold { background: #fff6da; color: #8a6700; }
        .badge.utility { background: #f1f3f5; color: #4f5965; }

        .gap-item {
            border-color: #f0c6bf;
            background: #fff7f5;
        }

        .footer-note {
            color: var(--muted);
            text-align: center;
            margin: 26px 0 10px 0;
            font-size: 13px;
        }

        @media (max-width: 1120px) {
            .hero-grid,
            .domain-body {
                grid-template-columns: 1fr;
            }

            .path {
                justify-content: flex-start;
            }
        }

        @media (max-width: 720px) {
            .shell {
                padding: 0 12px 18px 12px;
            }

            h1 {
                font-size: 18px;
            }

            .summary-grid {
                grid-template-columns: 1fr 1fr;
            }

            .domain-head,
            .domain-body {
                padding-left: 18px;
                padding-right: 18px;
            }
        }
    </style>
</head>
<body>
    <div class="shell">
        <section class="hero">
            <div class="hero-grid">
                <div>
                    <div class="eyebrow">Fabric Pipeline Explorer</div>
                    <h1>Layer Lineage View</h1>
                    <p class="subtitle">Browse how orchestration and medallion-layer pipelines hand work between Extract, Bronze, Silver, and Gold. Explicit child-pipeline handoffs are drawn directly; domains that rely on lookup-driven notebooks are marked so you know where table-level lineage still needs notebook or metadata inspection.</p>
                    <div class="meta" id="meta"></div>
                </div>
                <div class="summary-grid" id="summary-grid"></div>
            </div>
            <div class="legend" id="legend"></div>
            <div class="transition-grid" id="transition-grid"></div>
            <div class="domain-nav" id="domain-nav"></div>
        </section>

        <main class="domain-list" id="domain-list"></main>
        <p class="footer-note">Generated from exported Fabric pipeline definitions. Notebook-internal and metadata-driven table movement is summarized as a gap, not guessed.</p>
    </div>

    <script>
        const data = __PAGE_DATA_JSON__;
        const categoryOrder = ['extract', 'orchestrator', 'bronze', 'silver', 'gold', 'utility'];
        const categoryColors = {
            extract: '#4d7cfe',
            orchestrator: '#20b486',
            bronze: '#b97a3d',
            silver: '#b8c3d1',
            gold: '#e2b93b',
            utility: '#8a93a4'
        };

        function titleCase(value) {
            return value.charAt(0).toUpperCase() + value.slice(1);
        }

        function escapeHtml(value) {
            return String(value)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;')
                .replaceAll('"', '&quot;');
        }

        function wrapText(value, maxCharsPerLine, maxLines) {
            const words = String(value).split(/\s+/).filter(Boolean);
            const lines = [];
            let current = '';

            words.forEach(word => {
                const next = current ? `${current} ${word}` : word;
                if (next.length <= maxCharsPerLine) {
                    current = next;
                    return;
                }

                if (current) {
                    lines.push(current);
                }

                current = word;
            });

            if (current) {
                lines.push(current);
            }

            if (!lines.length) {
                return [''];
            }

            if (lines.length > maxLines) {
                const trimmed = lines.slice(0, maxLines);
                let lastLine = trimmed[maxLines - 1];
                if (lastLine.length > maxCharsPerLine - 3) {
                    lastLine = `${lastLine.slice(0, maxCharsPerLine - 3)}...`;
                } else {
                    lastLine = `${lastLine}...`;
                }
                trimmed[maxLines - 1] = lastLine;
                return trimmed;
            }

            return lines;
        }

        function renderTspans(lines, x, startY, lineHeight, anchor = 'start') {
            return lines.map((line, index) => {
                const dy = index === 0 ? 0 : lineHeight;
                return `<tspan x="${x}" dy="${dy}" text-anchor="${anchor}">${escapeHtml(line)}</tspan>`;
            }).join('');
        }

        function slugify(value) {
            return value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
        }

        function buildMeta() {
            const meta = document.getElementById('meta');
            meta.innerHTML = `
                <span class="meta-chip">Generated ${escapeHtml(data.generatedAt)}</span>
                <span class="meta-chip">${data.pipelineCount} pipelines parsed</span>
                <span class="meta-chip">${data.linkCount} explicit inter-pipeline links</span>
                <span class="meta-chip">${data.domains.length} domains</span>
            `;
        }

        function buildSummary() {
            const cards = [
                { value: data.pipelineCount, label: 'Pipelines parsed' },
                { value: data.linkCount, label: 'Explicit handoffs found' },
                { value: data.domains.filter(d => d.links.length > 0).length, label: 'Domains with explicit flows' },
                { value: data.domains.reduce((sum, d) => sum + d.gapPipelines.length, 0), label: 'Pipelines needing deeper lineage' }
            ];

            document.getElementById('summary-grid').innerHTML = cards.map(card => `
                <div class="summary-card">
                    <strong>${card.value}</strong>
                    <span>${escapeHtml(card.label)}</span>
                </div>
            `).join('');
        }

        function buildLegend() {
            document.getElementById('legend').innerHTML = data.categories.map(item => `
                <span class="legend-chip" data-category="${escapeHtml(item.category)}">${escapeHtml(titleCase(item.category))}: ${item.count}</span>
            `).join('');
        }

        function buildTransitions() {
            const container = document.getElementById('transition-grid');
            container.innerHTML = data.transitions.map(item => `
                <article class="transition-card">
                    <h3>${escapeHtml(titleCase(item.source))} -> ${escapeHtml(titleCase(item.target))}</h3>
                    <div class="count">${item.count}</div>
                    <p>${escapeHtml(item.samples.join('; '))}</p>
                </article>
            `).join('');
        }

        function buildDomainNav() {
            document.getElementById('domain-nav').innerHTML = data.domains.map(domain => `
                <a class="jump-link" href="#${slugify(domain.name)}">${escapeHtml(domain.name)}</a>
            `).join('');
        }

        function renderPipelineList(pipelines) {
            if (!pipelines.length) {
                return '<p class="empty-note">No pipelines in this section.</p>';
            }

            return pipelines.map(pipeline => `
                <div class="pipeline-item">
                    <span class="badge ${escapeHtml(pipeline.category)}">${escapeHtml(pipeline.category)}</span>
                    <strong>${escapeHtml(pipeline.name)}</strong>
                    <div class="pipeline-meta">Activities: ${pipeline.activityCount} | Source file: ${escapeHtml(pipeline.fileName)}</div>
                </div>
            `).join('');
        }

        function renderLinkList(links) {
            if (!links.length) {
                return '<p class="empty-note">No explicit child-pipeline links were found for this domain in the exported definitions. Movement here is probably inside notebooks or metadata-driven foreach jobs.</p>';
            }

            return `<div class="link-list">${links.map(link => `
                <div class="link-item">
                    <strong>${escapeHtml(link.sourceName)} -> ${escapeHtml(link.targetName)}</strong>
                    <div class="link-meta">${escapeHtml(link.sourceCategory)} -> ${escapeHtml(link.targetCategory)} via ${escapeHtml(link.activityName)}</div>
                </div>
            `).join('')}</div>`;
        }

        function renderGapList(gaps) {
            if (!gaps.length) {
                return '<p class="empty-note">No major notebook-driven lineage gaps detected at the pipeline level for this domain.</p>';
            }

            return `<div class="gap-list">${gaps.map(gap => `
                <div class="gap-item">
                    <span class="badge ${escapeHtml(gap.category)}">${escapeHtml(gap.category)}</span>
                    <strong>${escapeHtml(gap.name)}</strong>
                    <div class="gap-meta">Internal movement likely happens inside these activity types: ${escapeHtml(gap.activityTypes.map(type => type === 'TridentNotebook' ? 'Notebook' : type).join(', '))}</div>
                </div>
            `).join('')}</div>`;
        }

        function createSvgNode(x, y, width, height, label, category, domain) {
            const color = categoryColors[category] || categoryColors.utility;
            const isExternal = Boolean(domain);
            const wrappedLabel = wrapText(label, 24, 3);
            const labelStartY = y + 54;
            const labelTspans = renderTspans(wrappedLabel, x + 16, labelStartY, 16);
            const domainText = isExternal ? `<text x="${x + 16}" y="${y + height - 14}" fill="#5f6b73" font-size="11">${escapeHtml(domain)}</text>` : '';
            return `
                <g>
                    <rect x="${x}" y="${y}" rx="10" ry="10" width="${width}" height="${height}" fill="#ffffff" stroke="${color}" stroke-width="1.5"></rect>
                    <rect x="${x + 14}" y="${y + 14}" rx="6" ry="6" width="84" height="24" fill="${color}" opacity="0.12"></rect>
                    <text x="${x + 24}" y="${y + 31}" fill="${color}" font-size="11" font-weight="600">${escapeHtml(titleCase(category))}</text>
                    <text x="${x + 16}" y="${labelStartY}" fill="#212b32" font-size="13" font-weight="600">${labelTspans}</text>
                    ${domainText}
                </g>
            `;
        }

        function createLaneLabel(x, label, lineWidth = 140) {
            return `
                <g>
                    <text x="${x}" y="26" fill="#5f6b73" font-size="12" font-weight="600">${escapeHtml(titleCase(label))}</text>
                    <line x1="${x}" y1="36" x2="${x + lineWidth}" y2="36" stroke="#d8dde0" stroke-width="1"></line>
                </g>
            `;
        }

        function createEdge(fromNode, toNode, label) {
            const startX = fromNode.x + fromNode.width;
            const startY = fromNode.y + (fromNode.height / 2);
            const endX = toNode.x;
            const endY = toNode.y + (toNode.height / 2);
            const dx = Math.max(60, (endX - startX) * 0.45);
            const path = `M ${startX} ${startY} C ${startX + dx} ${startY}, ${endX - dx} ${endY}, ${endX} ${endY}`;
            const midX = (startX + endX) / 2;
            const wrappedLabel = wrapText(label, 20, 2);
            const maxLineLength = Math.max(...wrappedLabel.map(line => line.length));
            const boxWidth = Math.max(156, Math.min(260, 24 + (maxLineLength * 7)));
            const boxHeight = 16 + (wrappedLabel.length * 15);
            const labelY = Math.min(startY, endY) - 18;
            const labelTspans = renderTspans(wrappedLabel, midX, labelY + 14, 14, 'middle');
            return `
                <g>
                    <path d="${path}" fill="none" stroke="#6aa3d8" stroke-width="2.2" marker-end="url(#arrow)"></path>
                    <rect x="${midX - (boxWidth / 2)}" y="${labelY}" rx="6" ry="6" width="${boxWidth}" height="${boxHeight}" fill="#ffffff" stroke="#7eaed8" stroke-width="1.2"></rect>
                    <text x="${midX}" y="${labelY + 14}" fill="#212b32" font-size="12" font-weight="600">${labelTspans}</text>
                </g>
            `;
        }

        function renderGenericDiagram(domain) {
            const nodes = domain.lineagePipelines.length ? domain.lineagePipelines : domain.supportingPipelines;
            if (!nodes.length) {
                return '<p class="empty-note">No pipelines to render.</p>';
            }

            return `
                <div class="generic-diagram">
                    ${nodes.map(node => `
                        <div class="generic-node">
                            <span class="badge ${escapeHtml(node.category)}">${escapeHtml(titleCase(node.category))}</span>
                            <div class="node-title">${escapeHtml(node.name)}</div>
                            <div class="node-meta">Activities: ${node.activityCount}<br>Source file: ${escapeHtml(node.fileName)}</div>
                        </div>
                    `).join('')}
                </div>
            `;
        }

        function buildDiagram(domain) {
            if (domain.links.length === 0) {
                return renderGenericDiagram(domain);
            }

            const lanes = categoryOrder.filter(category => domain.graphPipelines.some(pipeline => pipeline.category === category));
            if (!lanes.length) {
                return '<p class="empty-note">No graphable pipelines for this domain.</p>';
            }

            const laneCount = lanes.length;
            const maxNodesInLane = Math.max(...lanes.map(lane => domain.graphPipelines.filter(pipeline => pipeline.category === lane).length));
            const compactSingleLane = domain.links.length === 0 && laneCount === 1 && domain.graphPipelines.length >= 2;
            const compactColumns = compactSingleLane ? 2 : 1;
            const nodeWidth = compactSingleLane ? 236 : (laneCount <= 3 ? 232 : (laneCount === 4 ? 220 : 204));
            const laneWidth = compactSingleLane ? ((nodeWidth * compactColumns) + 28) : (nodeWidth + 36);
            const leftPad = 28;
            const topPad = 56;
            const nodeHeight = compactSingleLane ? 92 : (maxNodesInLane <= 2 ? 118 : 110);
            const laneNodeGap = compactSingleLane ? 18 : (maxNodesInLane <= 2 ? 26 : 34);
            const positions = new Map();
            const laneHtml = [];
            const nodeHtml = [];

            lanes.forEach((lane, laneIndex) => {
                const lanePipelines = domain.graphPipelines.filter(pipeline => pipeline.category === lane);
                const laneX = leftPad + (laneIndex * laneWidth);
                laneHtml.push(createLaneLabel(laneX, lane, compactSingleLane ? laneWidth - 24 : 140));
                lanePipelines.forEach((pipeline, pipelineIndex) => {
                    let x = laneX;
                    let y = topPad + (pipelineIndex * (nodeHeight + laneNodeGap));

                    if (compactSingleLane) {
                        const columnIndex = pipelineIndex % compactColumns;
                        const rowIndex = Math.floor(pipelineIndex / compactColumns);
                        x = laneX + (columnIndex * (nodeWidth + 28));
                        y = topPad + (rowIndex * (nodeHeight + laneNodeGap));
                    }

                    const node = { x, y, width: nodeWidth, height: nodeHeight, category: lane };
                    positions.set(pipeline.name, node);
                    nodeHtml.push(createSvgNode(x, y, nodeWidth, nodeHeight, pipeline.name, pipeline.category, pipeline.domain !== domain.name ? pipeline.domain : ''));
                });
            });

            const heightCandidates = Array.from(positions.values()).map(item => item.y + item.height + 24);
            const width = compactSingleLane
                ? Math.max(780, (leftPad * 2) + (compactColumns * (nodeWidth + 28)))
                : ((leftPad * 2) + (lanes.length * laneWidth));
            const height = compactSingleLane
                ? Math.max(240, ...heightCandidates)
                : Math.max(320, ...heightCandidates);

            const edgeHtml = domain.links
                .map(link => {
                    const fromNode = positions.get(link.sourceName);
                    const toNode = positions.get(link.targetName);
                    if (!fromNode || !toNode) {
                        return '';
                    }
                    return createEdge(fromNode, toNode, link.activityName);
                })
                .join('');

            return `
                <div class="diagram-wrap${compactSingleLane ? ' compact' : ''}">
                    <svg viewBox="0 0 ${width} ${height}" role="img" aria-label="${escapeHtml(domain.name)} lineage diagram">
                        <defs>
                            <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
                                <path d="M 0 0 L 10 5 L 0 10 z" fill="#6aa3d8"></path>
                            </marker>
                        </defs>
                        ${laneHtml.join('')}
                        ${edgeHtml}
                        ${nodeHtml.join('')}
                    </svg>
                </div>
            `;
        }

        function buildDomains() {
            const container = document.getElementById('domain-list');
            container.innerHTML = data.domains.map(domain => {
                const inferred = domain.inferredPath.length
                    ? `<div class="path">${domain.inferredPath.map(item => `<span class="path-chip">${escapeHtml(titleCase(item))}</span>`).join('')}</div>`
                    : '<div class="path"><span class="path-chip">No inferred layer path</span></div>';

                return `
                    <section class="domain-card" id="${slugify(domain.name)}">
                        <div class="domain-head">
                            <div>
                                <h2>${escapeHtml(domain.name)}</h2>
                                <p>${domain.links.length ? 'Explicit handoffs are drawn from exported child-pipeline references.' : 'This domain currently needs notebook or metadata inspection for deeper lineage.'}</p>
                            </div>
                            ${inferred}
                        </div>
                        <div class="domain-body">
                            <div class="panel">
                                <h3>Flow Diagram</h3>
                                ${buildDiagram(domain)}
                            </div>
                            <div class="side-stack">
                                <div class="panel">
                                    <h3>Lineage Pipelines</h3>
                                    <p class="section-note">Pipelines that participate directly in the layer path or explicit handoff chain.</p>
                                    <div class="pipeline-grid">${renderPipelineList(domain.lineagePipelines)}</div>
                                </div>
                                <div class="panel">
                                    <h3>Supporting Pipelines</h3>
                                    <p class="section-note">Related utilities and non-path pipelines for this domain.</p>
                                    <div class="pipeline-grid">${renderPipelineList(domain.supportingPipelines)}</div>
                                </div>
                                <div class="panel">
                                    <h3>Explicit Handoffs</h3>
                                    ${renderLinkList(domain.links)}
                                </div>
                                <div class="panel">
                                    <h3>Notebook-Driven Gaps</h3>
                                    ${renderGapList(domain.gapPipelines)}
                                </div>
                            </div>
                        </div>
                    </section>
                `;
            }).join('');
        }

        buildMeta();
        buildSummary();
        buildLegend();
        buildTransitions();
        buildDomainNav();
        buildDomains();
    </script>
</body>
</html>
'@

$html = $html.Replace('__PAGE_DATA_JSON__', $pageDataJson)

$outputDir = Split-Path -Parent $OutputFile
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Set-Content -Path $OutputFile -Value $html -Encoding UTF8

Write-Host "Wrote lineage HTML to $OutputFile" -ForegroundColor Green