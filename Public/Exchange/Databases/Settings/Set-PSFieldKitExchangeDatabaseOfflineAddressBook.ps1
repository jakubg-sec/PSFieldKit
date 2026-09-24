function Set-PSFieldKitExchangeDatabaseOfflineAddressBook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity,
        [Parameter()]
        [string]$OfflineAddressBook,
        [Parameter()]
        [switch]$WhatIf
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Set-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Set-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-OfflineAddressBook -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-OfflineAddressBook' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter mailbox database name or identity"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Database = Get-MailboxDatabase `
            -Identity $Identity `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $CurrentOAB = $null
    if (
        $Database.PSObject.Properties.Name -contains 'OfflineAddressBook' -and
        $null -ne $Database.OfflineAddressBook
    ) {
        $CurrentOAB = [string]$Database.OfflineAddressBook
    }

    if ([string]::IsNullOrWhiteSpace($OfflineAddressBook)) {
        Clear-Host
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|         Database Offline Address Book        |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
        Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nCURRENT SETTING" -ForegroundColor DarkCyan
        if ([string]::IsNullOrWhiteSpace($CurrentOAB)) {
            Write-Host "Offline Address Book : None (default OAB will be used)"
        }
        else {
            Write-Host "Offline Address Book : $CurrentOAB"
        }

        try {
            $OABs = @(
                Get-OfflineAddressBook |
                    Sort-Object Name
            )
        }
        catch {
            Write-Host "`nFailed to retrieve Offline Address Books." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($OABs.Count -eq 0) {
            Write-Host "`nNo Offline Address Books were found." -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        Write-Host "`nAVAILABLE OFFLINE ADDRESS BOOKS" -ForegroundColor DarkCyan
        Write-Host ""

        $Index = 1
        foreach ($OAB in $OABs) {
            $DefaultText = if ($OAB.IsDefault) { " [Default]" } else { "" }
            Write-Host ("[{0}] {1}{2}" -f $Index, $OAB.Name, $DefaultText)
            $Index++
        }

        Write-Host ""
        Write-Host "[0] Clear database OAB assignment"
        Write-Host "[Enter] Keep current value"

        $Choice = Read-Host "Select option"

        if ([string]::IsNullOrWhiteSpace($Choice)) {
            Write-Host "`nNo changes selected." -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($Choice -eq '0') {
            $OfflineAddressBook = $null
        }
        else {
            $SelectedIndex = 0
            if (-not [int]::TryParse($Choice, [ref]$SelectedIndex)) {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }

            if ($SelectedIndex -lt 1 -or $SelectedIndex -gt $OABs.Count) {
                Write-Host "`nInvalid Offline Address Book selection." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }

            $OfflineAddressBook = [string]$OABs[$SelectedIndex - 1].Identity
        }
    }
    else {
        try {
            $SelectedOAB = Get-OfflineAddressBook `
                -Identity $OfflineAddressBook `
                -ErrorAction Stop

            $OfflineAddressBook = [string]$SelectedOAB.Identity
        }
        catch {
            Write-Host "`nOffline Address Book '$OfflineAddressBook' was not found." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    $NewOABDisplay = if ([string]::IsNullOrWhiteSpace($OfflineAddressBook)) {
        "None (default OAB will be used)"
    }
    else {
        $OfflineAddressBook
    }

    $CurrentOABDisplay = if ([string]::IsNullOrWhiteSpace($CurrentOAB)) {
        "None (default OAB will be used)"
    }
    else {
        $CurrentOAB
    }

    if ($CurrentOABDisplay -eq $NewOABDisplay) {
        Write-Host "`nThe database already has this Offline Address Book assignment." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|         Database Offline Address Book        |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host "Current OAB : $CurrentOABDisplay"
    Write-Host "New OAB     : $NewOABDisplay"

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Apply this Offline Address Book assignment? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating Offline Address Book assignment..." -ForegroundColor Yellow

        $Parameters = @{
            Identity    = $Database.Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ([string]::IsNullOrWhiteSpace($OfflineAddressBook)) {
            $Parameters['OfflineAddressBook'] = $null
        }
        else {
            $Parameters['OfflineAddressBook'] = $OfflineAddressBook
        }

        if ($WhatIf) {
            $Parameters['WhatIf'] = $true
        }

        Set-MailboxDatabase @Parameters

        if ($WhatIf) {
            Write-Host "`nWhatIf completed. No changes were made." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "`nOffline Address Book assignment updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update Offline Address Book assignment." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -ErrorAction Stop

        $VerificationOAB = if (
            $Verification.PSObject.Properties.Name -contains 'OfflineAddressBook' -and
            $null -ne $Verification.OfflineAddressBook
        ) {
            [string]$Verification.OfflineAddressBook
        }
        else {
            "None (default OAB will be used)"
        }

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Offline Address Book : {0}" -f $VerificationOAB)

        if (
            [string]::IsNullOrWhiteSpace($OfflineAddressBook) -and
            [string]::IsNullOrWhiteSpace([string]$Verification.OfflineAddressBook)
        ) {
            Write-Host "`nOffline Address Book assignment was cleared successfully." -ForegroundColor Green
        }
        elseif (
            -not [string]::IsNullOrWhiteSpace($OfflineAddressBook) -and
            [string]$Verification.OfflineAddressBook -eq $OfflineAddressBook
        ) {
            Write-Host "`nOffline Address Book assignment was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned OAB does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nOffline Address Book was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}