<#
.SYNOPSIS
    Contains shared helper functions and path definitions.
#>

# --- Global Path Definitions ---
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $Global:ProjectRoot = (Get-Location).Path
} else {
    $Global:ProjectRoot = (Resolve-Path $ProjectRoot).Path
}
# Ensure local scope variable is updated if it was passed in
$ProjectRoot = $Global:ProjectRoot

# --- Shared Functions ---

function Get-KebabCase
{
    param ([string]$InputString)

    if ( [string]::IsNullOrWhiteSpace($InputString))
    {
        return $InputString
    }

    $s = $InputString -creplace '([A-Z])([A-Z][a-z])', '$1-$2'
    $s = $s -creplace '([a-z])([A-Z])', '$1-$2'

    return $s.ToLower()
}

function Set-EnvVariable
{
    param (
        [string]$Path,
        [string]$Key,
        [string]$Value
    )
    if (-not (Test-Path $Path))
    {
        New-Item -Path $Path -ItemType File -Force | Out-Null
    }

    $Content = Get-Content -Path $Path -ErrorAction SilentlyContinue
    if ($null -eq $Content)
    {
        $Content = @()
    }

    $Pattern = "^${Key}\s*="
    if ($Content -match $Pattern)
    {
        $Content = $Content | ForEach-Object { if ($_ -match $Pattern)
        {
            "${Key}=${Value}"
        }
        else
        {
            $_
        } }
    }
    else
    {
        $Content += "${Key}=${Value}"
    }
    $Content | Set-Content -Path $Path
}

function Get-IntegrationServiceBlock
{
    param ($KebabName)

    return @"
  hamqtt-integration-${KebabName}:
    container_name: hamqtt-integration-${KebabName}
    build:
      context: .
      args:
        - GITHUB_USERNAME=`${GITHUB_USERNAME}
        - GITHUB_PAT=`${GITHUB_PAT}
    env_file:
      - .env
      - ../.env
    restart: unless-stopped
    networks:
      - hamqtt-integration_network
    depends_on:
      - mosquitto
"@
}

function New-IntegrationComposeFile
{
    <#
    .SYNOPSIS
        Generates a fresh docker-compose.dev.yml file.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$IntegrationName,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $KebabName = Get-KebabCase $IntegrationName
    $ServiceBlock = Get-IntegrationServiceBlock -KebabName $KebabName

    $ComposeContent = @"
services:
$ServiceBlock
"@

    $ComposeContent | Set-Content -Path $OutputPath
}

function Update-IntegrationServiceInCompose
{
    <#
    .SYNOPSIS
        Updates ONLY the hamqtt-integration service definition within an existing file.
        Preserves other manually added services.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$IntegrationName,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $KebabName = Get-KebabCase $IntegrationName
    $ServiceName = "hamqtt-integration-${KebabName}"

    $CurrentContent = Get-Content -Path $FilePath -Raw
    $NewServiceBlock = Get-IntegrationServiceBlock -KebabName $KebabName

    $Regex = "(?ms)^\s{2}${ServiceName}:.*?(?=^\s{2}\S|\Z)"

    if ($CurrentContent -match $Regex)
    {
        $UpdatedContent = $CurrentContent -replace $Regex, $NewServiceBlock
        $UpdatedContent | Set-Content -Path $FilePath
        return $true # Updated
    }
    else
    {
        if ($CurrentContent -match "^services:")
        {
            $UpdatedContent = $CurrentContent -replace "^services:", "services:`n${NewServiceBlock}"
            $UpdatedContent | Set-Content -Path $FilePath
            return $true # Injected
        }
        return $false # Could not locate service or services block
    }
}

function Get-Integrations {
    $CandidateDirs = Get-ChildItem -Path $ProjectRoot -Directory
    $ValidIntegrations = @()

    foreach ($dir in $CandidateDirs)
    {
        # Search for .csproj files within the directory (limited depth to avoid deep scans)
        $Csproj = Get-ChildItem -Path $dir.FullName -Filter "*.csproj" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($Csproj)
        {
            $Content = Get-Content $Csproj.FullName -Raw
            # Check for PackageReference or ProjectReference to HAMQTT.Integration
            if ($Content -match 'Include="HAMQTT\.Integration"')
            {
                $ValidIntegrations += $dir
            }
        }
    }
    
    return $ValidIntegrations
}