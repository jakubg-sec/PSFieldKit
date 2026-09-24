function Add-PSFieldKitExchangeDistributionGroupEmailAddress {
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

    if (-not (Get-Command Get-Recipient -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-Recipient' is not available." -ForegroundColor Red
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

    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        $EmailAddress = Read-Host "Enter new SMTP address"
    }

    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        Write-Host "`nEmail address cannot be empty." -ForegroundColor Yellow
        return
    }

    $EmailAddress = $EmailAddress.Trim()

    if ($EmailAddress -match '^(?i)(smtp|x400|x500):') {
        Write-Host "`nEnter the email address without an address type prefix." -ForegroundColor Yellow
        Write-Host "Example: alias@domain.local" -ForegroundColor Yellow
        return
    }

    try {
        $MailAddress = [System.Net.Mail.MailAddress]$EmailAddress

        if ($MailAddress.Address -ne $EmailAddress) {
            Write-Host "`nInvalid SMTP address format." -ForegroundColor Red
            return
        }
    }
    catch {
        Write-Host "`nInvalid SMTP address format." -ForegroundColor Red
        return
    }

    $ExistingAddresses = @(
        $Group.EmailAddresses |
            ForEach-Object {
                $_.ToString()
            }
    )

    $ExistingAddress = $ExistingAddresses |
        Where-Object {
            $_ -replace '^[^:]+:', '' -eq $EmailAddress
        } |
        Select-Object -First 1

    if ($ExistingAddress) {
        Write-Host "`nThis email address is already configured on the distribution group." -ForegroundColor Yellow
        return
    }

    try {
        $RecipientUsingAddress = Get-Recipient -Identity $EmailAddress -ErrorAction SilentlyContinue

        if (
            $null -ne $RecipientUsingAddress -and
            $RecipientUsingAddress.Identity -ne $Group.Identity -and
            $RecipientUsingAddress.DistinguishedName -ne $Group.DistinguishedName
        ) {
            Write-Host "`nThis email address is already assigned to another recipient." -ForegroundColor Red
            Write-Host ("Recipient : {0}" -f $RecipientUsingAddress.DisplayName) -ForegroundColor Yellow
            Write-Host ("Type      : {0}" -f $RecipientUsingAddress.RecipientTypeDetails) -ForegroundColor Yellow
            return
        }
    }
    catch {
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|      Add Distribution Group Email Address    |" -ForegroundColor Cyan
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

    Write-Host "`nGROUP" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Group.DisplayName)
    Write-Host ("Alias        : {0}" -f $Group.Alias)
    Write-Host ("Primary SMTP : {0}" -f $Group.PrimarySmtpAddress)

    Write-Host "`nNEW EMAIL ADDRESS" -ForegroundColor DarkCyan
    Write-Host ("Address      : {0}" -f $EmailAddress) -ForegroundColor Green
    Write-Host "Address Type : Secondary SMTP"

    $Confirmation = Read-Host "`nType YES to add this email address"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nAdding email address..." -ForegroundColor Yellow

        Set-DistributionGroup `
            -Identity $Group.Identity `
            -EmailAddresses @{
                Add = "smtp:$EmailAddress"
            } `
            -ErrorAction Stop

        Write-Host "`nEmail address added successfully." -ForegroundColor Green
        Write-Host ("Group   : {0}" -f $Group.DisplayName)
        Write-Host ("Address : {0}" -f $EmailAddress)
    }
    catch {
        Write-Host "`nFailed to add email address." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}