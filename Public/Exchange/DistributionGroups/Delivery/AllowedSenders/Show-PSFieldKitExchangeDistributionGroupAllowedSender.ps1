function Show-PSFieldKitExchangeDistributionGroupAllowedSender {
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

    $AllowedSenders = @($Group.AcceptMessagesOnlyFromSendersOrMembers)

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|              Allowed Senders                 |" -ForegroundColor Cyan
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

    if ($AllowedSenders.Count -eq 0) {
        Write-Host "`nNo allowed senders are configured." -ForegroundColor Yellow
        Write-Host "All senders are currently allowed by this setting." -ForegroundColor Green
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "`nALLOWED SENDERS" -ForegroundColor DarkCyan
    Write-Host ""

    $Index = 1

    foreach ($Sndr in $AllowedSenders) {
        try {
            $Recipient = Get-Recipient -Identity $Sndr -ErrorAction Stop

            Write-Host ("[{0}] {1}" -f $Index, $Recipient.DisplayName)
            Write-Host ("    Alias : {0}" -f $Recipient.Alias)

            if (-not [string]::IsNullOrWhiteSpace([string]$Recipient.PrimarySmtpAddress)) {
                Write-Host ("    SMTP  : {0}" -f $Recipient.PrimarySmtpAddress)
            }

            Write-Host ("    Type  : {0}" -f $Recipient.RecipientTypeDetails)
        }
        catch {
            Write-Host ("[{0}] {1}" -f $Index, $Sndr)
            Write-Host "    Type  : Unknown"
        }

        Write-Host ""
        $Index++
    }

    Write-Host ("Total allowed senders: {0}" -f $AllowedSenders.Count) -ForegroundColor Cyan
    Read-Host "`nPress Enter to continue" | Out-Null
}