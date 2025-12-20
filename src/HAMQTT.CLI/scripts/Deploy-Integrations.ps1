<#
.SYNOPSIS
    Generates a production-ready single docker-compose file.
#>

param (
    [string]$OutputDirectory,
    [string]$ProjectRoot,

    [Parameter(Mandatory = $false)]
    [string]$MqttHost,

    [Parameter(Mandatory = $false)]
    [string]$MqttUsername,

    [Parameter(Mandatory = $false)]
    [string]$MqttPassword
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/Common-Utils.ps1"

try
{
    $OriginUrl = git config --get remote.origin.url
    if ([string]::IsNullOrWhiteSpace($OriginUrl))
    {
        throw "Git remote 'origin' not found."
    }

    $RepoPath = $OriginUrl -replace '^(https?://|git@)github\.com[:/]', ''
    $RepoPath = $RepoPath -replace '\.git$', ''
    
    $ImageBaseUrl = "ghcr.io/${RepoPath}".ToLower()
    Write-Host "   ℹ️  Detected Image Base URL: $ImageBaseUrl" -ForegroundColor Gray
}
catch
{
    Write-Error "Failed to determine ImageBaseUrl from git config. Ensure you are in a git repository with a remote 'origin'. Error: $_"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($MqttHost)) {
    $MqttHost = Read-Host "Enter MQTT Host"
}

if ([string]::IsNullOrWhiteSpace($MqttUsername)) {
    $MqttUsername = Read-Host "Enter MQTT Username"
}

if ([string]::IsNullOrWhiteSpace($MqttPassword)) {
    $SecurePass = Read-Host -AsSecureString "Enter MQTT Password"
    $MqttPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePass))
}

if ( [string]::IsNullOrEmpty($OutputDirectory))
{
    $OutputDirectory = $ProjectRoot
}

if (-not (Test-Path $OutputDirectory))
{
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}
Write-Host "🚀 Starting deployment generation in '$OutputDirectory'..." -ForegroundColor Cyan

Write-Host "   🔍 Scanning for integrations..." -ForegroundColor Yellow
$Integrations = Get-Integrations

if ($Integrations.Count -eq 0)
{
    Write-Warning "   ⚠️  No integrations found."
}

$ServicesYaml = ""

foreach ($dir in $Integrations)
{
    $ProjectComposePath = Join-Path $dir.FullName "docker-compose.dev.yml"
    if (-not (Test-Path $ProjectComposePath))
    {
        continue
    }

    $CleanName = $dir.Name
    $KebabName = Get-KebabCase $CleanName
    $ImageUrl = "${ImageBaseUrl}/${KebabName}:latest"

    Write-Host "      Found: $CleanName -> Image: $ImageUrl" -ForegroundColor Gray

    $ServicesYaml += @"
  hamqtt-integration-${KebabName}:
    container_name: hamqtt-integration-${KebabName}
    image: ${ImageUrl}
    restart: unless-stopped
    network_mode: bridge
    environment:
      <<: *environment
`r`n
"@

    $envFilePath = Join-Path $dir.FullName ".env"
    $envFileContent = Get-Content -Path $envFilePath -ErrorAction SilentlyContinue
    foreach($line in $envFileContent)
    {
        $ServicesYaml += "`r`n      " + ($line -replace "=", ": ")
    }
}

$FinalCompose = @"
version: '3.8'

x-env: &environment
  MQTT_HOST: ${MqttHost}
  MQTT_USERNAME: ${MqttUsername}
  MQTT_PASSWORD: ${MqttPassword}

services:
$ServicesYaml
"@

$TargetComposePath = Join-Path $OutputDirectory "docker-compose.yml"
$FinalCompose | Set-Content -Path $TargetComposePath
Write-Host "   ✅ Generated docker-compose.yml." -ForegroundColor Green

Write-Host "`n✨ Deployment files ready in '$OutputDirectory'!" -ForegroundColor Cyan
