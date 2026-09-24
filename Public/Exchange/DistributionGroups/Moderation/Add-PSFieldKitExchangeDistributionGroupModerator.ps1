function Add-PSFieldKitExchangeDistributionGroupModerator {
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

    if ($Group.RecipientTypeDetails -eq 'DynamicDistributionGroup') {
        Write-Host "`nDynamic distribution groups are not supported by this operation." -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrWhiteSpace($Moderator)) {
        $Moderator = Read-Host "Enter moderator name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Moderator)) {
        Write-Host "`nModerator identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Recipient = Get-Recipient -Identity $Moderator -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find moderator '$Moderator'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    $AllowedModeratorTypes = @(
        'UserMailbox',
        'MailUser',
        'MailContact'
    )

    if ($AllowedModeratorTypes -notcontains $Recipient.RecipientTypeDetails) {
        Write-Host "`nRecipient type '$($Recipient.RecipientTypeDetails)' cannot be assigned as a moderator." -ForegroundColor Red
        Write-Host "A moderator must be a mailbox, mail user or mail contact." -ForegroundColor Yellow
        return
    }

    $ExistingModerators = @($Group.ModeratedBy)
    $AlreadyModerator = $false

    foreach ($ExistingModerator in $ExistingModerators) {
        try {
            $ExistingRecipient = Get-Recipient -Identity $ExistingModerator -ErrorAction Stop

            if (
                $ExistingRecipient.Identity -eq $Recipient.Identity -or
                $ExistingRecipient.DistinguishedName -eq $Recipient.DistinguishedName -or
                $ExistingRecipient.Alias -eq $Recipient.Alias -or
                (
                    -not [string]::IsNullOrWhiteSpace([string]$ExistingRecipient.PrimarySmtpAddress) -and
                    $ExistingRecipient.PrimarySmtpAddress -eq $Recipient.PrimarySmtpAddress
                )
            ) {
                $AlreadyModerator = $true
                break
            }
        }
        catch {
            if ([string]$ExistingModerator -eq [string]$Recipient.Identity) {
                $AlreadyModerator = $true
                break
            }
        }
    }

    if ($AlreadyModerator) {
        Write-Host "`nThis recipient is already a moderator of the distribution group." -ForegroundColor Yellow
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Add Distribution Group Moderator       |" -ForegroundColor Cyan
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

    Write-Host "`nGROUP" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Group.DisplayName)
    Write-Host ("Alias        : {0}" -f $Group.Alias)
    Write-Host ("Primary SMTP : {0}" -f $Group.PrimarySmtpAddress)

    Write-Host "`nMODERATOR" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Recipient.DisplayName)
    Write-Host ("Alias        : {0}" -f $Recipient.Alias)
    Write-Host ("SMTP         : {0}" -f $Recipient.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $Recipient.RecipientTypeDetails)

    $Confirmation = Read-Host "`nType YES to add this moderator"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nAdding moderator..." -ForegroundColor Yellow

        Set-DistributionGroup `
            -Identity $Group.Identity `
            -ModeratedBy @{
                Add = $Recipient.Identity
            } `
            -ErrorAction Stop

        Write-Host "`nModerator added successfully." -ForegroundColor Green
        Write-Host ("Group     : {0}" -f $Group.DisplayName)
        Write-Host ("Moderator : {0}" -f $Recipient.DisplayName)
    }
    catch {
        Write-Host "`nFailed to add moderator." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}