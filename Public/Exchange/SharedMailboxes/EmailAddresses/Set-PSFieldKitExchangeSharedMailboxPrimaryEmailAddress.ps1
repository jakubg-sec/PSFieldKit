function Set-PSFieldKitExchangeSharedMailboxPrimaryEmailAddress {
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
    Write-Host "| Shared Mailbox - Primary Email Address       |" -ForegroundColor Cyan
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
    Write-Host "  Current SMTP  : $($Mailbox.PrimarySmtpAddress)"
    Write-Host "  Policy Enabled: $($Mailbox.EmailAddressPolicyEnabled)"
    Write-Host ""

    $NewPrimarySmtpAddress = Read-Host "Enter new primary SMTP address"

    if ([string]::IsNullOrWhiteSpace($NewPrimarySmtpAddress)) {
        Write-Host ""
        Write-Host "Primary SMTP address cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $NewPrimarySmtpAddress = $NewPrimarySmtpAddress.Trim()

    if ($NewPrimarySmtpAddress -match '^(?i)smtp:') {
        $NewPrimarySmtpAddress = $NewPrimarySmtpAddress.Substring(5)
    }

    if ($NewPrimarySmtpAddress -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
        Write-Host ""
        Write-Host "The specified SMTP address is not valid." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $CurrentPrimarySmtpAddress = [string]$Mailbox.PrimarySmtpAddress

    if ($CurrentPrimarySmtpAddress.Equals($NewPrimarySmtpAddress, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host ""
        Write-Host "The specified address is already the primary SMTP address." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Primary SMTP : $CurrentPrimarySmtpAddress" -ForegroundColor Cyan
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $ExistingMailboxAddress = $null
    $ExistingMailboxAddressIsPrimary = $false

    foreach ($EmailAddress in @($Mailbox.EmailAddresses)) {
        $EmailAddressString = [string]$EmailAddress

        if ($EmailAddressString -match '^(?i)smtp:(.+)$') {
            $AddressPart = $Matches[1]

            if ($AddressPart.Equals($NewPrimarySmtpAddress, [System.StringComparison]::OrdinalIgnoreCase)) {
                $ExistingMailboxAddress = $EmailAddressString

                if ($EmailAddressString.StartsWith("SMTP:", [System.StringComparison]::Ordinal)) {
                    $ExistingMailboxAddressIsPrimary = $true
                }

                break
            }
        }
    }

    if ($ExistingMailboxAddressIsPrimary) {
        Write-Host ""
        Write-Host "The specified address is already the primary SMTP address." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $AddressOwner = $null

    try {
        $AddressOwner = Get-Recipient -Identity $NewPrimarySmtpAddress -ErrorAction SilentlyContinue
    }
    catch {
        $AddressOwner = $null
    }

    if ($null -ne $AddressOwner) {
        $SameMailbox = (
            $AddressOwner.PSObject.Properties.Name -contains "DistinguishedName" -and
            [string]$AddressOwner.DistinguishedName -eq [string]$Mailbox.DistinguishedName
        )

        if (-not $SameMailbox) {
            Write-Host ""
            Write-Host "The specified SMTP address is already assigned to another recipient." -ForegroundColor Red
            Write-Host ""
            Write-Host "Address : $NewPrimarySmtpAddress" -ForegroundColor Yellow
            Write-Host "Owner   : $($AddressOwner.DisplayName)" -ForegroundColor Yellow
            Write-Host "Type    : $($AddressOwner.RecipientTypeDetails)" -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }
    elseif ($null -eq $ExistingMailboxAddress) {
        Write-Host ""
        Write-Host "The specified SMTP address could not be confirmed as an existing mailbox address." -ForegroundColor Yellow
        Write-Host "The address will be added as the new primary SMTP address." -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "Primary SMTP address change:" -ForegroundColor Cyan
    Write-Host "  Current : $CurrentPrimarySmtpAddress"
    Write-Host "  New     : $NewPrimarySmtpAddress"
    Write-Host ""

    if ($ExistingMailboxAddress) {
        if ($ExistingMailboxAddress -ieq "smtp:$NewPrimarySmtpAddress") {
            Write-Host "The new address is already assigned to this mailbox as a secondary SMTP address." -ForegroundColor Green
        }
        else {
            Write-Host "The new address is already assigned to this mailbox." -ForegroundColor Green
        }

        Write-Host "It will be promoted to the primary SMTP address." -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "The new address is not currently assigned to this mailbox." -ForegroundColor Cyan
        Write-Host "It will be added as the new primary SMTP address." -ForegroundColor Cyan
        Write-Host ""
    }

    $PolicyWasEnabled = $false

    if (
        $Mailbox.PSObject.Properties.Name -contains "EmailAddressPolicyEnabled" -and
        $Mailbox.EmailAddressPolicyEnabled
    ) {
        $PolicyWasEnabled = $true

        Write-Host "WARNING: Email Address Policy is currently enabled." -ForegroundColor Yellow
        Write-Host "The policy must be disabled before the primary SMTP address can be changed manually." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "After this operation, the mailbox will no longer receive automatic" -ForegroundColor Yellow
        Write-Host "email address changes from the organization email address policy." -ForegroundColor Yellow
        Write-Host ""
    }

    $Confirmation = Read-Host "Type SET PRIMARY to continue"

    if ($Confirmation -cne "SET PRIMARY") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    $PolicyDisabledByFunction = $false

    try {
        if ($PolicyWasEnabled) {
            Write-Host ""
            Write-Host "Disabling Email Address Policy..." -ForegroundColor Cyan

            $PolicyParameters = @{
                Identity                 = $Mailbox.DistinguishedName
                EmailAddressPolicyEnabled = $false
                ErrorAction              = "Stop"
            }

            Set-Mailbox @PolicyParameters

            $PolicyDisabledByFunction = $true

            $Mailbox = Get-Mailbox -Identity $Mailbox.DistinguishedName -ErrorAction Stop

            if ($Mailbox.EmailAddressPolicyEnabled) {
                throw "Email Address Policy is still enabled after attempting to disable it."
            }

            Write-Host "Email Address Policy disabled." -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Setting primary SMTP address..." -ForegroundColor Cyan

        $PrimaryParameters = @{
            Identity          = $Mailbox.DistinguishedName
            PrimarySmtpAddress = $NewPrimarySmtpAddress
            ErrorAction       = "Stop"
        }

        Set-Mailbox @PrimaryParameters

        $UpdatedMailbox = Get-Mailbox -Identity $Mailbox.DistinguishedName -ErrorAction Stop

        $UpdatedPrimarySmtpAddress = [string]$UpdatedMailbox.PrimarySmtpAddress

        if (
            -not $UpdatedPrimarySmtpAddress.Equals(
                $NewPrimarySmtpAddress,
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {
            throw "Exchange did not set the requested primary SMTP address. Current primary SMTP address is '$UpdatedPrimarySmtpAddress'."
        }

        Write-Host ""
        Write-Host "Primary SMTP address updated successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Shared Mailbox : $($UpdatedMailbox.DisplayName)" -ForegroundColor Cyan
        Write-Host "Primary SMTP   : $($UpdatedMailbox.PrimarySmtpAddress)" -ForegroundColor Cyan
        Write-Host "Policy Enabled : $($UpdatedMailbox.EmailAddressPolicyEnabled)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to update the primary SMTP address." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        if ($PolicyDisabledByFunction) {
            try {
                $RollbackParameters = @{
                    Identity                 = $Mailbox.DistinguishedName
                    EmailAddressPolicyEnabled = $true
                    ErrorAction              = "Stop"
                }

                Set-Mailbox @RollbackParameters

                Write-Host ""
                Write-Host "Email Address Policy has been restored to its previous state." -ForegroundColor Yellow
            }
            catch {
                Write-Host ""
                Write-Host "WARNING: The primary SMTP address change failed and Email Address Policy could not be restored." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}