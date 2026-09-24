function Show-PSFieldKitExchangeDistributionGroupEmailAddress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity
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

    $EmailAddresses = @($Group.EmailAddresses)

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|      Distribution Group Email Addresses      |" -ForegroundColor Cyan
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

    if ($EmailAddresses.Count -eq 0) {
        Write-Host "`nNo email addresses are configured." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "`nEMAIL ADDRESSES" -ForegroundColor DarkCyan
    Write-Host ""

    $Index = 1

    foreach ($Address in $EmailAddresses) {
        $AddressString = $Address.ToString()
        $AddressType = "Unknown"
        $EmailAddress = $AddressString

        if ($AddressString -match '^SMTP:(.+)$') {
            $AddressType = "Primary SMTP"
            $EmailAddress = $Matches[1]
        }
        elseif ($AddressString -match '^smtp:(.+)$') {
            $AddressType = "Secondary SMTP"
            $EmailAddress = $Matches[1]
        }
        elseif ($AddressString -match '^(\w+):(.+)$') {
            $AddressType = $Matches[1].ToUpper()
            $EmailAddress = $Matches[2]
        }

        $AddressColor = "White"

        if ($AddressType -eq "Primary SMTP") {
            $AddressColor = "Green"
        }
        elseif ($AddressType -eq "Secondary SMTP") {
            $AddressColor = "Gray"
        }

        Write-Host ("[{0}] {1,-16} {2}" -f $Index, $AddressType, $EmailAddress) -ForegroundColor $AddressColor
        $Index++
    }

    Write-Host ""
    Write-Host ("Total addresses: {0}" -f $EmailAddresses.Count) -ForegroundColor Cyan
    Write-Host ("Primary SMTP   : {0}" -f $Group.PrimarySmtpAddress) -ForegroundColor Green

    Read-Host "`nPress Enter to continue" | Out-Null
}