<#
.SYNOPSIS
    Automates the creation of a HAMQTT Integration project.
.DESCRIPTION
    Creates new project and links to Docker Compose.
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$IntegrationName,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateTemplate,

    [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/Common-Utils.ps1"

if ( [string]::IsNullOrWhiteSpace($IntegrationName))
{
    Write-Host "📝 New Integration Setup" -ForegroundColor Cyan
    Write-Host "   Please enter the name for the new integration." -ForegroundColor Yellow
    Write-Host "   👉 Tip: Use PascalCase (e.g., 'SolarEdge', 'HomeAssistant')." -ForegroundColor Gray

    $IntegrationName = Read-Host "   > Name"

    if ( [string]::IsNullOrWhiteSpace($IntegrationName))
    {
        Write-Error "Integration name is required."
        exit 1
    }
}

$RootComposePath = Join-Path $ProjectRoot "docker-compose.dev.yml"

$ProjectRelPath = Join-Path $ProjectRoot ${IntegrationName}

Write-Host "🚀 Starting setup for '${IntegrationName}'..." -ForegroundColor Cyan

Write-Host "`n🔨 Generating Project..." -ForegroundColor Yellow
$RootLocation = Get-Location

try
{
    if (-not (Test-Path $ProjectRoot))
    {
        New-Item -ItemType Directory -Path $ProjectRoot | Out-Null
    }
    Set-Location $ProjectRoot

    dotnet new hamqtt-integration `
        --integration-name $IntegrationName `
        --force

    if ($LASTEXITCODE -ne 0)
    {
        throw "dotnet new failed. Ensure template is installed using 'hamqtt template install'"
    }
}
catch
{
    Write-Error "Failed to generate project: ${_}"
    Set-Location $RootLocation
    exit 1
}
finally
{
    Set-Location $RootLocation
}
Write-Host "   ✅ Project generated at: ${ProjectRelPath}" -ForegroundColor Green

Write-Host "`n🐳 Creating Project Docker Compose..." -ForegroundColor Yellow

$ComposePath = Join-Path $ProjectRelPath "docker-compose.dev.yml"

New-IntegrationComposeFile -IntegrationName $IntegrationName -OutputPath $ComposePath

Write-Host "   ✅ Created: ${ComposePath}" -ForegroundColor Green

Write-Host "`n🔗 Registering Integration in Root Docker Compose..." -ForegroundColor Yellow
& "$PSScriptRoot/Update-Integrations.ps1" -ProjectRoot $ProjectRoot

Write-Host "`n✨ Setup Complete! Run 'docker-compose -f docker-compose.dev.yml up -d' to start." -ForegroundColor Cyan
