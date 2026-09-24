function Show-PSFieldKitExchangeDistributionGroupDeliverySettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        return
    }

    if (-not (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        return
    }

    if (-not (Get-Command Get-Recipient -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-Recipient' is not available." -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter distribution group name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDistribution group identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Group = Get-DistributionGroup -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find distribution group '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|      Distribution Group Delivery             |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Group.DisplayName

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = [string]$Group.Name
    }

    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group : {0,-36}|" -f $DisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nAUTHENTICATION" -ForegroundColor DarkCyan

    $RequireAuth = [bool]$Group.RequireSenderAuthenticationEnabled

    if ($RequireAuth) {
        Write-Host "Require authenticated senders : Enabled" -ForegroundColor Green
        Write-Host "External senders              : Rejected" -ForegroundColor Yellow
    }
    else {
        Write-Host "Require authenticated senders : Disabled" -ForegroundColor Yellow
        Write-Host "External senders              : Allowed" -ForegroundColor Green
    }

    Write-Host "`nALLOWED SENDERS" -ForegroundColor DarkCyan

    $AllowedSenders = @(
        $Group.AcceptMessagesOnlyFromSendersOrMembers
    )

    if ($AllowedSenders.Count -eq 0) {
        Write-Host "Mode : All senders allowed"
    }
    else {
        Write-Host "Mode : Only listed senders/groups are allowed"
        Write-Host ""

        foreach ($Sndr in $AllowedSenders) {
            try {
                $Recipient = Get-Recipient -Identity $Sndr -ErrorAction Stop

                Write-Host (" - {0} <{1}>" -f $Recipient.DisplayName, $Recipient.PrimarySmtpAddress)
            }
            catch {
                Write-Host (" - {0}" -f $Sndr)
            }
        }

        Write-Host ""
        Write-Host ("Count: {0}" -f $AllowedSenders.Count) -ForegroundColor DarkGray
    }

    Write-Host "`nBLOCKED SENDERS" -ForegroundColor DarkCyan

    $BlockedSenders = @(
        $Group.RejectMessagesFromSendersOrMembers
    )

    if ($BlockedSenders.Count -eq 0) {
        Write-Host "Mode : No senders/groups are blocked"
    }
    else {
        Write-Host "Mode : Listed senders/groups are blocked"
        Write-Host ""

        foreach ($Sndr in $BlockedSenders) {
            try {
                $Recipient = Get-Recipient -Identity $Sndr -ErrorAction Stop

                Write-Host (" - {0} <{1}>" -f $Recipient.DisplayName, $Recipient.PrimarySmtpAddress)
            }
            catch {
                Write-Host (" - {0}" -f $Sndr)
            }
        }

        Write-Host ""
        Write-Host ("Count: {0}" -f $BlockedSenders.Count) -ForegroundColor DarkGray
    }

    Write-Host "`nMODERATION" -ForegroundColor DarkCyan

    if ($Group.PSObject.Properties.Name -contains 'ModerationEnabled') {
        if ($Group.ModerationEnabled) {
            Write-Host "Moderation : Enabled" -ForegroundColor Yellow

            if ($Group.PSObject.Properties.Name -contains 'ModeratedBy') {
                $Moderators = @($Group.ModeratedBy)

                if ($Moderators.Count -gt 0) {
                    Write-Host "Moderators :"

                    foreach ($Moderator in $Moderators) {
                        try {
                            $Recipient = Get-Recipient -Identity $Moderator -ErrorAction Stop
                            Write-Host (" - {0} <{1}>" -f $Recipient.DisplayName, $Recipient.PrimarySmtpAddress)
                        }
                        catch {
                            Write-Host (" - {0}" -f $Moderator)
                        }
                    }
                }
                else {
                    Write-Host "Moderators : Group owners"
                }
            }
        }
        else {
            Write-Host "Moderation : Disabled" -ForegroundColor Green
        }
    }

    Write-Host "`nMESSAGE SIZE" -ForegroundColor DarkCyan

    if ($Group.PSObject.Properties.Name -contains 'MaxReceiveSize') {
        Write-Host ("Maximum receive size : {0}" -f $Group.MaxReceiveSize)
    }

    if ($Group.PSObject.Properties.Name -contains 'MaxSendSize') {
        Write-Host ("Maximum send size    : {0}" -f $Group.MaxSendSize)
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}