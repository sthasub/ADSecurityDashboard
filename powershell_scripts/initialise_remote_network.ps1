# 1. Dynamically resolve path to config/config.ps1d relative to this script
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config\config.psd1"
$config = Import-PowerShellDataFile -Path $configPath

# 1. Initialize the WinRM client framework locally
winrm quickconfig -q

Set-NetConnectionProfile -NetworkCategory Private

# 2. Now run your TrustedHosts command again
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $config.RemoteIP -Force