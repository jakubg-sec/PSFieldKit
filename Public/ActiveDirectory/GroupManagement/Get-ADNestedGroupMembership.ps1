function Get-ADNestedGroupMembership {

    $Identity = Read-Host "Enter group name, SamAccountName or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nGroup identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $RootGroup = Get-ADGroup `
            -Identity $Identity `
            -ErrorAction Stop

        Write-Host "`nNested Group Membership" -ForegroundColor Cyan
        Write-Host "-----------------------"
        Write-Host "Root Group: $($RootGroup.Name)"
        Write-Host ""

        $VisitedGroups = @{}

        function Show-GroupTree {

            param(
                [Parameter(Mandatory)]
                [string]$GroupIdentity,

                [Parameter(Mandatory)]
                [string]$Prefix
            )

            $Group = Get-ADGroup `
                -Identity $GroupIdentity `
                -ErrorAction Stop

            if ($VisitedGroups.ContainsKey($Group.DistinguishedName)) {

                Write-Host "$Prefix[Cycle detected] $($Group.Name)" `
                    -ForegroundColor Red

                return
            }

            $VisitedGroups[$Group.DistinguishedName] = $true

            $NestedGroups = Get-ADGroupMember `
                -Identity $Group `
                -ErrorAction Stop |
                Where-Object {
                    $_.ObjectClass -eq 'group'
                } |
                Sort-Object Name

            if (-not $NestedGroups) {
                return
            }

            for ($i = 0; $i -lt $NestedGroups.Count; $i++) {

                $NestedGroup = $NestedGroups[$i]

                if ($i -eq ($NestedGroups.Count - 1)) {
                    $Branch = "\-- "
                    $NextPrefix = "$Prefix    "
                }
                else {
                    $Branch = "|-- "
                    $NextPrefix = "$Prefix|   "
                }

                Write-Host "$Prefix$Branch$($NestedGroup.Name)" `
                    -ForegroundColor White

                Show-GroupTree `
                    -GroupIdentity $NestedGroup.DistinguishedName `
                    -Prefix $NextPrefix
            }
        }

        Write-Host "$($RootGroup.Name)" -ForegroundColor Yellow

        $VisitedGroups[$RootGroup.DistinguishedName] = $true

        $NestedGroups = Get-ADGroupMember `
            -Identity $RootGroup `
            -ErrorAction Stop |
            Where-Object {
                $_.ObjectClass -eq 'group'
            } |
            Sort-Object Name

        if (-not $NestedGroups) {

            Write-Host "`nNo nested groups found." `
                -ForegroundColor Yellow

            return
        }

        for ($i = 0; $i -lt $NestedGroups.Count; $i++) {

            $NestedGroup = $NestedGroups[$i]

            if ($i -eq ($NestedGroups.Count - 1)) {
                $Branch = "\-- "
                $NextPrefix = "    "
            }
            else {
                $Branch = "|-- "
                $NextPrefix = "|   "
            }

            Write-Host "$Branch$($NestedGroup.Name)" `
                -ForegroundColor White

            Show-GroupTree `
                -GroupIdentity $NestedGroup.DistinguishedName `
                -Prefix $NextPrefix
        }
    }
    catch {

        Write-Host "`nFailed to retrieve nested group membership." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}