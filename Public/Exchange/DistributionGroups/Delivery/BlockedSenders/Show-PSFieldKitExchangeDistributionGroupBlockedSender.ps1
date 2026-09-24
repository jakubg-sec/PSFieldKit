function Show-PSFieldKitExchangeDistributionGroupBlockedSender {
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

    $IndividualSenders = @($Group.RejectMessagesFrom)
    $GroupSenders = @($Group.RejectMessagesFromDLMembers)

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|              Blocked Senders                 |" -ForegroundColor Cyan
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

    if ($IndividualSenders.Count -eq 0 -and $GroupSenders.Count -eq 0) {
        Write-Host "`nNo blocked senders are configured." -ForegroundColor Yellow
        Write-Host "No sender-specific delivery blocks are currently configured." -ForegroundColor Green
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($IndividualSenders.Count -gt 0) {
        Write-Host "`nBLOCKED SENDERS" -ForegroundColor DarkCyan
        Write-Host ""

        $Index = 1

        foreach ($Sndr in $IndividualSenders) {
            try {
                $Recipient = Get-Recipient -Identity $Sndr -ErrorAction Stop

                Write-Host ("[{0}] {1}" -f $Index, $Recipient.DisplayName)
                Write-Host ("    Alias : {0}" -f $Recipient.Alias)

                if (-not [string]::IsNullOrWhiteSpace([string]$Recipient.PrimarySmtpAddress)) {
                    Write-Host ("    SMTP  : {0}" -f $Recipient.PrimarySmtpAddress)
                }

                Write-Host ("    Type  : {0}" -f $Recipient.RecipientTypeDetails)
                Write-Host "    Kind  : Recipient"
            }
            catch {
                Write-Host ("[{0}] {1}" -f $Index, $Sndr)
                Write-Host "    Type  : Unknown"
                Write-Host "    Kind  : Recipient"
            }

            Write-Host ""
            $Index++
        }
    }

    if ($GroupSenders.Count -gt 0) {
        Write-Host "`nBLOCKED GROUPS" -ForegroundColor DarkCyan
        Write-Host ""

        $Index = 1

        foreach ($Sndr in $GroupSenders) {
            try {
                $Recipient = Get-Recipient -Identity $Sndr -ErrorAction Stop

                Write-Host ("[{0}] {1}" -f $Index, $Recipient.DisplayName)
                Write-Host ("    Alias : {0}" -f $Recipient.Alias)

                if (-not [string]::IsNullOrWhiteSpace([string]$Recipient.PrimarySmtpAddress)) {
                    Write-Host ("    SMTP  : {0}" -f $Recipient.PrimarySmtpAddress)
                }

                Write-Host ("    Type  : {0}" -f $Recipient.RecipientTypeDetails)
                Write-Host "    Kind  : Group"
            }
            catch {
                Write-Host ("[{0}] {1}" -f $Index, $Sndr)
                Write-Host "    Type  : Unknown"
                Write-Host "    Kind  : Group"
            }

            Write-Host ""
            $Index++
        }
    }

    Write-Host ("Blocked recipients : {0}" -f $IndividualSenders.Count) -ForegroundColor Cyan
    Write-Host ("Blocked groups     : {0}" -f $GroupSenders.Count) -ForegroundColor Cyan
    Write-Host ("Total blocked      : {0}" -f ($IndividualSenders.Count + $GroupSenders.Count)) -ForegroundColor Cyan

    Read-Host "`nPress Enter to continue" | Out-Null
}