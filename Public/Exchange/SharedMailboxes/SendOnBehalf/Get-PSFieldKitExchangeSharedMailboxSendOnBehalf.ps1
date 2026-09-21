function Get-PSFieldKitExchangeSharedMailboxSendOnBehalf {
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
    Write-Host "|      Shared Mailbox - Send on Behalf         |" -ForegroundColor Cyan
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

    $Delegates = @($Mailbox.GrantSendOnBehalfTo)

    Write-Host ""
    Write-Host "Shared mailbox:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Alias        : $($Mailbox.Alias)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host ""

    if ($Delegates.Count -eq 0) {
        Write-Host "No Send on Behalf permissions were found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $DelegateList = @()

    foreach ($Delegate in $Delegates) {
        try {
            $Recipient = Get-Recipient -Identity $Delegate -ErrorAction Stop

            $DelegateList += [PSCustomObject]@{
                Name  = $Recipient.DisplayName
                Type  = $Recipient.RecipientTypeDetails
                SMTP  = $Recipient.PrimarySmtpAddress
                Identity = $Recipient.Identity
            }
        }
        catch {
            $DelegateList += [PSCustomObject]@{
                Name  = [string]$Delegate
                Type  = "Unknown"
                SMTP  = ""
                Identity = [string]$Delegate
            }
        }
    }

    Write-Host "SEND ON BEHALF PERMISSIONS" -ForegroundColor DarkCyan
    Write-Host ""

    $DelegateList |
        Sort-Object Name |
        Select-Object Name, Type, SMTP, Identity |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "Showing delegates configured in GrantSendOnBehalfTo." -ForegroundColor DarkGray
    Read-Host "`nPress Enter to continue" | Out-Null
}