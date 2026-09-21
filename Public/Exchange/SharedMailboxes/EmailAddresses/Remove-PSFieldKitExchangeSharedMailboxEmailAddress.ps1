function Remove-PSFieldKitExchangeSharedMailboxEmailAddress {
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
    Write-Host "|  Remove Shared Mailbox Email Address         |" -ForegroundColor Cyan
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

    $EmailAddresses = @(
        $Mailbox.EmailAddresses |
            ForEach-Object {
                [string]$_
            } |
            Where-Object {
                $_ -match "^smtp:" -or
                $_ -match "^SMTP:"
            }
    )

    if ($EmailAddresses.Count -eq 0) {
        Write-Host "No SMTP email addresses were found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $AddressList = @()

    foreach ($Address in $EmailAddresses) {
        $IsPrimary = $Address.StartsWith("SMTP:")
        $AddressValue = $Address.Substring(5)

        $AddressList += [PSCustomObject]@{
            Address = $AddressValue
            Primary = if ($IsPrimary) { "Yes" } else { "No" }
        }
    }

    Write-Host "Current SMTP addresses:" -ForegroundColor Cyan
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
        }, Address |
        Format-Table -AutoSize

    Write-Host ""

    $EmailAddress = Read-Host "Enter SMTP address to remove"

    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        Write-Host ""
        Write-Host "Email address cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $EmailAddress = $EmailAddress.Trim()

    if ($EmailAddress -match "^(?i)smtp:") {
        $EmailAddress = $EmailAddress.Substring(5)
    }

    $SelectedAddress = $AddressList |
        Where-Object {
            $_.Address -ieq $EmailAddress
        } |
        Select-Object -First 1

    if ($null -eq $SelectedAddress) {
        Write-Host ""
        Write-Host "The specified SMTP address is not assigned to this mailbox." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($SelectedAddress.Primary -eq "Yes") {
        Write-Host ""
        Write-Host "The primary SMTP address cannot be removed." -ForegroundColor Red
        Write-Host "Set another primary email address first." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Email address selected:" -ForegroundColor Cyan
    Write-Host "  Shared Mailbox : $($Mailbox.DisplayName)"
    Write-Host "  SMTP Address   : $($SelectedAddress.Address)"
    Write-Host "  Primary        : No"
    Write-Host ""

    $Confirmation = Read-Host "Type REMOVE ADDRESS to continue"

    if ($Confirmation -cne "REMOVE ADDRESS") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $EmailAddressParameters = @{
            Identity       = $Mailbox.Identity
            EmailAddresses = @{
                Remove = "smtp:$($SelectedAddress.Address)"
            }
            Confirm        = $false
            ErrorAction    = "Stop"
        }

        Set-Mailbox @EmailAddressParameters

        Write-Host ""
        Write-Host "Email address removed successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Shared Mailbox : $($Mailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "SMTP Address   : $($SelectedAddress.Address)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to remove email address." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}