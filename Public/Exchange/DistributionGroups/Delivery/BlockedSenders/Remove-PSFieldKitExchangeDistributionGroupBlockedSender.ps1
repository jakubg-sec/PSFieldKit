function Remove-PSFieldKitExchangeDistributionGroupBlockedSender {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$Sndr
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

    if (-not (Get-Command Set-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Set-DistributionGroup' is not available." -ForegroundColor Red
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

    $IndividualSenders = @($Group.RejectMessagesFrom)
    $GroupSenders = @($Group.RejectMessagesFromDLMembers)

    if ($IndividualSenders.Count -eq 0 -and $GroupSenders.Count -eq 0) {
        Write-Host "`nNo blocked senders are configured for this distribution group." -ForegroundColor Yellow
        return
    }

    $BlockedSenders = New-Object System.Collections.ArrayList

    foreach ($BlockedSender in $IndividualSenders) {
        try {
            $Recipient = Get-Recipient -Identity $BlockedSender -ErrorAction Stop

            [void]$BlockedSenders.Add([PSCustomObject]@{
                Identity = $BlockedSender
                DisplayName = $Recipient.DisplayName
                Alias = $Recipient.Alias
                PrimarySmtpAddress = [string]$Recipient.PrimarySmtpAddress
                RecipientTypeDetails = $Recipient.RecipientTypeDetails
                IsGroup = $false
            })
        }
        catch {
            [void]$BlockedSenders.Add([PSCustomObject]@{
                Identity = $BlockedSender
                DisplayName = [string]$BlockedSender
                Alias = ''
                PrimarySmtpAddress = ''
                RecipientTypeDetails = 'Unknown'
                IsGroup = $false
            })
        }
    }

    foreach ($BlockedSender in $GroupSenders) {
        try {
            $Recipient = Get-Recipient -Identity $BlockedSender -ErrorAction Stop

            [void]$BlockedSenders.Add([PSCustomObject]@{
                Identity = $BlockedSender
                DisplayName = $Recipient.DisplayName
                Alias = $Recipient.Alias
                PrimarySmtpAddress = [string]$Recipient.PrimarySmtpAddress
                RecipientTypeDetails = $Recipient.RecipientTypeDetails
                IsGroup = $true
            })
        }
        catch {
            [void]$BlockedSenders.Add([PSCustomObject]@{
                Identity = $BlockedSender
                DisplayName = [string]$BlockedSender
                Alias = ''
                PrimarySmtpAddress = ''
                RecipientTypeDetails = 'Unknown'
                IsGroup = $true
            })
        }
    }

    if ([string]::IsNullOrWhiteSpace($Sndr)) {
        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|         Remove Blocked Sender                |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        $GroupDisplayName = [string]$Group.DisplayName

        if ([string]::IsNullOrWhiteSpace($GroupDisplayName)) {
            $GroupDisplayName = [string]$Group.Name
        }

        if ($GroupDisplayName.Length -gt 36) {
            $GroupDisplayName = $GroupDisplayName.Substring(0, 33) + "..."
        }

        Write-Host ("|  Group : {0,-36}|" -f $GroupDisplayName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "`nCURRENT BLOCKED SENDERS" -ForegroundColor DarkCyan
        Write-Host ""

        $Index = 1

        foreach ($BlockedSender in $BlockedSenders) {
            Write-Host ("[{0}] {1}" -f $Index, $BlockedSender.DisplayName)

            if (-not [string]::IsNullOrWhiteSpace($BlockedSender.PrimarySmtpAddress)) {
                Write-Host ("    SMTP : {0}" -f $BlockedSender.PrimarySmtpAddress)
            }

            Write-Host ("    Type : {0}" -f $BlockedSender.RecipientTypeDetails)
            Write-Host ("    Kind : {0}" -f $(if ($BlockedSender.IsGroup) { 'Group' } else { 'Recipient' }))
            Write-Host ""

            $Index++
        }

        $Choice = Read-Host "Select sender to remove"

        if (-not $Choice -match '^\d+$') {
            Write-Host "`nInvalid sender selection." -ForegroundColor Red
            return
        }

        $SndrIndex = [int]$Choice

        if ($SndrIndex -lt 1 -or $SndrIndex -gt $BlockedSenders.Count) {
            Write-Host "`nInvalid sender selection." -ForegroundColor Red
            return
        }

        $SelectedSender = $BlockedSenders[$SndrIndex - 1]
    }
    else {
        try {
            $Recipient = Get-Recipient -Identity $Sndr -ErrorAction Stop
        }
        catch {
            Write-Host "`nFailed to find recipient '$Sndr'." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            return
        }

        $SelectedSender = $BlockedSenders |
            Where-Object {
                $_.Identity -eq $Recipient.Identity -or
                $_.Identity -eq $Recipient.DistinguishedName -or
                $_.Alias -eq $Recipient.Alias -or
                (
                    -not [string]::IsNullOrWhiteSpace($_.PrimarySmtpAddress) -and
                    $_.PrimarySmtpAddress -eq [string]$Recipient.PrimarySmtpAddress
                )
            } |
            Select-Object -First 1

        if ($null -eq $SelectedSender) {
            Write-Host "`nThe specified sender is not in the blocked senders list." -ForegroundColor Yellow
            return
        }
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|         Remove Blocked Sender                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $GroupDisplayName = [string]$Group.DisplayName

    if ([string]::IsNullOrWhiteSpace($GroupDisplayName)) {
        $GroupDisplayName = [string]$Group.Name
    }

    if ($GroupDisplayName.Length -gt 36) {
        $GroupDisplayName = $GroupDisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group : {0,-36}|" -f $GroupDisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nSENDER TO REMOVE" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $SelectedSender.DisplayName)
    Write-Host ("Alias        : {0}" -f $SelectedSender.Alias)
    Write-Host ("SMTP         : {0}" -f $SelectedSender.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $SelectedSender.RecipientTypeDetails)
    Write-Host ("Kind         : {0}" -f $(if ($SelectedSender.IsGroup) { 'Group' } else { 'Recipient' }))

    $Confirmation = Read-Host "`nType YES to remove this blocked sender"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nRemoving blocked sender..." -ForegroundColor Yellow

        if ($SelectedSender.IsGroup) {
            Set-DistributionGroup `
                -Identity $Group.Identity `
                -RejectMessagesFromDLMembers @{
                    Remove = $SelectedSender.Identity
                } `
                -ErrorAction Stop
        }
        else {
            Set-DistributionGroup `
                -Identity $Group.Identity `
                -RejectMessagesFrom @{
                    Remove = $SelectedSender.Identity
                } `
                -ErrorAction Stop
        }

        Write-Host "`nBlocked sender removed successfully." -ForegroundColor Green
        Write-Host ("Group  : {0}" -f $Group.DisplayName)
        Write-Host ("Sender : {0}" -f $SelectedSender.DisplayName)
    }
    catch {
        Write-Host "`nFailed to remove blocked sender." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}