function Remove-PSFieldKitExchangeDistributionGroupModerator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$Moderator
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

    $ModeratedBy = @($Group.ModeratedBy)

    if ($ModeratedBy.Count -eq 0) {
        Write-Host "`nNo moderators are configured for this distribution group." -ForegroundColor Yellow
        return
    }

    $Moderators = foreach ($ModeratorIdentity in $ModeratedBy) {
        try {
            $Recipient = Get-Recipient -Identity $ModeratorIdentity -ErrorAction Stop

            [PSCustomObject]@{
                Identity = $ModeratorIdentity
                DisplayName = $Recipient.DisplayName
                Alias = $Recipient.Alias
                PrimarySmtpAddress = [string]$Recipient.PrimarySmtpAddress
                RecipientTypeDetails = $Recipient.RecipientTypeDetails
            }
        }
        catch {
            [PSCustomObject]@{
                Identity = $ModeratorIdentity
                DisplayName = [string]$ModeratorIdentity
                Alias = ''
                PrimarySmtpAddress = ''
                RecipientTypeDetails = 'Unknown'
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($Moderator)) {
        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|      Remove Distribution Group Moderator     |" -ForegroundColor Cyan
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
        Write-Host "`nCURRENT MODERATORS" -ForegroundColor DarkCyan
        Write-Host ""

        $Index = 1

        foreach ($CurrentModerator in $Moderators) {
            Write-Host ("[{0}] {1}" -f $Index, $CurrentModerator.DisplayName)

            if (-not [string]::IsNullOrWhiteSpace($CurrentModerator.PrimarySmtpAddress)) {
                Write-Host ("    SMTP : {0}" -f $CurrentModerator.PrimarySmtpAddress)
            }

            Write-Host ("    Type : {0}" -f $CurrentModerator.RecipientTypeDetails)
            Write-Host ""

            $Index++
        }

        $Choice = Read-Host "Select moderator to remove"

        if ($Choice -notmatch '^\d+$') {
            Write-Host "`nInvalid moderator selection." -ForegroundColor Red
            return
        }

        $ModeratorIndex = [int]$Choice

        if ($ModeratorIndex -lt 1 -or $ModeratorIndex -gt $Moderators.Count) {
            Write-Host "`nInvalid moderator selection." -ForegroundColor Red
            return
        }

        $SelectedModerator = $Moderators[$ModeratorIndex - 1]
    }
    else {
        try {
            $Recipient = Get-Recipient -Identity $Moderator -ErrorAction Stop
        }
        catch {
            Write-Host "`nFailed to find moderator '$Moderator'." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            return
        }

        $SelectedModerator = $Moderators |
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

        if ($null -eq $SelectedModerator) {
            Write-Host "`nThe specified recipient is not a moderator of this distribution group." -ForegroundColor Yellow
            return
        }
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|      Remove Distribution Group Moderator     |" -ForegroundColor Cyan
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

    Write-Host "`nMODERATOR TO REMOVE" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $SelectedModerator.DisplayName)
    Write-Host ("Alias        : {0}" -f $SelectedModerator.Alias)
    Write-Host ("SMTP         : {0}" -f $SelectedModerator.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $SelectedModerator.RecipientTypeDetails)

    $Confirmation = Read-Host "`nType YES to remove this moderator"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nRemoving moderator..." -ForegroundColor Yellow

        Set-DistributionGroup `
            -Identity $Group.Identity `
            -ModeratedBy @{
                Remove = $SelectedModerator.Identity
            } `
            -ErrorAction Stop

        Write-Host "`nModerator removed successfully." -ForegroundColor Green
        Write-Host ("Group     : {0}" -f $Group.DisplayName)
        Write-Host ("Moderator : {0}" -f $SelectedModerator.DisplayName)
    }
    catch {
        Write-Host "`nFailed to remove moderator." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}