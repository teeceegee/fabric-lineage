<#
.SYNOPSIS
    Exports Fabric pipeline definitions to local JSON files
.DESCRIPTION
    This script authenticates to Microsoft Fabric API and exports all pipeline definitions
    from the specified workspace to local JSON files in the pipelines/ directory.
.PARAMETER WorkspaceId
    The Fabric workspace ID (defaults to dev-prescriptions-process workspace)
.PARAMETER OutputPath
    The directory to save pipeline JSON files (defaults to ./pipelines/)
.EXAMPLE
    .\Export-FabricPipelines.ps1
.EXAMPLE
    .\Export-FabricPipelines.ps1 -WorkspaceId "e8c421cf-979f-450a-94b4-e2010e807479" -OutputPath "./pipelines/"
#>

[CmdletBinding()]
param(
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
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

#region Authentication
Write-Host "`n=== Authenticating to Microsoft Fabric ===" -ForegroundColor Cyan

# Prompt user for access token
Write-Host @"

To authenticate, please get a Fabric API access token:
1. Open browser to: https://learn.microsoft.com/en-us/rest/api/fabric/articles/get-started/fabric-api-quickstart
2. Or run in PowerShell: 
   (Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com").Token
3. Or use Azure CLI:
   az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv

"@ -ForegroundColor Yellow

$token = Read-Host "Please paste your Fabric API access token"

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error "No token provided. Exiting."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

# Test the token with a simple API call
try {
    Write-Host "Testing token validity..." -ForegroundColor Yellow
    $testUri = "$FabricApiBase/workspaces/$WorkspaceId"
    $testResponse = Invoke-RestMethod -Uri $testUri -Method Get -Headers $headers -ErrorAction Stop
    Write-Host "[OK] Token valid - Connected to workspace: $($testResponse.displayName)" -ForegroundColor Green
}
catch {
    Write-Error "Token validation failed: $_"
    exit 1
}
#endregion

#region Load Pipeline Inventory
Write-Host "`n=== Loading Pipeline Inventory ===" -ForegroundColor Cyan

if (-not (Test-Path $InventoryFile)) {
    Write-Error "Pipeline inventory file not found: $InventoryFile"
    exit 1
}

try {
    $inventory = Get-Content $InventoryFile -Raw | ConvertFrom-Json
    $pipelines = $inventory.pipelines
    Write-Host "[OK] Loaded $($pipelines.Count) pipelines from inventory" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load pipeline inventory: $_"
    exit 1
}
#endregion

#region Export Pipeline Definitions
Write-Host "`n=== Exporting Pipeline Definitions ===" -ForegroundColor Cyan

$successCount = 0
$failCount = 0
$results = @()

foreach ($pipeline in $pipelines) {
    $pipelineName = $pipeline.name
    $pipelineId = $pipeline.id
    $safeFileName = $pipelineName -replace "[\\/:*?`"<>|]", "_"
    $outputFile = Join-Path $OutputPath "$safeFileName.json"
    
    Write-Host "`nProcessing: $pipelineName" -ForegroundColor Yellow
    Write-Host "  ID: $pipelineId"
    
    try {
        # Call Fabric API to get pipeline definition
        $uri = "$FabricApiBase/workspaces/$WorkspaceId/items/$pipelineId/getDefinition"
        Write-Host "  Calling API: $uri"
        
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ErrorAction Stop
        
        # Check if definition exists
        if ($response.definition) {
            # Create output object with metadata and definition
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
            
            # Save to file
            $output | ConvertTo-Json -Depth 100 | Set-Content -Path $outputFile -Encoding UTF8
            Write-Host "  [OK] Saved to: $outputFile" -ForegroundColor Green
            $successCount++
            
            $results += @{
                pipeline = $pipelineName
                status = "Success"
                file = $outputFile
            }
        }
        else {
            Write-Warning "  [WARN] No definition returned for $pipelineName"
            $failCount++
            
            $results += @{
                pipeline = $pipelineName
                status = "NoDefinition"
                file = $null
            }
        }
        
        # Rate limiting - be nice to the API
        Start-Sleep -Milliseconds 500
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "  [FAIL] Failed to export $pipelineName : $errorMessage"
        $failCount++
        
        $results += @{
            pipeline = $pipelineName
            status = "Error"
            error = $errorMessage
            file = $null
        }
        
        # Continue with next pipeline
        continue
    }
}
#endregion

#region Summary
Write-Host "`n=== Export Summary ===" -ForegroundColor Cyan
Write-Host "Total pipelines: $($pipelines.Count)" -ForegroundColor White
Write-Host "Successfully exported: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })

# Save results to a summary file
$summaryFile = Join-Path $OutputPath "export_summary.json"
$summary = @{
    exportedAt = (Get-Date).ToString("o")
    workspaceId = $WorkspaceId
    totalPipelines = $pipelines.Count
    successCount = $successCount
    failCount = $failCount
    results = $results
}
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryFile -Encoding UTF8
Write-Host "`nExport summary saved to: $summaryFile" -ForegroundColor Cyan

Write-Host "`n[OK] Export complete!" -ForegroundColor Green
#endregion
