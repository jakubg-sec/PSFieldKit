function Set-PSFieldKitExchangeMailboxAutomaticReply {
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
    Write-Host "|              Automatic Replies               |" -ForegroundColor Cyan
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

    try {
        $AutomaticReply = Get-MailboxAutoReplyConfiguration -Identity $Mailbox.Identity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve current automatic reply configuration." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Mailbox selected:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host ""

    Write-Host "Current automatic reply configuration:" -ForegroundColor Cyan
    Write-Host "  State           : $($AutomaticReply.AutoReplyState)"
    Write-Host "  External Audience: $($AutomaticReply.ExternalAudience)"

    if ($AutomaticReply.StartTime) {
        Write-Host "  Start Time      : $($AutomaticReply.StartTime)"
    }

    if ($AutomaticReply.EndTime) {
        Write-Host "  End Time        : $($AutomaticReply.EndTime)"
    }

    Write-Host ""

    Write-Host "Select automatic reply mode:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Enable immediately"
    Write-Host "  [2] Schedule automatic reply"
    Write-Host "  [3] Disable automatic reply"
    Write-Host "  [0] Back"
    Write-Host ""

    $Mode = Read-Host "Select option"

    switch ($Mode) {
        "1" {
            $AutoReplyState = "Enabled"
        }

        "2" {
            $AutoReplyState = "Scheduled"
        }

        "3" {
            $AutoReplyState = "Disabled"
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

    if ($AutoReplyState -eq "Disabled") {
        Write-Host ""
        Write-Host "Automatic replies will be disabled for this mailbox." -ForegroundColor Yellow
        Write-Host ""

        $Confirmation = Read-Host "Type DISABLE to continue"

        if ($Confirmation -cne "DISABLE") {
            Write-Host ""
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }

        try {
            $Parameters = @{
                Identity      = $Mailbox.Identity
                AutoReplyState = "Disabled"
                ErrorAction   = "Stop"
            }

            Set-MailboxAutoReplyConfiguration @Parameters

            Write-Host ""
            Write-Host "Automatic replies disabled successfully." -ForegroundColor Green
        }
        catch {
            Write-Host ""
            Write-Host "Failed to disable automatic replies." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }

        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Internal automatic reply message:" -ForegroundColor Cyan
    Write-Host "Enter the message that will be sent to internal senders."
    Write-Host "HTML can also be used if required."
    Write-Host ""

    $InternalMessage = Read-Host "Internal message"

    if ([string]::IsNullOrWhiteSpace($InternalMessage)) {
        Write-Host ""
        Write-Host "Internal message cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "External audience:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] None"
    Write-Host "  [2] Known senders"
    Write-Host "  [3] All external senders"
    Write-Host ""

    $ExternalAudienceChoice = Read-Host "Select option"

    switch ($ExternalAudienceChoice) {
        "1" {
            $ExternalAudience = "None"
        }

        "2" {
            $ExternalAudience = "Known"
        }

        "3" {
            $ExternalAudience = "All"
        }

        default {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    $ExternalMessage = $null

    if ($ExternalAudience -ne "None") {
        Write-Host ""
        Write-Host "External automatic reply message:" -ForegroundColor Cyan
        Write-Host "Enter the message that will be sent to external senders."
        Write-Host "HTML can also be used if required."
        Write-Host ""

        $ExternalMessage = Read-Host "External message"

        if ([string]::IsNullOrWhiteSpace($ExternalMessage)) {
            Write-Host ""
            Write-Host "External message cannot be empty when external replies are enabled." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    $StartTime = $null
    $EndTime = $null

    if ($AutoReplyState -eq "Scheduled") {
        Write-Host ""
        Write-Host "Schedule configuration:" -ForegroundColor Cyan
        Write-Host "Enter date and time, for example: 09/20/2026 18:00"
        Write-Host ""

        $StartTimeInput = Read-Host "Start time"
        $EndTimeInput = Read-Host "End time"

        $StartTimeParsed = [datetime]::MinValue
        $EndTimeParsed = [datetime]::MinValue

        if (-not [datetime]::TryParse($StartTimeInput, [ref]$StartTimeParsed)) {
            Write-Host ""
            Write-Host "Invalid start time." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if (-not [datetime]::TryParse($EndTimeInput, [ref]$EndTimeParsed)) {
            Write-Host ""
            Write-Host "Invalid end time." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if ($EndTimeParsed -le $StartTimeParsed) {
            Write-Host ""
            Write-Host "End time must be later than start time." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $StartTime = $StartTimeParsed
        $EndTime = $EndTimeParsed
    }

    Write-Host ""
    Write-Host "New automatic reply configuration:" -ForegroundColor Cyan
    Write-Host "  Mailbox          : $($Mailbox.DisplayName)"
    Write-Host "  State            : $AutoReplyState"
    Write-Host "  External Audience: $ExternalAudience"

    if ($StartTime) {
        Write-Host "  Start Time       : $StartTime"
        Write-Host "  End Time         : $EndTime"
    }

    Write-Host ""
    Write-Host "Internal message:" -ForegroundColor DarkGray
    Write-Host $InternalMessage

    if ($ExternalAudience -ne "None") {
        Write-Host ""
        Write-Host "External message:" -ForegroundColor DarkGray
        Write-Host $ExternalMessage
    }

    Write-Host ""

    $Confirmation = Read-Host "Type SET REPLY to continue"

    if ($Confirmation -cne "SET REPLY") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $Parameters = @{
            Identity         = $Mailbox.Identity
            AutoReplyState   = $AutoReplyState
            InternalMessage  = $InternalMessage
            ExternalAudience = $ExternalAudience
            ExternalMessage  = $ExternalMessage
            Confirm          = $false
            ErrorAction      = "Stop"
        }

        if ($AutoReplyState -eq "Scheduled") {
            $Parameters["StartTime"] = $StartTime
            $Parameters["EndTime"] = $EndTime
        }

        Set-MailboxAutoReplyConfiguration @Parameters

        Write-Host ""
        Write-Host "Automatic reply configuration updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "Failed to update automatic reply configuration." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}