# 1. Dynamically resolve path to config/config.psd1 relative to this script
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config\config.psd1"
$config = Import-PowerShellDataFile -Path $configPath

# 2. Prompt for credentials if $Credential isn't already defined
if (-not $Credential) {
    $Credential = Get-Credential
}

# 3. Execute the user creation logic remotely on the Domain Controller via Invoke-Command
Invoke-Command -ComputerName $config.RemoteIP -Credential $Credential -ScriptBlock {
    Import-Module ActiveDirectory

    # Path pointing directly to your host PC's shared folder inside the VM
    $CsvPath = "\\vmware-host\Shared Folders\csv_file\new_users.csv"
    $DomainDN = (Get-ADDomain).DistinguishedName
    $DomainDNS = (Get-ADDomain).DNSRoot
    $TargetOU = "OU=Employees,$DomainDN"

    # 1. Validate CSV file existence before proceeding
    if (-not (Test-Path -Path $CsvPath)) {
        Write-Error "CRITICAL: CSV file not found at path: $CsvPath"
        exit 1
    }

    # 2. Ensure target OU exists using a safe Try/Catch block
    try {
        Get-ADOrganizationalUnit -Identity $TargetOU -ErrorAction Stop | Out-Null
        Write-Host "Employees OU already exists." -ForegroundColor Yellow
    }
    catch {
        Write-Host "Employees OU not found. Creating it now..." -ForegroundColor Cyan
        New-ADOrganizationalUnit -Name "Employees" -Path $DomainDN
        Write-Host "Successfully created 'Employees' Organizational Unit." -ForegroundColor Green
    }

    # Import CSV records
    $NewUsers = Import-Csv -Path $CsvPath
    Write-Host "Processing $($NewUsers.Count) records from CSV..." -ForegroundColor Magenta

    # Loop through and provision each user with isolated error handling
    foreach ($User in $NewUsers) {
        $Sam = $User.SamAccountName

        # Check if user already exists
        if (Get-ADUser -Filter "SamAccountName -eq '$Sam'") {
            Write-Warning "User '$Sam' already exists. Skipping."
            continue
        }

        $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force
        $UPN = "$Sam@$DomainDNS"

        try {
            # Create the user account in AD
            New-ADUser `
                -Name "$($User.GivenName) $($User.Surname)" `
                -SamAccountName $Sam `
                -UserPrincipalName $UPN `
                -GivenName $User.GivenName `
                -Surname $User.Surname `
                -Department $User.Department `
                -Path $TargetOU `
                -AccountPassword $SecurePassword `
                -Enabled $true `
                -ChangePasswordAtLogon $true `
                -ErrorAction Stop

            Write-Host "Successfully provisioned: $Sam" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to provision user '$Sam': $_"
        }
    }
}