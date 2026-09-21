function Add-PSFieldKitExchangeSharedMailboxSendOnBehalf {
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
    Write-Host "|      Add Shared Mailbox Send on Behalf       |" -ForegroundColor Cyan
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
    Write-Host ""

    $DelegateIdentity = Read-Host "Enter user or group to grant Send on Behalf"

    if ([string]::IsNullOrWhiteSpace($DelegateIdentity)) {
        Write-Host ""
        Write-Host "User or group identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Delegate = Get-Recipient -Identity $DelegateIdentity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to find the specified user or group." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $AllowedRecipientTypes = @(
        "UserMailbox"
        "SharedMailbox"
        "MailUser"
        "MailContact"
        "MailUniversalSecurityGroup"
        "MailUniversalDistributionGroup"
        "MailNonUniversalGroup"
        "GroupMailbox"
    )

    if ($AllowedRecipientTypes -notcontains [string]$Delegate.RecipientTypeDetails) {
        Write-Host ""
        Write-Host "The selected recipient cannot be used as a Send on Behalf delegate." -ForegroundColor Red
        Write-Host "Recipient type: $($Delegate.RecipientTypeDetails)" -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Delegate selected:" -ForegroundColor Cyan
    Write-Host "  Name : $($Delegate.DisplayName)"
    Write-Host "  Type : $($Delegate.RecipientTypeDetails)"
    Write-Host "  SMTP : $($Delegate.PrimarySmtpAddress)"
    Write-Host ""

    if (
        $Delegate.PSObject.Properties.Name -contains "DistinguishedName" -and
        $Mailbox.PSObject.Properties.Name -contains "DistinguishedName" -and
        [string]$Delegate.DistinguishedName -eq [string]$Mailbox.DistinguishedName
    ) {
        Write-Host "A shared mailbox cannot be configured as its own Send on Behalf delegate." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $ExistingDelegates = @($Mailbox.GrantSendOnBehalfTo)

    foreach ($ExistingDelegate in $ExistingDelegates) {
        try {
            $ExistingRecipient = Get-Recipient -Identity $ExistingDelegate -ErrorAction Stop

            if (
                [string]$ExistingRecipient.DistinguishedName -eq
                [string]$Delegate.DistinguishedName
            ) {
                Write-Host ""
                Write-Host "The selected recipient already has Send on Behalf permission." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Delegate: $($Delegate.DisplayName)" -ForegroundColor Cyan
                Read-Host "`nPress Enter to continue" | Out-Null
                return
            }
        }
        catch {
            if ([string]$ExistingDelegate -eq [string]$Delegate.Identity) {
                Write-Host ""
                Write-Host "The selected recipient already has Send on Behalf permission." -ForegroundColor Yellow
                Read-Host "`nPress Enter to continue" | Out-Null
                return
            }
        }
    }

    Write-Host "Send on Behalf permission will be granted with the following configuration:" -ForegroundColor Cyan
    Write-Host "  Shared Mailbox : $($Mailbox.DisplayName)"
    Write-Host "  Delegate       : $($Delegate.DisplayName)"
    Write-Host ""

    $Confirmation = Read-Host "Type ADD SEND ON BEHALF to continue"

    if ($Confirmation -cne "ADD SEND ON BEHALF") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $PermissionParameters = @{
            Identity         = $Mailbox.Identity
            GrantSendOnBehalfTo = @{
                Add = $Delegate.Identity
            }
            ErrorAction      = "Stop"
        }

        Set-Mailbox @PermissionParameters

        $UpdatedMailbox = Get-Mailbox -Identity $Mailbox.Identity -ErrorAction Stop

        Write-Host ""
        Write-Host "Send on Behalf permission granted successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Mailbox : $($UpdatedMailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "Delegate: $($Delegate.DisplayName)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to grant Send on Behalf permission." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}