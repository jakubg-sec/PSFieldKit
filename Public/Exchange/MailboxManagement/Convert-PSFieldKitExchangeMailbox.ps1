function Convert-PSFieldKitExchangeMailbox {
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
    Write-Host "|               Convert Mailbox                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $MailboxIdentity = Read-Host "Enter mailbox identity"

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

    $CurrentType = [string]$Mailbox.RecipientTypeDetails
    $CurrentMailboxType = $null

    switch ($CurrentType) {
        "UserMailbox" {
            $CurrentMailboxType = "Regular"
        }
        "SharedMailbox" {
            $CurrentMailboxType = "Shared"
        }
        "RoomMailbox" {
            $CurrentMailboxType = "Room"
        }
        "EquipmentMailbox" {
            $CurrentMailboxType = "Equipment"
        }
        default {
            $CurrentMailboxType = $CurrentType
        }
    }

    $DisplayCurrentType = $CurrentType

    if (-not [string]::IsNullOrWhiteSpace($CurrentMailboxType)) {
        $DisplayCurrentType = $CurrentMailboxType
    }

    Write-Host ""
    Write-Host "Mailbox selected:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Alias        : $($Mailbox.Alias)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host "  Current Type : $DisplayCurrentType"
    Write-Host ""

    Write-Host "Select new mailbox type:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Regular"
    Write-Host "  [2] Shared"
    Write-Host "  [3] Room"
    Write-Host "  [4] Equipment"
    Write-Host "  [0] Back"
    Write-Host ""

    $Choice = Read-Host "Select option"

    $NewType = $null

    switch ($Choice) {
        "1" {
            $NewType = "Regular"
        }

        "2" {
            $NewType = "Shared"
        }

        "3" {
            $NewType = "Room"
        }

        "4" {
            $NewType = "Equipment"
        }

        "0" {
            return
        }

        default {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    if ($NewType -eq $CurrentMailboxType) {
        Write-Host ""
        Write-Host "The mailbox is already configured as $NewType." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Conversion:" -ForegroundColor Cyan
    Write-Host "  Current : $DisplayCurrentType"
    Write-Host "  Target  : $NewType"
    Write-Host ""

    $Password = $null
    $ResetPasswordOnNextLogon = $false

    if ($NewType -eq "Regular") {
        Write-Host "A Regular mailbox requires an AD account password." -ForegroundColor Yellow
        Write-Host ""

        $PasswordPlainText = Read-Host "Enter new password"

        if ([string]::IsNullOrWhiteSpace($PasswordPlainText)) {
            Write-Host ""
            Write-Host "Password cannot be empty." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $Password = ConvertTo-SecureString $PasswordPlainText -AsPlainText -Force

        Write-Host ""
        $ResetChoice = Read-Host "Require password change at next logon? (Y/N)"

        if ($ResetChoice -match "^(Y|y)$") {
            $ResetPasswordOnNextLogon = $true
        }
    }
    else {
        Write-Host "Converting this mailbox to $NewType may disable the associated AD account." -ForegroundColor Yellow
        Write-Host "Verify the resulting account state after the conversion." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "WARNING: Mailbox type conversion changes how the mailbox is treated by Exchange." -ForegroundColor Yellow
    Write-Host "Verify the target type before continuing." -ForegroundColor Yellow
    Write-Host ""

    $Confirmation = Read-Host "Type CONVERT to continue"

    if ($Confirmation -cne "CONVERT") {
        Write-Host ""
        Write-Host "Mailbox conversion cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $Parameters = @{
            Identity   = $Mailbox.Identity
            Type       = $NewType
            Confirm    = $false
            ErrorAction = "Stop"
        }

        if ($NewType -eq "Regular") {
            $Parameters["Password"] = $Password
            $Parameters["ResetPasswordOnNextLogon"] = $ResetPasswordOnNextLogon
        }

        Set-Mailbox @Parameters

        Write-Host ""
        Write-Host "Mailbox converted successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "New mailbox type: $NewType" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to convert mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}