<#
.SYNOPSIS
    Generates a markdown lineage map showing how data moves between pipeline layers.
#>

param(
    [string]$PipelineDir = ".\pipelines\",
    [string]$OutputFile = ".\pipeline-lineage.md"
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

Write-Host "=== Generating Layer Lineage ===" -ForegroundColor Cyan

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

$layerLinks = $links |
    Where-Object { $_.SourceCategory -ne $_.TargetCategory } |
    Sort-Object SourceDomain, SourceName, Order, TargetName

$categoryCounts = $pipelines |
    Group-Object Category |
    Sort-Object Name

$domains = $pipelines |
    Group-Object Domain |
    Sort-Object Name

$dateStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("# Pipeline Layer Lineage")
$lines.Add("")
$lines.Add("Generated: $dateStamp")
$lines.Add("")
$lines.Add("This report shows pipeline-level lineage across the medallion layers using exported Fabric pipeline definitions. It is reliable for pipeline-to-pipeline movement, but notebook-internal and table-level lineage remains partially hidden where pipelines dispatch metadata-driven notebook jobs.")
$lines.Add("")
$lines.Add("## Coverage")
$lines.Add("")
$lines.Add("- Pipelines parsed: $($pipelines.Count)")
$lines.Add("- Inter-pipeline links found: $($links.Count)")
$lines.Add("- Cross-layer links found: $($layerLinks.Count)")
$lines.Add("")
$lines.Add("### Pipelines by category")
$lines.Add("")
foreach ($count in $categoryCounts) {
    $lines.Add("- $($count.Name): $($count.Count)")
}

$lines.Add("")
$lines.Add("## Layer transition matrix")
$lines.Add("")

$transitionCounts = $layerLinks |
    Group-Object SourceCategory, TargetCategory |
    Sort-Object Name

foreach ($transition in $transitionCounts) {
    $sample = $transition.Group | Select-Object -First 3
    $samplesText = ($sample | ForEach-Object { "$($_.SourceName) -> $($_.TargetName)" }) -join "; "
    $parts = $transition.Name -split ", "
    $lines.Add("- $($parts[0]) -> $($parts[1]): $($transition.Count) link(s) | $samplesText")
}

$lines.Add("")
$lines.Add("## Domain flows")
$lines.Add("")

foreach ($domainGroup in $domains) {
    $domainPipelines = $domainGroup.Group | Sort-Object Category, Name
    $domainLinks = $links |
        Where-Object { $_.SourceDomain -eq $domainGroup.Name -or $_.TargetDomain -eq $domainGroup.Name } |
        Sort-Object Order, SourceName, TargetName
    $domainGraphNames = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($pipeline in $domainPipelines) {
        [void]$domainGraphNames.Add($pipeline.Name)
    }

    foreach ($link in $domainLinks) {
        [void]$domainGraphNames.Add($link.SourceName)
        [void]$domainGraphNames.Add($link.TargetName)
    }

    $domainGraphPipelines = $pipelines |
        Where-Object { $domainGraphNames.Contains($_.Name) } |
        Sort-Object { Get-LayerRank -Category $_.Category }, Name
    $inferredFlow = $domainPipelines |
        Where-Object { $_.Category -in @("extract", "orchestrator", "bronze", "silver", "gold") } |
        Sort-Object { Get-LayerRank -Category $_.Category }, Name
    $inferredCategories = @($inferredFlow | ForEach-Object { $_.Category } | Select-Object -Unique)

    $lines.Add("### $($domainGroup.Name)")
    $lines.Add("")
    $lines.Add("Pipelines:")
    foreach ($pipeline in $domainPipelines) {
        $lines.Add("- $($pipeline.Name) [$($pipeline.Category)]")
    }

    if ($inferredCategories.Count -gt 1) {
        $lines.Add("")
        $lines.Add("Inferred layer path:")
        $lines.Add("- $($inferredCategories -join ' -> ')")
    }

    if ($domainLinks.Count -gt 0) {
        $lines.Add("")
        $lines.Add("Mermaid view:")
        $lines.Add("")
        $lines.Add('```mermaid')
        $lines.Add('flowchart LR')

        foreach ($pipeline in $domainGraphPipelines) {
            $nodeId = ($pipeline.Name -replace '[^A-Za-z0-9]', '_')
            $label = "$($pipeline.Name) [$($pipeline.Category)]"
            $lines.Add("    $nodeId[$label]")
        }

        foreach ($link in $domainLinks) {
            $sourceId = ($link.SourceName -replace '[^A-Za-z0-9]', '_')
            $targetId = ($link.TargetName -replace '[^A-Za-z0-9]', '_')
            $edgeLabel = $link.ActivityName -replace '"', '\"'
            $lines.Add("    $sourceId -->|$edgeLabel| $targetId")
        }

        $lines.Add('```')
        $lines.Add("")
        $lines.Add("Pipeline transitions:")
        foreach ($link in $domainLinks) {
            $lines.Add("- $($link.SourceName) [$($link.SourceCategory)] -> $($link.TargetName) [$($link.TargetCategory)] via $($link.ActivityName)")
        }
    }
    else {
        $lines.Add("")
        $lines.Add("No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.")
    }

    $lines.Add("")
}

$lines.Add("## Gaps")
$lines.Add("")
$metadataDriven = $pipelines |
    Where-Object {
        $_.Category -in @("bronze", "silver", "gold") -and
        $_.References.Count -eq 0 -and
        ($_.Activities | Where-Object { $_.type -in @("Lookup", "ForEach", "TridentNotebook") }).Count -gt 0
    } |
    Sort-Object Domain, Name

if ($metadataDriven.Count -gt 0) {
    $lines.Add("The following layer pipelines appear to move data internally through lookup-driven notebook execution rather than explicit child-pipeline calls:")
    $lines.Add("")
    foreach ($pipeline in $metadataDriven) {
        $activityTypes = ($pipeline.Activities | ForEach-Object { $_.type } | Select-Object -Unique) -join ", "
        $lines.Add("- $($pipeline.Name) [$($pipeline.Category)] - activity types: $activityTypes")
    }
}
else {
    $lines.Add("No significant lineage gaps detected at the pipeline level.")
}

$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("Use this report to answer which pipeline hands off to which next layer. Use notebook code or the metadata files read by the Lookup activities when you need exact source-table to target-table lineage.")

$outputDir = Split-Path -Parent $OutputFile
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Set-Content -Path $OutputFile -Value $lines -Encoding UTF8

Write-Host "Wrote lineage report to $OutputFile" -ForegroundColor Green