function Get-ADSiteInformation {

    try {

        $Sites = Get-ADReplicationSite -Filter * -ErrorAction Stop
        $Subnets = Get-ADReplicationSubnet -Filter * -ErrorAction Stop

        Write-Host "`nSites" -ForegroundColor Cyan
        Write-Host "-----" -ForegroundColor DarkCyan

        $Sites |
            Select-Object `
                Name,
                Description,
                DistinguishedName |
            Sort-Object Name |
            Format-Table -AutoSize

        Write-Host "`nSubnets" -ForegroundColor Cyan
        Write-Host "-------" -ForegroundColor DarkCyan

        $SubnetInfo = foreach ($Subnet in $Subnets) {

            $SiteName = if ($Subnet.Site) {
                $Subnet.Site.Name
            }
            else {
                '-'
            }

            [PSCustomObject]@{
                Name            = $Subnet.Name
                Site            = $SiteName
                Location        = $Subnet.Location
                Description     = $Subnet.Description
                DistinguishedName = $Subnet.DistinguishedName
            }
        }

        $SubnetInfo |
            Sort-Object Site, Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve AD Sites and Subnets." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}