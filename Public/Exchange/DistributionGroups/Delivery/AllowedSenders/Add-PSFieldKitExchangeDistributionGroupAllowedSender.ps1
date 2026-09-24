function Add-PSFieldKitExchangeDistributionGroupAllowedSender {
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

    if ($Group.RecipientTypeDetails -eq 'DynamicDistributionGroup') {
        Write-Host "`nDynamic distribution groups do not support manually managed members." -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrWhiteSpace($Sndr)) {
        $Sndr = Read-Host "Enter allowed sender name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Sndr)) {
        Write-Host "`nSender identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Recipient = Get-Recipient -Identity $Sndr -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find recipient '$Sndr'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    $AllowedIndividualRecipients = @(
        'UserMailbox'
        'SharedMailbox'
        'RoomMailbox'
        'EquipmentMailbox'
        'MailUser'
        'MailContact'
    )

    $AllowedGroupRecipients = @(
        'MailUniversalDistributionGroup'
        'MailUniversalSecurityGroup'
        'DynamicDistributionGroup'
    )

    if (
        $AllowedIndividualRecipients -notcontains $Recipient.RecipientTypeDetails -and
        $AllowedGroupRecipients -notcontains $Recipient.RecipientTypeDetails
    ) {
        Write-Host "`nRecipient type '$($Recipient.RecipientTypeDetails)' cannot be used as an allowed sender." -ForegroundColor Red
        return
    }

    $ExistingAllowedSenders = @(
        $Group.AcceptMessagesOnlyFromSendersOrMembers
    )

    $AlreadyAllowed = $false

    foreach ($AllowedSender in $ExistingAllowedSenders) {
        try {
            $ExistingRecipient = Get-Recipient -Identity $AllowedSender -ErrorAction Stop

            if (
                $ExistingRecipient.Identity -eq $Recipient.Identity -or
                $ExistingRecipient.DistinguishedName -eq $Recipient.DistinguishedName -or
                $ExistingRecipient.PrimarySmtpAddress -eq $Recipient.PrimarySmtpAddress
            ) {
                $AlreadyAllowed = $true
                break
            }
        }
        catch {
            if ([string]$AllowedSender -eq [string]$Recipient.Identity) {
                $AlreadyAllowed = $true
                break
            }
        }
    }

    if ($AlreadyAllowed) {
        Write-Host "`nThis sender is already in the allowed senders list." -ForegroundColor Yellow
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Add Allowed Sender                  |" -ForegroundColor Cyan
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

    Write-Host "`nALLOWED SENDER" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Recipient.DisplayName)
    Write-Host ("Alias        : {0}" -f $Recipient.Alias)
    Write-Host ("SMTP         : {0}" -f $Recipient.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $Recipient.RecipientTypeDetails)

    if ($AllowedGroupRecipients -contains $Recipient.RecipientTypeDetails) {
        Write-Host "Sender class : Group" -ForegroundColor Cyan
    }
    else {
        Write-Host "Sender class : Individual" -ForegroundColor Cyan
    }

    $Confirmation = Read-Host "`nType YES to add this allowed sender"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nAdding allowed sender..." -ForegroundColor Yellow

        $Parameters = @{
            Identity = $Group.Identity
            ErrorAction = 'Stop'
        }

        if ($AllowedGroupRecipients -contains $Recipient.RecipientTypeDetails) {
            $Parameters.AcceptMessagesOnlyFromDLMembers = @{
                Add = $Recipient.Identity
            }
        }
        else {
            $Parameters.AcceptMessagesOnlyFrom = @{
                Add = $Recipient.Identity
            }
        }

        Set-DistributionGroup @Parameters

        Write-Host "`nAllowed sender added successfully." -ForegroundColor Green
        Write-Host ("Group  : {0}" -f $Group.DisplayName)
        Write-Host ("Sender : {0}" -f $Recipient.DisplayName)
    }
    catch {
        Write-Host "`nFailed to add allowed sender." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}