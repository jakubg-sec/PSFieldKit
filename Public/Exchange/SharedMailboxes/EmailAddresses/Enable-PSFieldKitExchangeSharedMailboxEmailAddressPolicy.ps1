function Enable-PSFieldKitExchangeSharedMailboxEmailAddressPolicy {
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
    Write-Host "| Shared Mailbox - Email Address Policy        |" -ForegroundColor Cyan
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
    Write-Host "  Name          : $($Mailbox.DisplayName)"
    Write-Host "  Alias         : $($Mailbox.Alias)"
    Write-Host "  Primary SMTP  : $($Mailbox.PrimarySmtpAddress)"
    Write-Host "  Policy Enabled: $($Mailbox.EmailAddressPolicyEnabled)"
    Write-Host ""

    if ($Mailbox.EmailAddressPolicyEnabled) {
        Write-Host "Email Address Policy is already enabled for this mailbox." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "WARNING: Enabling the Email Address Policy allows the organization" -ForegroundColor Yellow
    Write-Host "email address policies to manage addresses for this mailbox." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manually configured email addresses may be affected when the policy" -ForegroundColor Yellow
    Write-Host "is applied or updated." -ForegroundColor Yellow
    Write-Host ""

    $Confirmation = Read-Host "Type ENABLE POLICY to continue"

    if ($Confirmation -cne "ENABLE POLICY") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $PolicyParameters = @{
            Identity                 = $Mailbox.Identity
            EmailAddressPolicyEnabled = $true
            Confirm                  = $false
            ErrorAction              = "Stop"
        }

        Set-Mailbox @PolicyParameters

        $UpdatedMailbox = Get-Mailbox -Identity $Mailbox.Identity -ErrorAction Stop

        Write-Host ""
        Write-Host "Email Address Policy enabled successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Shared Mailbox : $($UpdatedMailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "Primary SMTP   : $($UpdatedMailbox.PrimarySmtpAddress)" -ForegroundColor Cyan
        Write-Host "Policy Enabled : $($UpdatedMailbox.EmailAddressPolicyEnabled)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to enable Email Address Policy." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}