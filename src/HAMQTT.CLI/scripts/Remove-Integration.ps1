<#
.SYNOPSIS
    Automates the removal of a HAMQTT Integration project.
.DESCRIPTION
    Removes reference and deletes directory.
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$IntegrationName,

    [Parameter(Mandatory = $false)]
    [string]$ProjectFolderName,

    [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/Common-Utils.ps1"

$RootComposePath = Join-Path $ProjectRoot "docker-compose.dev.yml"

if ([string]::IsNullOrWhiteSpace($IntegrationName) -and [string]::IsNullOrWhiteSpace($ProjectFolderName))
{
    if (-not (Test-Path $ProjectRoot))
    {
        Write-Error "Source directory not found."
        exit 1
    }

    $Integrations = Get-Integrations

    if ($Integrations.Count -eq 0)
    {
        Write-Warning "No integrations found to remove."
        exit 0
    }

    Write-Host "🗑️  Select an integration to remove:" -ForegroundColor Cyan

    $Map = @{ }
    $Index = 1

    foreach ($dir in $Integrations)
    {
        Write-Host "   [$Index] $dir.Name"
        $Map[$Index] = $dir.Name
        $Index++
    }

    $Selection = Read-Host "`n   > Enter number or name"

    if ($Selection -match "^\d+$" -and $Map.ContainsKey([int]$Selection))
    {
        $IntegrationName = $Map[[int]$Selection]
    }
    elseif ($Integrations | Where-Object { ($_.Name) -eq $Selection })
    {
        $IntegrationName = $Selection
    }
    else
    {
        Write-Error "Invalid selection."
        exit 1
    }

    Write-Host "   Selected: $IntegrationName" -ForegroundColor Gray
}

if ([string]::IsNullOrWhiteSpace($ProjectFolderName))
{
    $ProjectFolderName = ${IntegrationName}
}
elseif ([string]::IsNullOrWhiteSpace($IntegrationName))
{
    $IntegrationName = $ProjectFolderName
}

$ProjectRelPath = Join-Path $ProjectRoot $ProjectFolderName

Write-Host "🗑️  Starting removal for '${IntegrationName}'..." -ForegroundColor Cyan

if (Test-Path $RootComposePath)
{
    Write-Host "   🔗 Checking root compose file..." -ForegroundColor Yellow

    $Content = Get-Content $RootComposePath -Raw
    $IncludeString = "${ProjectFolderName}/docker-compose.dev.yml"

    $Lines = $Content -split "`r?`n"
    $NewLines = $Lines | Where-Object { -not ($_ -match [regex]::Escape($IncludeString)) }

    if ($Lines.Count -ne $NewLines.Count)
    {
        $NewLines -join "`n" | Set-Content -Path $RootComposePath
        Write-Host "   ✅ Removed include reference from ${RootComposePath}" -ForegroundColor Green
    }
    else
    {
        Write-Host "   ℹ️  No reference found in ${RootComposePath} (skipping)" -ForegroundColor Gray
    }
}
else
{
    Write-Warning "   ⚠️  Root compose file not found at ${RootComposePath}"
}

$SolutionFile = Get-ChildItem -Path $ProjectRoot -Filter "*.sln" | Select-Object -First 1
$CsprojPath = Join-Path $ProjectRelPath "${ProjectFolderName}.csproj"

if ($SolutionFile -and (Test-Path $CsprojPath))
{
    Write-Host "   🔗 Removing from solution..." -ForegroundColor Yellow
    
    dotnet sln $SolutionFile.FullName remove $CsprojPath | Out-Null
    
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "   ✅ Removed project from solution." -ForegroundColor Green
    }
    else
    {
        Write-Warning "   ⚠️  Failed to remove project from solution (Exit Code: $LASTEXITCODE)"
    }
}

$KebabName = Get-KebabCase $IntegrationName
$WorkflowPath = Join-Path $ProjectRoot ".." ".github" "workflows" "${KebabName}.yml"
$WorkflowPath = [System.IO.Path]::GetFullPath($WorkflowPath)

if (Test-Path $WorkflowPath)
{
    Write-Host "   🤖 Removing workflow file..." -ForegroundColor Yellow
    try
    {
        Remove-Item -Path $WorkflowPath -Force -ErrorAction Stop
        Write-Host "   ✅ Deleted workflow: ${WorkflowPath}" -ForegroundColor Green
    }
    catch
    {
        Write-Error "   ❌ Failed to delete workflow: $_"
    }
}

if (Test-Path $ProjectRelPath)
{
    Write-Host "   📂 Removing project directory..." -ForegroundColor Yellow
    try
    {
        Remove-Item -Path $ProjectRelPath -Recurse -Force -ErrorAction Stop
        Write-Host "   ✅ Deleted directory: ${ProjectRelPath}" -ForegroundColor Green
    }
    catch
    {
        Write-Error "   ❌ Failed to delete directory: $_"
    }
}
else
{
    Write-Host "   ℹ️  Directory not found: ${ProjectRelPath} (skipping)" -ForegroundColor Gray
}

Write-Host "`n✨ Removal Complete!" -ForegroundColor Cyan
Write-Host "   ⚠️  To apply changes and remove the running container, run:" -ForegroundColor Gray
Write-Host "      docker-compose -f docker-compose.dev.yml up -d --remove-orphans" -ForegroundColor White
