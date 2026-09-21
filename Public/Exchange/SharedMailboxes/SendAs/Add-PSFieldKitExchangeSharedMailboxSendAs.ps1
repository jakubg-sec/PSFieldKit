function Add-PSFieldKitExchangeSharedMailboxSendAs {
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
    Write-Host "|      Add Shared Mailbox Send As              |" -ForegroundColor Cyan
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

    $TrusteeIdentity = Read-Host "Enter user or group to grant Send As"

    if ([string]::IsNullOrWhiteSpace($TrusteeIdentity)) {
        Write-Host ""
        Write-Host "User or group identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Trustee = Get-Recipient -Identity $TrusteeIdentity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to find the specified user or group." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Recipient selected:" -ForegroundColor Cyan
    Write-Host "  Name : $($Trustee.DisplayName)"
    Write-Host "  Type : $($Trustee.RecipientTypeDetails)"
    Write-Host "  SMTP : $($Trustee.PrimarySmtpAddress)"
    Write-Host ""

    if (
        $Trustee.PSObject.Properties.Name -contains "DistinguishedName" -and
        $Mailbox.PSObject.Properties.Name -contains "DistinguishedName" -and
        [string]$Trustee.DistinguishedName -eq [string]$Mailbox.DistinguishedName
    ) {
        Write-Host "A shared mailbox cannot be granted Send As permission to itself." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $ExistingPermission = @(
            Get-ADPermission -Identity $Mailbox.DistinguishedName -User $Trustee.DistinguishedName -ErrorAction Stop |
                Where-Object {
                    $_.ExtendedRights -contains "Send As" -and
                    -not $_.Deny -and
                    -not $_.IsInherited
                }
        )
    }
    catch {
        Write-Host ""
        Write-Host "Failed to check existing Send As permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($ExistingPermission.Count -gt 0) {
        Write-Host ""
        Write-Host "The recipient already has Send As permission." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Recipient: $($Trustee.DisplayName)" -ForegroundColor Cyan
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Send As permission will be granted with the following configuration:" -ForegroundColor Cyan
    Write-Host "  Shared Mailbox : $($Mailbox.DisplayName)"
    Write-Host "  Trustee        : $($Trustee.DisplayName)"
    Write-Host ""

    $Confirmation = Read-Host "Type ADD SEND AS to continue"

    if ($Confirmation -cne "ADD SEND AS") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $PermissionParameters = @{
            Identity       = $Mailbox.DistinguishedName
            User           = $Trustee.DistinguishedName
            AccessRights   = "ExtendedRight"
            ExtendedRights = "Send As"
            Confirm        = $false
            ErrorAction    = "Stop"
        }

        Add-ADPermission @PermissionParameters | Out-Null

        Write-Host ""
        Write-Host "Send As permission granted successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Mailbox : $($Mailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "Trustee : $($Trustee.DisplayName)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to grant Send As permission." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}