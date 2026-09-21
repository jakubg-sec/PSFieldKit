function Remove-PSFieldKitExchangeSharedMailboxFullAccess {
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
    Write-Host "|     Remove Shared Mailbox Full Access        |" -ForegroundColor Cyan
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

    $UserIdentity = Read-Host "Enter user or group"

    if ([string]::IsNullOrWhiteSpace($UserIdentity)) {
        Write-Host ""
        Write-Host "User or group identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Recipient = Get-Recipient -Identity $UserIdentity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to find the specified user or group." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Permissions = @(
            Get-MailboxPermission -Identity $Mailbox.Identity -ErrorAction Stop |
                Where-Object {
                    $_.AccessRights -contains "FullAccess" -and
                    -not $_.Deny -and
                    -not $_.IsInherited -and
                    [string]$_.User -ne "NT AUTHORITY\SELF"
                }
        )
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve mailbox permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $Permission = $Permissions |
        Where-Object {
            [string]$_.User -eq [string]$Recipient.Identity
        } |
        Select-Object -First 1

    if ($null -eq $Permission) {
        $Permission = $Permissions |
            Where-Object {
                [string]$_.User -eq [string]$Recipient.PrimarySmtpAddress
            } |
            Select-Object -First 1
    }

    if ($null -eq $Permission) {
        Write-Host ""
        Write-Host "The recipient does not have explicit Full Access to this shared mailbox." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Recipient: $($Recipient.DisplayName)" -ForegroundColor Cyan
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Full Access permission found:" -ForegroundColor Cyan
    Write-Host "  Mailbox   : $($Mailbox.DisplayName)"
    Write-Host "  Recipient : $($Recipient.DisplayName)"
    Write-Host "  User      : $($Permission.User)"
    Write-Host "  Access    : $($Permission.AccessRights -join ', ')"
    Write-Host ""

    Write-Host "WARNING: This will remove Full Access from the selected recipient." -ForegroundColor Yellow
    Write-Host "The recipient will no longer have access to the shared mailbox through this permission." -ForegroundColor Yellow
    Write-Host ""

    $Confirmation = Read-Host "Type REMOVE FULL ACCESS to continue"

    if ($Confirmation -cne "REMOVE FULL ACCESS") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $PermissionParameters = @{
            Identity    = $Mailbox.Identity
            User        = $Recipient.Identity
            AccessRights = "FullAccess"
            Confirm     = $false
            ErrorAction = "Stop"
        }

        Remove-MailboxPermission @PermissionParameters | Out-Null

        Write-Host ""
        Write-Host "Full Access removed successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Mailbox   : $($Mailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "Recipient : $($Recipient.DisplayName)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to remove Full Access." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}