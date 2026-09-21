function Add-PSFieldKitExchangeSharedMailboxEmailAddress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    $ServerName = "Unknown"

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
        -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
    ) {
        $ServerName = [string]$ExchangeContext.ServerName
    }

    if ($ServerName.Length -gt 35) {
        $ServerName = $ServerName.Substring(0, 32) + "..."
    }

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|    Add Shared Mailbox Email Address          |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $MailboxIdentity = Read-Host "Enter shared mailbox identity"

    if ([string]::IsNullOrWhiteSpace($MailboxIdentity)) {
        Write-Host ""
        Write-Host "Mailbox identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to find mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($Mailbox.RecipientTypeDetails -ne "SharedMailbox") {
        Write-Host ""
        Write-Host "The selected mailbox is not a shared mailbox." -ForegroundColor Red
        Write-Host "Current type: $($Mailbox.RecipientTypeDetails)" -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Shared mailbox selected:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Alias        : $($Mailbox.Alias)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host "  Policy Enabled: $($Mailbox.EmailAddressPolicyEnabled)"
    Write-Host ""

    $EmailAddress = Read-Host "Enter new SMTP email address"

    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        Write-Host ""
        Write-Host "Email address cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $EmailAddress = $EmailAddress.Trim()

    if ($EmailAddress -match "^(?i)smtp:") {
        $EmailAddress = $EmailAddress.Substring(5)
    }

    if ($EmailAddress -notmatch '^[^@\s]+@[^@\s]+$') {
        Write-Host ""
        Write-Host "Invalid SMTP email address format." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $NormalizedEmailAddress = $EmailAddress.ToLowerInvariant()

    foreach ($ExistingAddress in @($Mailbox.EmailAddresses)) {
        $ExistingAddressString = [string]$ExistingAddress

        if ($ExistingAddressString -match "^[^:]+:(.+)$") {
            $ExistingAddressValue = $Matches[1]
        }
        else {
            $ExistingAddressValue = $ExistingAddressString
        }

        if ($ExistingAddressValue.ToLowerInvariant() -eq $NormalizedEmailAddress) {
            Write-Host ""
            Write-Host "This email address is already assigned to the shared mailbox." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    try {
        $ExistingRecipient = Get-Recipient -Identity $EmailAddress -ErrorAction SilentlyContinue
    }
    catch {
        $ExistingRecipient = $null
    }

    if ($null -ne $ExistingRecipient) {
        Write-Host ""
        Write-Host "The email address is already assigned to another recipient." -ForegroundColor Red
        Write-Host ""
        Write-Host "Recipient : $($ExistingRecipient.DisplayName)" -ForegroundColor Yellow
        Write-Host "Type      : $($ExistingRecipient.RecipientTypeDetails)" -ForegroundColor Yellow
        Write-Host "Address   : $($ExistingRecipient.PrimarySmtpAddress)" -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "New SMTP address:" -ForegroundColor Cyan
    Write-Host "  Shared Mailbox : $($Mailbox.DisplayName)"
    Write-Host "  SMTP Address   : $EmailAddress"
    Write-Host "  Address Type   : Secondary SMTP"
    Write-Host ""

    if ($Mailbox.EmailAddressPolicyEnabled) {
        Write-Host "WARNING: Email Address Policy is enabled for this mailbox." -ForegroundColor Yellow
        Write-Host "The policy may affect manually configured addresses when it is applied." -ForegroundColor Yellow
        Write-Host ""
    }

    $Confirmation = Read-Host "Type ADD ADDRESS to continue"

    if ($Confirmation -cne "ADD ADDRESS") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $EmailAddressParameters = @{
            Identity      = $Mailbox.Identity
            EmailAddresses = @{
                Add = "smtp:$EmailAddress"
            }
            Confirm       = $false
            ErrorAction   = "Stop"
        }

        Set-Mailbox @EmailAddressParameters

        Write-Host ""
        Write-Host "Email address added successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Shared Mailbox : $($Mailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "SMTP Address   : $EmailAddress" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to add email address." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}