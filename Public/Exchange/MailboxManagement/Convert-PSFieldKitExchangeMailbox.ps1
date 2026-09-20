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
    Write-Host "|                Convert Mailbox               |" -ForegroundColor Cyan
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

        $CurrentType = [string]$Mailbox.RecipientTypeDetails

        Write-Host ""
        Write-Host "Mailbox selected:" -ForegroundColor Cyan
        Write-Host "  Name         : $($Mailbox.DisplayName)"
        Write-Host "  Alias        : $($Mailbox.Alias)"
        Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
        Write-Host "  Current Type : $CurrentType"
        Write-Host ""

        Write-Host "Select target mailbox type:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Regular"
        Write-Host "  [2] Shared"
        Write-Host "  [3] Room"
        Write-Host "  [4] Equipment"
        Write-Host ""
        Write-Host "  [0] Back"

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                $TargetType = "Regular"
            }

            "2" {
                $TargetType = "Shared"
            }

            "3" {
                $TargetType = "Room"
            }

            "4" {
                $TargetType = "Equipment"
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

        $CurrentTypeMap = @{
            "UserMailbox"       = "Regular"
            "SharedMailbox"     = "Shared"
            "RoomMailbox"       = "Room"
            "EquipmentMailbox"  = "Equipment"
        }

        $CurrentMailboxType = $CurrentTypeMap[$CurrentType]

        if ($CurrentMailboxType -eq $TargetType) {
            Write-Host ""
            Write-Host "The mailbox is already configured as $TargetType." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""
        Write-Host "Conversion:" -ForegroundColor Cyan
        Write-Host "  Mailbox : $($Mailbox.DisplayName)"
        Write-Host "  Current : $($CurrentMailboxType ?? $CurrentType)"
        Write-Host "  Target  : $TargetType"
        Write-Host ""

        if ($TargetType -eq "Regular") {
            Write-Host "A password is required when converting to a regular mailbox." -ForegroundColor Yellow
            Write-Host ""

            $Password = Read-Host "Enter mailbox password" -AsSecureString

            $ResetPasswordInput = Read-Host "Require password change on next logon? (Y/N)"
            $ResetPasswordOnNextLogon = $false

            if ($ResetPasswordInput -match "^[Yy]$") {
                $ResetPasswordOnNextLogon = $true
            }

            Write-Host ""
            Write-Host "WARNING: The associated AD account will be used as a regular user account." -ForegroundColor Yellow
            Write-Host ""

            $Confirmation = Read-Host "Type CONVERT to continue"

            if ($Confirmation -cne "CONVERT") {
                Write-Host ""
                Write-Host "Mailbox conversion cancelled." -ForegroundColor Yellow
                return
            }

            $Parameters = @{
                Identity                = $Mailbox.Identity
                Type                    = "Regular"
                Password                = $Password
                ResetPasswordOnNextLogon = $ResetPasswordOnNextLogon
                ErrorAction             = "Stop"
            }

            Set-Mailbox @Parameters
        }
        else {
            Write-Host ""

            if ($TargetType -eq "Shared") {
                Write-Host "The mailbox will be converted to a shared mailbox." -ForegroundColor Yellow
                Write-Host "The associated AD account will be disabled." -ForegroundColor Yellow
            }
            elseif ($TargetType -eq "Room") {
                Write-Host "The mailbox will be converted to a room mailbox." -ForegroundColor Yellow
                Write-Host "The associated AD account will be disabled." -ForegroundColor Yellow
            }
            elseif ($TargetType -eq "Equipment") {
                Write-Host "The mailbox will be converted to an equipment mailbox." -ForegroundColor Yellow
                Write-Host "The associated AD account will be disabled." -ForegroundColor Yellow
            }

            Write-Host ""

            $Confirmation = Read-Host "Type CONVERT to continue"

            if ($Confirmation -cne "CONVERT") {
                Write-Host ""
                Write-Host "Mailbox conversion cancelled." -ForegroundColor Yellow
                return
            }

            $Parameters = @{
                Identity    = $Mailbox.Identity
                Type        = $TargetType
                ErrorAction = "Stop"
            }

            Set-Mailbox @Parameters
        }

        Write-Host ""
        Write-Host "Mailbox converted successfully." -ForegroundColor Green

        $UpdatedMailbox = Get-Mailbox -Identity $Mailbox.Identity -ErrorAction Stop

        Write-Host ""
        Write-Host "Mailbox information:" -ForegroundColor Cyan
        Write-Host "  Name         : $($UpdatedMailbox.DisplayName)"
        Write-Host "  Alias        : $($UpdatedMailbox.Alias)"
        Write-Host "  Primary SMTP : $($UpdatedMailbox.PrimarySmtpAddress)"
        Write-Host "  New Type     : $($UpdatedMailbox.RecipientTypeDetails)"
    }
    catch {
        Write-Host ""
        Write-Host "Failed to convert mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}