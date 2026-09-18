function New-PSFKADOrganizationalUnit {
    try {
        $Domain = Get-ADDomain -ErrorAction Stop

        Write-Host "`nCreate Organizational Unit" -ForegroundColor Cyan
        Write-Host "--------------------------" -ForegroundColor DarkCyan

        $Name = Read-Host "OU name"

        if ([string]::IsNullOrWhiteSpace($Name)) {
            Write-Host "`nOU name cannot be empty." -ForegroundColor Red
            return
        }

        $Description = Read-Host "Description"

        $ParentInput = Read-Host "Parent OU/DN [$($Domain.DistinguishedName)]"

        if ([string]::IsNullOrWhiteSpace($ParentInput)) {
            $ParentDN = $Domain.DistinguishedName
        }
        else {
            $ParentDN = $null

            # Full DN
            if ($ParentInput -match '^(OU|CN|DC)=') {
                try {
                    $ParentObject = Get-ADObject `
                        -Identity $ParentInput `
                        -Properties ObjectClass `
                        -ErrorAction Stop

                    $ParentDN = $ParentObject.DistinguishedName
                }
                catch {
                    Write-Host "`nParent object was not found." -ForegroundColor Red
                    return
                }
            }
            else {
                # Short OU name
                $SafeParentName = $ParentInput.Replace("'", "''")

                $ParentOUs = @(
                    Get-ADOrganizationalUnit `
                        -Filter "Name -eq '$SafeParentName'" `
                        -SearchBase $Domain.DistinguishedName `
                        -SearchScope Subtree `
                        -ErrorAction Stop
                )

                if ($ParentOUs.Count -eq 0) {
                    Write-Host "`nOU '$ParentInput' was not found." -ForegroundColor Red
                    return
                }

                if ($ParentOUs.Count -gt 1) {
                    Write-Host "`nMultiple OUs with the name '$ParentInput' were found:" -ForegroundColor Yellow
                    Write-Host ""

                    $ParentOUs |
                        Select-Object Name, DistinguishedName |
                        Format-Table -AutoSize

                    Write-Host "`nEnter the full Distinguished Name of the parent OU." -ForegroundColor Yellow
                    return
                }

                $ParentDN = $ParentOUs[0].DistinguishedName
            }
        }

        $ParentObject = Get-ADObject `
            -Identity $ParentDN `
            -Properties ObjectClass `
            -ErrorAction Stop

        if ($ParentObject.ObjectClass -notin @(
            'domainDNS',
            'organizationalUnit',
            'container'
        )) {
            Write-Host "`nParent object must be a domain, OU or container." -ForegroundColor Red
            return
        }

        $SafeName = $Name.Replace("'", "''")

        $ExistingOU = Get-ADOrganizationalUnit `
            -Filter "Name -eq '$SafeName'" `
            -SearchBase $ParentDN `
            -SearchScope OneLevel `
            -ErrorAction Stop

        if ($ExistingOU) {
            Write-Host "`nAn OU with this name already exists under the selected parent." -ForegroundColor Red
            return
        }

        Write-Host "`nProtect OU from accidental deletion?"
        Write-Host "[1] Yes"
        Write-Host "[2] No"

        $ProtectionChoice = Read-Host "Select option"

        switch ($ProtectionChoice) {
            '1' {
                $ProtectedFromAccidentalDeletion = $true
            }
            '2' {
                $ProtectedFromAccidentalDeletion = $false
            }
            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                return
            }
        }

        Write-Host "`nOU Summary" -ForegroundColor Cyan
        Write-Host "----------" -ForegroundColor DarkCyan
        Write-Host "Name        : $Name"
        Write-Host "Description : $Description"
        Write-Host "Parent      : $ParentDN"
        Write-Host "Protection  : $ProtectedFromAccidentalDeletion"
        Write-Host ""

        $Confirm = Read-Host "Create this OU? (Y/N)"

        if ($Confirm -notmatch '^[Yy]$') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        $Parameters = @{
            Name                            = $Name
            Path                            = $ParentDN
            ProtectedFromAccidentalDeletion = $ProtectedFromAccidentalDeletion
            ErrorAction                     = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($Description)) {
            $Parameters.Description = $Description
        }

        New-ADOrganizationalUnit @Parameters

        Write-Host "`nOrganizational Unit created successfully." -ForegroundColor Green
        Write-Host "Name   : $Name"
        Write-Host "Parent : $ParentDN"
    }
    catch {
        Write-Host "`nFailed to create organizational unit." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}