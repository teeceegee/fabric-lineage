<#
.SYNOPSIS
    Creates enhanced pipeline documentation with activity details
#>

param(
    [string]$PipelineDir = ".\pipelines\",
    [string]$OutputFile = ".\pipeline-documentation.md"
)

Write-Host "=== Creating Pipeline Documentation ===" -ForegroundColor Cyan

$pipelineFiles = Get-ChildItem -Path $PipelineDir -Filter "*.json" | 
    Where-Object { $_.Name -notin @("export_summary.json", "pipeline_inventory.json") }

$doc = @"
# Fabric Pipeline Documentation
**Workspace**: dev-prescriptions-process
**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Pipelines**: $($pipelineFiles.Count)

---

"@

$orchestrators = @()
$bronzeLayer = @()
$silverLayer = @()
$goldLayer = @()
$extractPipelines = @()
$utilities = @()

foreach ($file in $pipelineFiles) {
    try {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        
        # Decode base64 content
        $contentPart = $json.definition.parts | Where-Object { $_.path -eq "pipeline-content.json" }
        $schedulePart = $json.definition.parts | Where-Object { $_.path -eq ".schedules" }
        
        if (-not $contentPart) {
            Write-Warning "No content found for $($json.metadata.name)"
            continue
        }
        
        $contentBytes = [System.Convert]::FromBase64String($contentPart.payload)
        $contentJson = [System.Text.Encoding]::UTF8.GetString($contentBytes) | ConvertFrom-Json
        $activities = $contentJson.properties.activities
        
        $schedule = $null
        if ($schedulePart) {
            $scheduleBytes = [System.Convert]::FromBase64String($schedulePart.payload)
            $scheduleJson = [System.Text.Encoding]::UTF8.GetString($scheduleBytes) | ConvertFrom-Json
            if ($scheduleJson.schedules -and $scheduleJson.schedules.Count -gt 0) {
                $schedule = $scheduleJson.schedules[0]
            }
        }
        
        # Build pipeline documentation
        $pipelineDoc = @"

## $($json.metadata.name)

"@
        
        # Schedule info
        if ($schedule) {
            $scheduleInfo = "$($schedule.configuration.type)"
            if ($schedule.configuration.times) {
                $scheduleInfo += " at $($schedule.configuration.times -join ', ')"
            }
            if ($schedule.configuration.weekdays) {
                $scheduleInfo += " on $($schedule.configuration.weekdays -join ', ')"
            }
            $pipelineDoc += "**Schedule**: $scheduleInfo ($(if ($schedule.enabled) {'Enabled'} else {'Disabled'}))`n`n"
        } else {
            $pipelineDoc += "**Schedule**: None (manual trigger only)`n`n"
        }
        
        $pipelineDoc += "**Total Activities**: $($activities.Count)`n`n"
        
        # Activity details
        $pipelineDoc += "### Activities`n`n"
        
        $activityNum = 1
        foreach ($activity in $activities) {
            $pipelineDoc += "#### $activityNum. $($activity.name)`n"
            $pipelineDoc += "- **Type**: $($activity.type)`n"
            
            # Dependencies
            if ($activity.dependsOn -and $activity.dependsOn.Count -gt 0) {
                $deps = $activity.dependsOn | ForEach-Object { "$($_.activity) ($($_.dependencyConditions -join ', '))" }
                $pipelineDoc += "- **Depends On**: $($deps -join '; ')`n"
            }
            
            # Type-specific details
            switch ($activity.type) {
                "ExecutePipeline" {
                    $refName = $activity.typeProperties.pipeline.referenceName
                    $waitOnCompletion = $activity.typeProperties.waitOnCompletion
                    $pipelineDoc += "- **Target Pipeline ID**: ``$refName```n"
                    $pipelineDoc += "- **Wait for Completion**: $waitOnCompletion`n"
                }
                "Notebook" {
                    if ($activity.typeProperties.notebook) {
                        $nbName = $activity.typeProperties.notebook.referenceName
                        $pipelineDoc += "- **Notebook**: $nbName`n"
                    }
                    if ($activity.typeProperties.parameters) {
                        $pipelineDoc += "- **Parameters**: `n"
                        $activity.typeProperties.parameters.PSObject.Properties | ForEach-Object {
                            $pipelineDoc += "  - ``$($_.Name)``: $($_.Value.value)`n"
                        }
                    }
                }
                "Copy" {
                    if ($activity.typeProperties.source) {
                        $pipelineDoc += "- **Source**: $($activity.typeProperties.source.type)`n"
                    }
                    if ($activity.typeProperties.sink) {
                        $pipelineDoc += "- **Sink**: $($activity.typeProperties.sink.type)`n"
                    }
                    if ($activity.typeProperties.dataSource) {
                        $pipelineDoc += "- **Data Source**: $($activity.typeProperties.dataSource.type)`n"
                    }
                }
                "Script" {
                    if ($activity.typeProperties.scriptType) {
                        $pipelineDoc += "- **Script Type**: $($activity.typeProperties.scriptType)`n"
                    }
                    if ($activity.typeProperties.logSettings) {
                        $pipelineDoc += "- **Logging**: Enabled`n"
                    }
                }
                "Wait" {
                    if ($activity.typeProperties.waitTimeInSeconds) {
                        $pipelineDoc += "- **Wait Time**: $($activity.typeProperties.waitTimeInSeconds) seconds`n"
                    }
                }
            }
            
            $pipelineDoc += "`n"
            $activityNum++
        }
        
        $pipelineDoc += "---`n"
        
        # Categorize
        $name = $json.metadata.name
        if ($name -match "bronze") { $bronzeLayer += $pipelineDoc }
        elseif ($name -match "silver") { $silverLayer += $pipelineDoc }
        elseif ($name -match "gold") { $goldLayer += $pipelineDoc }
        elseif ($name -match "master|_all$") { $orchestrators += $pipelineDoc }
        elseif ($name -match "BAU|extract|gateway") { $extractPipelines += $pipelineDoc }
        else { $utilities += $pipelineDoc }
        
    } catch {
        Write-Warning "Failed to process $($file.Name): $_"
    }
}

# Build final document
$doc += @"

# Orchestrator Pipelines
Master pipelines that coordinate multiple sub-pipelines

$($orchestrators -join "`n")

# Bronze Layer Pipelines
Raw data ingestion and initial processing

$($bronzeLayer -join "`n")

# Silver Layer Pipelines
Cleansed and conformed data

$($silverLayer -join "`n")

# Gold Layer Pipelines
Business-level aggregates and analytics

$($goldLayer -join "`n")

# Extract Pipelines
BAU extracts and data gateway operations

$($extractPipelines -join "`n")

# Utility Pipelines
Maintenance and support operations

$($utilities -join "`n")
"@

$doc | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "[OK] Documentation created: $OutputFile" -ForegroundColor Green
Write-Host "Categories:" -ForegroundColor Cyan
Write-Host "  Orchestrators: $($orchestrators.Count)" -ForegroundColor White
Write-Host "  Bronze: $($bronzeLayer.Count)" -ForegroundColor White
Write-Host "  Silver: $($silverLayer.Count)" -ForegroundColor White
Write-Host "  Gold: $($goldLayer.Count)" -ForegroundColor White
Write-Host "  Extracts: $($extractPipelines.Count)" -ForegroundColor White
Write-Host "  Utilities: $($utilities.Count)" -ForegroundColor White
