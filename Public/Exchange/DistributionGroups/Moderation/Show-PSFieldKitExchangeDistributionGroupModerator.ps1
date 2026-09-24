function Show-PSFieldKitExchangeDistributionGroupModerator {
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
    Write-Host "|         Distribution Group Moderators        |" -ForegroundColor Cyan
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

    Write-Host "`nMODERATION" -ForegroundColor DarkCyan

    if ([bool]$Group.ModerationEnabled) {
        Write-Host "Status : Enabled" -ForegroundColor Green
    }
    else {
        Write-Host "Status : Disabled" -ForegroundColor Yellow
    }

    $Moderators = @($Group.ModeratedBy)

    if ($Moderators.Count -eq 0) {
        Write-Host "`nNo explicit moderators are configured." -ForegroundColor Yellow

        if ([bool]$Group.ModerationEnabled) {
            Write-Host "The group does not have any explicitly assigned moderators." -ForegroundColor Yellow
        }

        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "`nMODERATORS" -ForegroundColor DarkCyan
    Write-Host ""

    $Index = 1

    foreach ($Moderator in $Moderators) {
        try {
            $Recipient = Get-Recipient -Identity $Moderator -ErrorAction Stop

            Write-Host ("[{0}] {1}" -f $Index, $Recipient.DisplayName)

            if (-not [string]::IsNullOrWhiteSpace([string]$Recipient.Alias)) {
                Write-Host ("    Alias : {0}" -f $Recipient.Alias)
            }

            if (-not [string]::IsNullOrWhiteSpace([string]$Recipient.PrimarySmtpAddress)) {
                Write-Host ("    SMTP  : {0}" -f $Recipient.PrimarySmtpAddress)
            }

            Write-Host ("    Type  : {0}" -f $Recipient.RecipientTypeDetails)
        }
        catch {
            Write-Host ("[{0}] {1}" -f $Index, $Moderator)
            Write-Host "    Type  : Unknown"
        }

        Write-Host ""
        $Index++
    }

    Write-Host ("Total moderators: {0}" -f $Moderators.Count) -ForegroundColor Cyan

    Read-Host "`nPress Enter to continue" | Out-Null
}