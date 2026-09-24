function Remove-PSFieldKitExchangeDistributionGroupEmailAddress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$EmailAddress
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        return
    }

    if (-not (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        return
    }

    if (-not (Get-Command Set-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Set-DistributionGroup' is not available." -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter distribution group name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDistribution group identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Group = Get-DistributionGroup -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find distribution group '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    $EmailAddresses = @(
        $Group.EmailAddresses |
            ForEach-Object {
                $_.ToString()
            }
    )

    $SecondaryAddresses = @(
        $EmailAddresses |
            Where-Object {
                $_ -cmatch '^smtp:'
            }
    )

    if ($SecondaryAddresses.Count -eq 0) {
        Write-Host "`nNo secondary SMTP addresses are configured." -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|    Remove Distribution Group Email Address   |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        $DisplayName = [string]$Group.DisplayName

        if ([string]::IsNullOrWhiteSpace($DisplayName)) {
            $DisplayName = [string]$Group.Name
        }

        if ($DisplayName.Length -gt 36) {
            $DisplayName = $DisplayName.Substring(0, 33) + "..."
        }

        Write-Host ("|  Group : {0,-36}|" -f $DisplayName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nSECONDARY SMTP ADDRESSES" -ForegroundColor DarkCyan
        Write-Host ""

        $Index = 1

        foreach ($Address in $SecondaryAddresses) {
            $Value = $Address.Substring(5)
            Write-Host ("[{0}] {1}" -f $Index, $Value)
            $Index++
        }

        Write-Host ""

        $Choice = Read-Host "Select address to remove"

        if ($Choice -notmatch '^\d+$') {
            Write-Host "`nInvalid address selection." -ForegroundColor Red
            return
        }

        $AddressIndex = [int]$Choice

        if ($AddressIndex -lt 1 -or $AddressIndex -gt $SecondaryAddresses.Count) {
            Write-Host "`nInvalid address selection." -ForegroundColor Red
            return
        }

        $SelectedAddress = $SecondaryAddresses[$AddressIndex - 1]
        $EmailAddress = $SelectedAddress.Substring(5)
    }
    else {
        $EmailAddress = $EmailAddress.Trim()

        $SelectedAddress = $SecondaryAddresses |
            Where-Object {
                $_.Substring(5) -ieq $EmailAddress
            } |
            Select-Object -First 1

        if ($null -eq $SelectedAddress) {
            $PrimaryAddress = $EmailAddresses |
                Where-Object {
                    $_ -cmatch '^SMTP:' -and
                    $_.Substring(5) -ieq $EmailAddress
                } |
                Select-Object -First 1

            if ($null -ne $PrimaryAddress) {
                Write-Host "`nThe selected address is the primary SMTP address." -ForegroundColor Red
                Write-Host "Primary SMTP address cannot be removed with this function." -ForegroundColor Yellow
                return
            }

            Write-Host "`nThe specified secondary SMTP address was not found." -ForegroundColor Yellow
            return
        }

        $EmailAddress = $SelectedAddress.Substring(5)
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|    Remove Distribution Group Email Address   |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Group.DisplayName

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = [string]$Group.Name
    }

    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group : {0,-36}|" -f $DisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nEMAIL ADDRESS TO REMOVE" -ForegroundColor DarkCyan
    Write-Host ("Address : {0}" -f $EmailAddress) -ForegroundColor Yellow
    Write-Host "Type    : Secondary SMTP"

    $Confirmation = Read-Host "`nType YES to remove this email address"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nRemoving email address..." -ForegroundColor Yellow

        Set-DistributionGroup `
            -Identity $Group.Identity `
            -EmailAddresses @{
                Remove = $SelectedAddress
            } `
            -ErrorAction Stop

        Write-Host "`nEmail address removed successfully." -ForegroundColor Green
        Write-Host ("Group   : {0}" -f $Group.DisplayName)
        Write-Host ("Address : {0}" -f $EmailAddress)
    }
    catch {
        Write-Host "`nFailed to remove email address." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}