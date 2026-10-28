Import-Module ActiveDirectory

# Path pointing directly to your host PC's shared folder inside the VM
$CsvPath = "\\vmware-host\Shared Folders\csv_file\new_users.csv"
$DomainDN = (Get-ADDomain).DistinguishedName
$TargetOU = "OU=Employees,$DomainDN"

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

# Loop through and provision each user
foreach ($User in $NewUsers) {
    $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force
    $UPN = "$($User.SamAccountName)@lab.local"

    # Check if user already exists
    if (Get-ADUser -Filter "SamAccountName -eq '$($User.SamAccountName)'") {
        Write-Warning "User $($User.SamAccountName) already exists. Skipping."
        continue
    }

    # Create the user account in AD
    New-ADUser `
        -Name "$($User.GivenName) $($User.Surname)" `
        -SamAccountName $User.SamAccountName `
        -UserPrincipalName $UPN `
        -GivenName $User.GivenName `
        -Surname $User.Surname `
        -Department $User.Department `
        -Path $TargetOU `
        -AccountPassword $SecurePassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    Write-Host "Successfully provisioned: $($User.SamAccountName)" -ForegroundColor Green
}