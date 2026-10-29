# 1. Dynamically resolve path to config/config.ps1d relative to this script
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config\config.psd1"
$config = Import-PowerShellDataFile -Path $configPath

# 2. Prompt for credentials if $Credential isn't already defined
if (-not $Credential) {
    $Credential = Get-Credential
}

# 3. Enter the session using the imported RemoteIP
Enter-PSSession -ComputerName $config.RemoteIP -Credential $Credential