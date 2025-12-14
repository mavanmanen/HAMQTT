<#
.SYNOPSIS
    Lists all HAMQTT Integration projects and their deployment status.
.DESCRIPTION
    Scans and compares dev/prod compose files.
#>

param(
    [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/Common-Utils.ps1"

$DevComposePath = Join-Path $ProjectRoot "docker-compose.dev.yml"
$ProdComposePath = Join-Path $ProjectRoot "docker-compose.yml"

if (-not (Test-Path $ProjectRoot))
{
    Write-Warning "Source directory not found at $ProjectRoot"
    return
}

$Integrations = Get-Integrations

if ($Integrations.Count -eq 0)
{
    Write-Host "No integrations found on disk." -ForegroundColor Gray
    return
}

$DevIncludes = @()
if (Test-Path $DevComposePath)
{
    $DevContent = Get-Content $DevComposePath -Raw
    if ($DevContent -match "(?ms)^include:\s*(.*?)(^services:|\Z)")
    {
        $DevIncludes = $matches[1] -split "`r?`n" | Where-Object { $_.Trim().StartsWith("-") }
    }
}

$ProdServices = @()
if (Test-Path $ProdComposePath)
{
    $ProdContent = Get-Content $ProdComposePath
    $ProdServices = $ProdContent | Select-String -Pattern "^\s+hamqtt-integration-([a-zA-Z0-9-]+):" | ForEach-Object { $_.Matches.Groups[1].Value }
}

$StatusList = @()

foreach ($dir in $Integrations)
{
    $KebabName = Get-KebabCase $dir.Name

    $ExpectedIncludePart = "${dir.Name}/docker-compose.dev.yml"
    $IsDev = $false

    foreach ($inc in $DevIncludes)
    {
        if ($inc -match [regex]::Escape($ExpectedIncludePart))
        {
            $IsDev = $true;
            break
        }
    }

    $IsProd = $ProdServices -contains $KebabName

    $Status = "Active"
    if (-not $IsDev)
    {
        $Status = "ORPHANED"
    }

    $DisplayDev = if ($IsDev)
    {
        "Yes"
    }
    else
    {
        "NO"
    }

    if (-not (Test-Path (Join-Path $dir.FullName "docker-compose.dev.yml")))
    {
        if (-not $IsDev)
        {
            $DisplayDev = "No"
        }
    }

    $StatusList += [PSCustomObject]@{
        "Integration Name" = $dir.Name
        "Dev Configured" = $DisplayDev
        "Prod Deployed" = if ($IsProd)
        {
            "Yes"
        }
        else
        {
            "No"
        }
        "Status" = $Status
    }
}

Write-Host "`n📊 Integration Status Report" -ForegroundColor Cyan
$StatusList | Format-Table -AutoSize

if ($StatusList | Where-Object { $_.Status -eq "ORPHANED" })
{
    Write-Host "⚠️  Orphaned integrations detected!" -ForegroundColor Yellow
    Write-Host "   Run 'hamqtt integrations update' to register them automatically." -ForegroundColor Gray
}
