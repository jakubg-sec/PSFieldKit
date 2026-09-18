function New-ADGroupAccount {
    try {
        $Domain = Get-ADDomain -ErrorAction Stop
        $DefaultOU = $Domain.UsersContainer

        Write-Host "`nCreate Group" -ForegroundColor Cyan
        Write-Host "------------" -ForegroundColor DarkCyan

        $GroupName = Read-Host "Group name"

        if ([string]::IsNullOrWhiteSpace($GroupName)) {
            Write-Host "`nGroup name cannot be empty." -ForegroundColor Red
            return
        }

        $SamAccountName = Read-Host "SamAccountName [$GroupName]"

        if ([string]::IsNullOrWhiteSpace($SamAccountName)) {
            $SamAccountName = $GroupName
        }

        $Description = Read-Host "Description"

        Write-Host "`nGroup scope:"
        Write-Host "[1] Global"
        Write-Host "[2] DomainLocal"
        Write-Host "[3] Universal"

        $ScopeChoice = Read-Host "Select option"

        switch ($ScopeChoice) {
            '1' {
                $GroupScope = 'Global'
            }
            '2' {
                $GroupScope = 'DomainLocal'
            }
            '3' {
                $GroupScope = 'Universal'
            }
            default {
                Write-Host "`nInvalid group scope." -ForegroundColor Red
                return
            }
        }

        Write-Host "`nGroup category:"
        Write-Host "[1] Security"
        Write-Host "[2] Distribution"

        $CategoryChoice = Read-Host "Select option"

        switch ($CategoryChoice) {
            '1' {
                $GroupCategory = 'Security'
            }
            '2' {
                $GroupCategory = 'Distribution'
            }
            default {
                Write-Host "`nInvalid group category." -ForegroundColor Red
                return
            }
        }

        $OUInput = Read-Host "OU [$DefaultOU]"

        if ([string]::IsNullOrWhiteSpace($OUInput)) {
            $TargetPath = $DefaultOU
        }
        else {
            $TargetPath = $OUInput
        }

        $TargetObject = Get-ADObject `
            -Identity $TargetPath `
            -Properties objectClass `
            -ErrorAction Stop

        if ($TargetObject.ObjectClass -notin @(
            'organizationalUnit',
            'container'
        )) {
            Write-Host "`nTarget is not an OU or container." -ForegroundColor Red
            return
        }

        $SafeGroupName = $GroupName.Replace("'", "''")
        $SafeSamAccountName = $SamAccountName.Replace("'", "''")

        $ExistingByName = Get-ADGroup `
            -Filter "Name -eq '$SafeGroupName'" `
            -SearchBase $Domain.DistinguishedName `
            -ErrorAction Stop

        if ($ExistingByName) {
            Write-Host "`nA group with this name already exists." -ForegroundColor Red
            return
        }

        $ExistingBySam = Get-ADGroup `
            -Filter "SamAccountName -eq '$SafeSamAccountName'" `
            -SearchBase $Domain.DistinguishedName `
            -ErrorAction Stop

        if ($ExistingBySam) {
            Write-Host "`nA group with this SamAccountName already exists." -ForegroundColor Red
            return
        }

        Write-Host "`nGroup Summary" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor DarkCyan
        Write-Host "Name           : $GroupName"
        Write-Host "SamAccountName : $SamAccountName"
        Write-Host "Description    : $Description"
        Write-Host "Scope          : $GroupScope"
        Write-Host "Category       : $GroupCategory"
        Write-Host "Path           : $TargetPath"
        Write-Host ""

        $Confirm = Read-Host "Create this group? (Y/N)"

        if ($Confirm -notmatch '^[Yy]$') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        $Parameters = @{
            Name           = $GroupName
            SamAccountName = $SamAccountName
            GroupScope     = $GroupScope
            GroupCategory  = $GroupCategory
            Path           = $TargetPath
            ErrorAction    = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($Description)) {
            $Parameters.Description = $Description
        }

        New-ADGroup @Parameters

        Write-Host "`nGroup created successfully." -ForegroundColor Green
        Write-Host "Name           : $GroupName"
        Write-Host "SamAccountName : $SamAccountName"
        Write-Host "Path           : $TargetPath"
    }
    catch {
        Write-Host "`nFailed to create group." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}