function Get-ADTrustInformation {
    $Identity = Read-Host "Enter trusted domain name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nTrusted domain name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Trust = Get-ADTrust `
            -Identity $Identity `
            -Properties * `
            -ErrorAction Stop

        $TrustDirection = switch ($Trust.Direction) {
            'Inbound' {
                'Inbound'
            }
            'Outbound' {
                'Outbound'
            }
            'Bidirectional' {
                'Bidirectional'
            }
            default {
                $Trust.Direction
            }
        }

        $TrustAttributes = @()

        if ($Trust.ForestTransitive) {
            $TrustAttributes += 'ForestTransitive'
        }

        if ($Trust.IntraForest) {
            $TrustAttributes += 'IntraForest'
        }

        if ($Trust.UplevelOnly) {
            $TrustAttributes += 'UplevelOnly'
        }

        if ($Trust.SelectiveAuthentication) {
            $TrustAttributes += 'SelectiveAuthentication'
        }

        if ($Trust.SIDFilteringQuarantined) {
            $TrustAttributes += 'SIDFilteringQuarantined'
        }

        if ($Trust.TGTDelegation) {
            $TrustAttributes += 'TGTDelegation'
        }

        if ($Trust.UsesAESKeys) {
            $TrustAttributes += 'UsesAESKeys'
        }

        if ($Trust.UsesRC4Encryption) {
            $TrustAttributes += 'UsesRC4Encryption'
        }

        if (-not $TrustAttributes) {
            $TrustAttributes = 'None'
        }
        else {
            $TrustAttributes = $TrustAttributes -join ', '
        }

        Write-Host "`nAD Trust Information" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            Name                  = $Trust.Name
            Source                = $Trust.Source
            Target                = $Trust.Target
            Direction             = $TrustDirection
            TrustType             = $Trust.TrustType
            ForestTransitive      = $Trust.ForestTransitive
            IntraForest           = $Trust.IntraForest
            UplevelOnly           = $Trust.UplevelOnly
            SelectiveAuthentication = $Trust.SelectiveAuthentication
            SIDFilteringQuarantined = $Trust.SIDFilteringQuarantined
            TGTDelegation          = $Trust.TGTDelegation
            UsesAESKeys            = $Trust.UsesAESKeys
            UsesRC4Encryption      = $Trust.UsesRC4Encryption
            TrustAttributes        = $TrustAttributes
            Created               = $Trust.Created
            Modified              = $Trust.Modified
            DistinguishedName     = $Trust.DistinguishedName
        } | Format-List
    }
    catch {
        Write-Host "`nFailed to retrieve trust information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}