function Add-PSFieldKitExchangeSharedMailboxFullAccess {
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
    Write-Host "|      Add Shared Mailbox Full Access          |" -ForegroundColor Cyan
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

    $UserIdentity = Read-Host "Enter user or group to grant Full Access"

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

    Write-Host ""
    Write-Host "Recipient selected:" -ForegroundColor Cyan
    Write-Host "  Name : $($Recipient.DisplayName)"
    Write-Host "  Type : $($Recipient.RecipientTypeDetails)"
    Write-Host "  SMTP : $($Recipient.PrimarySmtpAddress)"
    Write-Host ""

    if (
        [string]$Recipient.Identity -eq [string]$Mailbox.Identity -or
        [string]$Recipient.PrimarySmtpAddress -eq [string]$Mailbox.PrimarySmtpAddress
    ) {
        Write-Host "A shared mailbox cannot be granted Full Access to itself." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $ExistingPermission = @(
            Get-MailboxPermission -Identity $Mailbox.Identity -User $Recipient.Identity -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.AccessRights -contains "FullAccess" -and
                    -not $_.Deny
                }
        )
    }
    catch {
        $ExistingPermission = @()
    }

    if ($ExistingPermission.Count -gt 0) {
        Write-Host ""
        Write-Host "The recipient already has Full Access to this shared mailbox." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "Outlook automapping:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Enable AutoMapping"
    Write-Host "  [2] Disable AutoMapping"
    Write-Host ""

    $AutoMappingChoice = Read-Host "Select option"

    switch ($AutoMappingChoice) {
        "1" {
            $AutoMapping = $true
        }

        "2" {
            $AutoMapping = $false
        }

        default {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    Write-Host ""
    Write-Host "Full Access will be granted with the following configuration:" -ForegroundColor Cyan
    Write-Host "  Shared Mailbox : $($Mailbox.DisplayName)"
    Write-Host "  Recipient      : $($Recipient.DisplayName)"
    Write-Host "  AutoMapping    : $AutoMapping"
    Write-Host ""

    $Confirmation = Read-Host "Type ADD FULL ACCESS to continue"

    if ($Confirmation -cne "ADD FULL ACCESS") {
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

        if ($AutoMapping) {
            $PermissionParameters["AutoMapping"] = $true
        }
        else {
            $PermissionParameters["AutoMapping"] = $false
        }

        Add-MailboxPermission @PermissionParameters | Out-Null

        Write-Host ""
        Write-Host "Full Access granted successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Mailbox   : $($Mailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "Recipient : $($Recipient.DisplayName)" -ForegroundColor Cyan
        Write-Host "AutoMapping: $AutoMapping" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to grant Full Access." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}