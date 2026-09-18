function Get-ADOUTree {

    try {

        $Domain = Get-ADDomain -ErrorAction Stop

        Write-Host "`nOrganizational Unit Tree" -ForegroundColor Cyan
        Write-Host "------------------------" -ForegroundColor DarkCyan
        Write-Host $Domain.DNSRoot
        Write-Host ""

        $OUs = Get-ADOrganizationalUnit `
            -Filter * `
            -Properties DistinguishedName `
            -ErrorAction Stop

        if (-not $OUs) {
            Write-Host "No organizational units found." -ForegroundColor Yellow
            return
        }

        # Mapa OU po DistinguishedName
        $OUMap = @{}

        foreach ($OU in $OUs) {
            $OUMap[$OU.DistinguishedName] = $OU
        }

        # Mapa rodzic -> dzieci
        $ChildrenMap = @{}

        foreach ($OU in $OUs) {

            $DNParts = $OU.DistinguishedName -split ','

            if ($DNParts.Count -le 1) {
                continue
            }

            # Usuwamy bieżące OU i otrzymujemy DN rodzica
            $ParentDN = ($DNParts[1..($DNParts.Count - 1)] -join ',')

            # Jeżeli rodzicem jest domena
            if ($ParentDN -eq $Domain.DistinguishedName) {

                if (-not $ChildrenMap.ContainsKey($Domain.DistinguishedName)) {
                    $ChildrenMap[$Domain.DistinguishedName] = @()
                }

                $ChildrenMap[$Domain.DistinguishedName] += $OU
            }

            # Jeżeli rodzicem jest inne OU
            elseif ($OUMap.ContainsKey($ParentDN)) {

                if (-not $ChildrenMap.ContainsKey($ParentDN)) {
                    $ChildrenMap[$ParentDN] = @()
                }

                $ChildrenMap[$ParentDN] += $OU
            }
        }

        function Show-OUTree {

            param(
                [Parameter(Mandatory)]
                [string]$ParentDN,

                [string]$Prefix = ''
            )

            if (-not $ChildrenMap.ContainsKey($ParentDN)) {
                return
            }

            $Children = @(
                $ChildrenMap[$ParentDN] |
                Sort-Object Name
            )

            for ($Index = 0; $Index -lt $Children.Count; $Index++) {

                $Child = $Children[$Index]

                $IsLast = $Index -eq ($Children.Count - 1)

                if ($IsLast) {
                    $Branch = '\-- '
                    $ChildPrefix = "$Prefix    "
                }
                else {
                    $Branch = '|-- '
                    $ChildPrefix = "$Prefix|   "
                }

                Write-Host "$Prefix$Branch$($Child.Name)"

                Show-OUTree `
                    -ParentDN $Child.DistinguishedName `
                    -Prefix $ChildPrefix
            }
        }

        Show-OUTree `
            -ParentDN $Domain.DistinguishedName `
            -Prefix ''

    }
    catch {

        Write-Host "`nFailed to retrieve OU tree." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}