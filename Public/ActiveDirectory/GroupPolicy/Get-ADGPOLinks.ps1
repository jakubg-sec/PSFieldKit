function Get-ADGPOLinks {

    $Identity = Read-Host "Enter GPO name or GUID"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nGPO identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Guid = [Guid]::Empty

        if ([Guid]::TryParse($Identity, [ref]$Guid)) {

            $GPO = Get-GPO `
                -Guid $Guid `
                -ErrorAction Stop
        }
        else {

            $GPO = Get-GPO `
                -Name $Identity `
                -ErrorAction Stop
        }

        $Domain = Get-ADDomain

        $Targets = @()

        # Domain root
        $Targets += [PSCustomObject]@{
            Name = $Domain.DNSRoot
            DN   = $Domain.DistinguishedName
            Type = 'Domain'
        }

        # OUs
        $Targets += Get-ADOrganizationalUnit `
            -Filter * `
            -Properties DistinguishedName |
            ForEach-Object {

                [PSCustomObject]@{
                    Name = $_.Name
                    DN   = $_.DistinguishedName
                    Type = 'OU'
                }
            }

        $Results = foreach ($Target in $Targets) {

            try {

                $Inheritance = Get-GPInheritance `
                    -Target $Target.DN `
                    -ErrorAction Stop

                foreach ($Link in $Inheritance.GpoLinks) {

                    if ($Link.GpoId -eq $GPO.Id) {

                        [PSCustomObject]@{
                            GPO          = $GPO.DisplayName
                            Target       = $Target.Name
                            TargetType   = $Target.Type
                            DistinguishedName = $Target.DN
                            LinkEnabled  = $Link.Enabled
                            Enforced     = $Link.Enforced
                            Order        = $Link.Order
                        }
                    }
                }
            }
            catch {
                # Skip targets that cannot be queried
            }
        }

        if (-not $Results) {

            Write-Host "`nGPO is not linked to any queried domain or OU." `
                -ForegroundColor Yellow

            return
        }

        Write-Host "`nGPO Links" -ForegroundColor Cyan
        Write-Host "---------" -ForegroundColor DarkCyan

        $Results |
            Sort-Object Target |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve GPO links." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}