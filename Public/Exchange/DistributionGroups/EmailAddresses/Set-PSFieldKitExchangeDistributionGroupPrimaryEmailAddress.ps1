function Set-PSFieldKitExchangeDistributionGroupPrimaryEmailAddress {
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

    if (-not (Get-Command Get-Recipient -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-Recipient' is not available." -ForegroundColor Red
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
        $EmailAddress = Read-Host "Enter new primary SMTP address"
    }

    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        Write-Host "`nEmail address cannot be empty." -ForegroundColor Yellow
        return
    }

    $EmailAddress = $EmailAddress.Trim()

    if ($EmailAddress -match '^(?i)(smtp|x400|x500):') {
        Write-Host "`nEnter the email address without an address type prefix." -ForegroundColor Yellow
        Write-Host "Example: group@domain.local" -ForegroundColor Yellow
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

    $EmailAddresses = @(
        $Group.EmailAddresses |
            ForEach-Object {
                $_.ToString()
            }
    )

    $CurrentPrimary = $EmailAddresses |
        Where-Object {
            $_ -cmatch '^SMTP:'
        } |
        Select-Object -First 1

    $CurrentPrimaryAddress = $null

    if ($null -ne $CurrentPrimary) {
        $CurrentPrimaryAddress = $CurrentPrimary.Substring(5)
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$Group.PrimarySmtpAddress)) {
        $CurrentPrimaryAddress = [string]$Group.PrimarySmtpAddress
    }

    if (
        -not [string]::IsNullOrWhiteSpace($CurrentPrimaryAddress) -and
        $CurrentPrimaryAddress -ieq $EmailAddress
    ) {
        Write-Host "`nThis address is already the primary SMTP address." -ForegroundColor Yellow
        return
    }

    $ExistingAddress = $EmailAddresses |
        Where-Object {
            $_ -replace '^[^:]+:', '' -ieq $EmailAddress
        } |
        Select-Object -First 1

    if ($null -ne $ExistingAddress) {
        $AddressSource = "existing secondary address"
    }
    else {
        $AddressSource = "new address"
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

    $NewEmailAddresses = New-Object System.Collections.Generic.List[string]

    foreach ($Address in $EmailAddresses) {
        $AddressType = ''
        $AddressValue = $Address

        if ($Address -match '^([^:]+):(.+)$') {
            $AddressType = $Matches[1]
            $AddressValue = $Matches[2]
        }

        if ($AddressValue -ieq $EmailAddress) {
            continue
        }

        if ($AddressType -ieq 'SMTP') {
            [void]$NewEmailAddresses.Add("smtp:$AddressValue")
        }
        else {
            [void]$NewEmailAddresses.Add($Address)
        }
    }

    [void]$NewEmailAddresses.Insert(0, "SMTP:$EmailAddress")

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|   Set Distribution Group Primary SMTP        |" -ForegroundColor Cyan
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

    Write-Host "`nCURRENT PRIMARY SMTP" -ForegroundColor DarkCyan
    Write-Host ("{0}" -f $CurrentPrimaryAddress) -ForegroundColor Yellow

    Write-Host "`nNEW PRIMARY SMTP" -ForegroundColor DarkCyan
    Write-Host $EmailAddress -ForegroundColor Green
    Write-Host ("Source : {0}" -f $AddressSource)

    if (
        $Group.PSObject.Properties.Name -contains 'EmailAddressPolicyEnabled' -and
        $Group.EmailAddressPolicyEnabled
    ) {
        Write-Host "`nEMAIL ADDRESS POLICY" -ForegroundColor DarkCyan
        Write-Host "This group is currently managed by an email address policy." -ForegroundColor Yellow
        Write-Host "Setting a custom primary SMTP address disables automatic email address policy updates." -ForegroundColor Yellow

        $PolicyConfirmation = Read-Host "Type YES to disable the policy and continue"

        if ($PolicyConfirmation -cne 'YES') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        $DisablePolicy = $true
    }
    else {
        $DisablePolicy = $false
    }

    Write-Host "`nRESULTING ADDRESSES" -ForegroundColor DarkCyan
    Write-Host ("Primary SMTP : {0}" -f $EmailAddress) -ForegroundColor Green

    if (-not [string]::IsNullOrWhiteSpace($CurrentPrimaryAddress)) {
        Write-Host ("Previous SMTP: {0}" -f $CurrentPrimaryAddress)
    }

    Write-Host ""
    $Confirmation = Read-Host "Type YES to change the primary SMTP address"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating primary SMTP address..." -ForegroundColor Yellow

        $Parameters = @{
            Identity = $Group.Identity
            EmailAddresses = $NewEmailAddresses.ToArray()
            ErrorAction = 'Stop'
        }

        if ($DisablePolicy) {
            $Parameters.EmailAddressPolicyEnabled = $false
        }

        Set-DistributionGroup @Parameters

        Write-Host "`nPrimary SMTP address updated successfully." -ForegroundColor Green
        Write-Host ("Group        : {0}" -f $Group.DisplayName)
        Write-Host ("Primary SMTP : {0}" -f $EmailAddress) -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update primary SMTP address." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}