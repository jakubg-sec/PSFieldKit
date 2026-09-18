function Get-ADReplicationMetadata {

    $Identity = Read-Host "Enter object identity (DN, GUID, SID or sAMAccountName)"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nObject identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Object = Get-ADObject `
            -Identity $Identity `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "Object found:" -ForegroundColor Cyan
        Write-Host "Name : $($Object.Name)"
        Write-Host "Class: $($Object.ObjectClass)"
        Write-Host "DN   : $($Object.DistinguishedName)"
        Write-Host ""

        $Server = Read-Host "Enter domain controller name (leave empty for default DC)"

        $Parameters = @{
            Object     = $Object
            Properties = '*'
            ErrorAction = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($Server)) {

            $DC = Get-ADDomainController `
                -Identity $Server `
                -ErrorAction Stop

            $Parameters.Server = $DC.HostName
        }

        $Metadata = Get-ADReplicationAttributeMetadata @Parameters

        if (-not $Metadata) {

            Write-Host "`nNo replication metadata found." `
                -ForegroundColor Yellow

            return
        }

        $Results = foreach ($Entry in $Metadata) {

            [PSCustomObject]@{
                Attribute                     = $Entry.AttributeName
                Version                       = $Entry.Version
                LastOriginatingChange         = $Entry.LastOriginatingChangeTime
                OriginatingServer             = $Entry.OriginatingServer
                OriginatingUSN                = $Entry.OriginatingUSN
                LocalUSN                      = $Entry.LocalUSN
                InvocationId                 = $Entry.LastOriginatingChangeDirectoryServerInvocationId
            }
        }

        Write-Host "`nReplication Metadata" `
            -ForegroundColor Cyan

        Write-Host "---------------------" `
            -ForegroundColor DarkCyan

        $Results |
            Sort-Object LastOriginatingChange -Descending |
            Format-Table `
                Attribute,
                Version,
                LastOriginatingChange,
                OriginatingServer,
                OriginatingUSN,
                LocalUSN `
                -Wrap `
                -AutoSize

        Write-Host ""
        Write-Host "Object:" -ForegroundColor Cyan
        Write-Host $Object.DistinguishedName

        if ($Server) {
            Write-Host "Read from DC: $($Parameters.Server)"
        }
        else {
            Write-Host "Read from DC: default domain controller"
        }
    }
    catch {

        Write-Host "`nFailed to retrieve replication metadata." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}