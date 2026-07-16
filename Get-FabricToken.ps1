<#
.SYNOPSIS
    Helper script to get Fabric API access token
.DESCRIPTION
    Attempts to get a Fabric API access token using available methods
#>

Write-Host "=== Getting Fabric API Token ===" -ForegroundColor Cyan

# Method 1: Try Az.Accounts if available
try {
    Import-Module Az.Accounts -ErrorAction Stop
    Write-Host "Attempting Azure authentication..." -ForegroundColor Yellow
    $context = Connect-AzAccount -ErrorAction Stop
    $tokenObj = Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com" -ErrorAction Stop
    Write-Host "`nYour Fabric API Token:" -ForegroundColor Green
    Write-Host $tokenObj.Token -ForegroundColor White
    Write-Host "`nToken copied to clipboard!" -ForegroundColor Green
    $tokenObj.Token | Set-Clipboard
    exit 0
}
catch {
    Write-Host "Az.Accounts not available or authentication failed." -ForegroundColor Yellow
}

# Method 2: Try Azure CLI
try {
    $cliToken = az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv 2>$null
    if ($cliToken) {
        Write-Host "`nYour Fabric API Token:" -ForegroundColor Green
        Write-Host $cliToken -ForegroundColor White
        Write-Host "`nToken copied to clipboard!" -ForegroundColor Green
        $cliToken | Set-Clipboard
        exit 0
    }
}
catch {
    Write-Host "Azure CLI not available or not logged in." -ForegroundColor Yellow
}

# No methods worked
Write-Host @"

No automated method available. Please get a token manually:

OPTION 1: Install Az.Accounts module and run this script again
  Install-Module -Name Az.Accounts -Scope CurrentUser -Force
  .\Get-FabricToken.ps1

OPTION 2: Use Azure CLI
  az login
  az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv

OPTION 3: Get token from Azure Portal
  1. Go to https://portal.azure.com
  2. Open Cloud Shell (PowerShell)
  3. Run: (Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com").Token

"@ -ForegroundColor Yellow
