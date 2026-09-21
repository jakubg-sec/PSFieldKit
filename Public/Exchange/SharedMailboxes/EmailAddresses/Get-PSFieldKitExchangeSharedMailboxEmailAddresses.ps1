function Get-PSFieldKitExchangeSharedMailboxEmailAddresses {
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
    Write-Host "|     Shared Mailbox - Email Addresses        |" -ForegroundColor Cyan
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

    $EmailAddresses = @($Mailbox.EmailAddresses)

    Write-Host ""
    Write-Host "Shared mailbox:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Alias        : $($Mailbox.Alias)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host ""

    if ($EmailAddresses.Count -eq 0) {
        Write-Host "No email addresses were found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $AddressList = foreach ($Address in $EmailAddresses) {
        $AddressString = [string]$Address

        $AddressType = "Other"
        $AddressValue = $AddressString
        $IsPrimary = $false

        if ($AddressString -match "^SMTP:(.+)$") {
            $AddressType = "SMTP"
            $AddressValue = $Matches[1]
            $IsPrimary = $true
        }
        elseif ($AddressString -match "^smtp:(.+)$") {
            $AddressType = "SMTP"
            $AddressValue = $Matches[1]
        }
        elseif ($AddressString -match "^X500:(.+)$") {
            $AddressType = "X500"
            $AddressValue = $Matches[1]
        }
        elseif ($AddressString -match "^SIP:(.+)$") {
            $AddressType = "SIP"
            $AddressValue = $Matches[1]
        }
        elseif ($AddressString -match "^x400:(.+)$") {
            $AddressType = "X400"
            $AddressValue = $Matches[1]
        }
        elseif ($AddressString -match "^EUM:(.+)$") {
            $AddressType = "EUM"
            $AddressValue = $Matches[1]
        }

        [PSCustomObject]@{
            Type    = $AddressType
            Address = $AddressValue
            Primary = if ($IsPrimary) { "Yes" } else { "" }
        }
    }

    Write-Host "EMAIL ADDRESSES" -ForegroundColor DarkCyan
    Write-Host ""

    $AddressList |
        Sort-Object @{
            Expression = {
                if ($_.Primary -eq "Yes") {
                    0
                }
                else {
                    1
                }
            }
        }, Type, Address |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "Primary SMTP address: $($Mailbox.PrimarySmtpAddress)" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to continue" | Out-Null
}