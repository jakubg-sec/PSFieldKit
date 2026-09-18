function Get-ADOUInformation {

    $Identity = Read-Host "Enter OU name or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nOU identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        # ---------------------------------------
        # Try Distinguished Name / Identity
        # ---------------------------------------

        $OU = $null

        try {

            $OU = Get-ADOrganizationalUnit `
                -Identity $Identity `
                -Properties `
                    Description,
                    ManagedBy,
                    ProtectedFromAccidentalDeletion,
                    Created,
                    Modified,
                    DistinguishedName `
                -ErrorAction Stop
        }
        catch {

            # ---------------------------------------
            # If Identity failed, search by OU name
            # ---------------------------------------

            $EscapedName = $Identity.Replace("'", "''")

            $mtch = @(
                Get-ADOrganizationalUnit `
                    -Filter "Name -eq '$EscapedName'" `
                    -Properties `
                        Description,
                        ManagedBy,
                        ProtectedFromAccidentalDeletion,
                        Created,
                        Modified,
                        DistinguishedName `
                    -ErrorAction Stop
            )

            if ($mtch.Count -eq 0) {

                throw "Organizational Unit '$Identity' was not found."
            }

            if ($mtch.Count -gt 1) {

                Write-Host "`nMultiple OUs with this name were found:" `
                    -ForegroundColor Yellow

                $mtch |
                    Select-Object Name, DistinguishedName |
                    Format-Table -AutoSize

                Write-Host "`nUse Distinguished Name to select the exact OU." `
                    -ForegroundColor Yellow

                return
            }

            $OU = $mtch[0]
        }

        # ---------------------------------------
        # Get direct children
        # ---------------------------------------

        $Children = @(
            Get-ADObject `
                -SearchBase $OU.DistinguishedName `
                -SearchScope OneLevel `
                -Filter * `
                -ErrorAction Stop
        )

        # ---------------------------------------
        # Count objects
        # ---------------------------------------

        $Users = @(
            $Children |
            Where-Object {
                $_.ObjectClass -eq 'user'
            }
        ).Count

        $Computers = @(
            $Children |
            Where-Object {
                $_.ObjectClass -eq 'computer'
            }
        ).Count

        $Groups = @(
            $Children |
            Where-Object {
                $_.ObjectClass -eq 'group'
            }
        ).Count

        $SubOUs = @(
            $Children |
            Where-Object {
                $_.ObjectClass -eq 'organizationalUnit'
            }
        ).Count

        # ---------------------------------------
        # Display information
        # ---------------------------------------

        [PSCustomObject]@{

            Name                           = $OU.Name
            DistinguishedName              = $OU.DistinguishedName
            Description                    = $OU.Description
            ManagedBy                      = $OU.ManagedBy
            ProtectedFromAccidentalDeletion = `
                $OU.ProtectedFromAccidentalDeletion

            Users                          = $Users
            Computers                      = $Computers
            Groups                         = $Groups
            ChildOUs                       = $SubOUs

            Created                        = $OU.Created
            Modified                       = $OU.Modified
        } |
        Format-List

    }

    catch {

        Write-Host "`nFailed to retrieve OU information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}