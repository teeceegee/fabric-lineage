<#
.SYNOPSIS
    Exports Fabric pipeline definitions using a provided access token
.DESCRIPTION
    Simple script that exports all pipeline definitions from a Fabric workspace.
    Requires you to provide a valid Fabric API access token.
.PARAMETER Token
    Fabric API access token
.PARAMETER WorkspaceId
    The Fabric workspace ID
.EXAMPLE
    .\Export-FabricPipelines-Simple.ps1 -Token "your-token-here"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Token,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkspaceId = "e8c421cf-979f-450a-94b4-e2010e807479",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\pipelines\",
    
    [Parameter(Mandatory = $false)]
    [string]$InventoryFile = ".\pipelines\pipeline_inventory.json"
)

# Fabric API endpoint
$FabricApiBase = "https://api.fabric.microsoft.com/v1"

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "`n=== Fabric Pipeline Exporter ===" -ForegroundColor Cyan
Write-Host "Workspace: $WorkspaceId`n" -ForegroundColor White

# Get token if not provided
if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host "You need a Fabric API access token. Get one by:" -ForegroundColor Yellow
    Write-Host "  1. Open https://portal.azure.com" -ForegroundColor White
    Write-Host "  2. Click Cloud Shell icon (top right)" -ForegroundColor White
    Write-Host "  3. Ensure PowerShell mode is selected" -ForegroundColor White
    Write-Host "  4. Run: (Get-AzAccessToken -ResourceUrl 'https://api.fabric.microsoft.com').Token" -ForegroundColor White
    Write-Host "  5. Copy the token and paste below`n" -ForegroundColor White
    
    $Token = Read-Host "Paste your Fabric API access token"
    
    if ([string]::IsNullOrWhiteSpace($Token)) {
        Write-Error "No token provided. Exiting."
        exit 1
    }
}

# Setup headers
$headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json"
}

# Test token
Write-Host "Testing token..." -ForegroundColor Yellow
try {
    $testUri = "$FabricApiBase/workspaces/$WorkspaceId"
    $workspace = Invoke-RestMethod -Uri $testUri -Method Get -Headers $headers -ErrorAction Stop
    Write-Host "[OK] Connected to workspace: $($workspace.displayName)" -ForegroundColor Green
}
catch {
    Write-Error "Token validation failed: $($_.Exception.Message)"
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    exit 1
}

# Load pipeline inventory
Write-Host "`nLoading pipeline inventory..." -ForegroundColor Yellow
if (-not (Test-Path $InventoryFile)) {
    Write-Error "Pipeline inventory file not found: $InventoryFile"
    exit 1
}

$inventory = Get-Content $InventoryFile -Raw | ConvertFrom-Json
$pipelines = $inventory.pipelines
Write-Host "[OK] Loaded $($pipelines.Count) pipelines`n" -ForegroundColor Green

# Export pipelines
Write-Host "=== Exporting Pipeline Definitions ===" -ForegroundColor Cyan
$successCount = 0
$failCount = 0
$results = @()

foreach ($pipeline in $pipelines) {
    $pipelineName = $pipeline.name
    $pipelineId = $pipeline.id
    $safeFileName = $pipelineName -replace "[\\/:*?`"<>|]", "_"
    $outputFile = Join-Path $OutputPath "$safeFileName.json"
    
    Write-Host "[$($successCount + $failCount + 1)/$($pipelines.Count)] $pipelineName" -ForegroundColor Yellow
    
    try {
        # Call Fabric API
        $uri = "$FabricApiBase/workspaces/$WorkspaceId/items/$pipelineId/getDefinition"
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ErrorAction Stop
        
        if ($response.definition) {
            $output = @{
                metadata = @{
                    id = $pipelineId
                    name = $pipelineName
                    type = $pipeline.type
                    workspaceId = $WorkspaceId
                    exportedAt = (Get-Date).ToString("o")
                }
                definition = $response.definition
            }
            
            $output | ConvertTo-Json -Depth 100 | Set-Content -Path $outputFile -Encoding UTF8
            Write-Host "  [OK] $outputFile" -ForegroundColor Green
            $successCount++
            
            $results += @{
                pipeline = $pipelineName
                status = "Success"
                file = $outputFile
            }
        }
        else {
            Write-Warning "  [WARN] No definition returned"
            $failCount++
            $results += @{
                pipeline = $pipelineName
                status = "NoDefinition"
            }
        }
        
        Start-Sleep -Milliseconds 300
    }
    catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
        $results += @{
            pipeline = $pipelineName
            status = "Error"
            error = $_.Exception.Message
        }
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total: $($pipelines.Count) | Success: $successCount | Failed: $failCount" -ForegroundColor White

$summary = @{
    exportedAt = (Get-Date).ToString("o")
    workspaceId = $WorkspaceId
    workspaceName = $workspace.displayName
    totalPipelines = $pipelines.Count
    successCount = $successCount
    failCount = $failCount
    results = $results
}
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $OutputPath "export_summary.json") -Encoding UTF8

Write-Host "`n[OK] Export complete! Check the pipelines/ directory" -ForegroundColor Green
