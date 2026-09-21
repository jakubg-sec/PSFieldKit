function Remove-PSFieldKitExchangeSharedMailboxSendOnBehalf {
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
    Write-Host "|    Remove Shared Mailbox Send on Behalf      |" -ForegroundColor Cyan
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

    $DelegateIdentity = Read-Host "Enter user or group"

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

    Write-Host ""
    Write-Host "Delegate selected:" -ForegroundColor Cyan
    Write-Host "  Name : $($Delegate.DisplayName)"
    Write-Host "  Type : $($Delegate.RecipientTypeDetails)"
    Write-Host "  SMTP : $($Delegate.PrimarySmtpAddress)"
    Write-Host ""

    $ExistingDelegates = @($Mailbox.GrantSendOnBehalfTo)

    $MatchingDelegate = $null

    foreach ($ExistingDelegate in $ExistingDelegates) {
        try {
            $ExistingRecipient = Get-Recipient -Identity $ExistingDelegate -ErrorAction Stop

            if (
                [string]$ExistingRecipient.DistinguishedName -eq
                [string]$Delegate.DistinguishedName
            ) {
                $MatchingDelegate = $ExistingRecipient
                break
            }
        }
        catch {
            if ([string]$ExistingDelegate -eq [string]$Delegate.Identity) {
                $MatchingDelegate = $Delegate
                break
            }
        }
    }

    if ($null -eq $MatchingDelegate) {
        Write-Host ""
        Write-Host "The selected recipient does not have Send on Behalf permission." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Delegate: $($Delegate.DisplayName)" -ForegroundColor Cyan
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "Send on Behalf permission found:" -ForegroundColor Cyan
    Write-Host "  Mailbox  : $($Mailbox.DisplayName)"
    Write-Host "  Delegate : $($Delegate.DisplayName)"
    Write-Host ""

    Write-Host "WARNING: This will remove Send on Behalf permission from the selected delegate." -ForegroundColor Yellow
    Write-Host "The delegate will no longer be able to send messages on behalf of this shared mailbox." -ForegroundColor Yellow
    Write-Host ""

    $Confirmation = Read-Host "Type REMOVE SEND ON BEHALF to continue"

    if ($Confirmation -cne "REMOVE SEND ON BEHALF") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $PermissionParameters = @{
            Identity            = $Mailbox.Identity
            GrantSendOnBehalfTo = @{
                Remove = $Delegate.Identity
            }
            ErrorAction         = "Stop"
        }

        Set-Mailbox @PermissionParameters

        Write-Host ""
        Write-Host "Send on Behalf permission removed successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Mailbox  : $($Mailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "Delegate : $($Delegate.DisplayName)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to remove Send on Behalf permission." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}