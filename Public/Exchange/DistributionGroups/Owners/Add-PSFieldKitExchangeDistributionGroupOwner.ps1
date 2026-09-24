function Add-PSFieldKitExchangeDistributionGroupOwner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$Owner
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

    if ($Group.RecipientTypeDetails -eq 'DynamicDistributionGroup') {
        Write-Host "`nDynamic distribution groups do not support manually managed owners." -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrWhiteSpace($Owner)) {
        $Owner = Read-Host "Enter owner name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Owner)) {
        Write-Host "`nOwner identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Recipient = Get-Recipient -Identity $Owner -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find owner '$Owner'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    $SupportedOwnerTypes = @(
        'UserMailbox',
        'MailUser',
        'MailContact',
        'MailUniversalSecurityGroup'
    )

    if ($SupportedOwnerTypes -notcontains $Recipient.RecipientTypeDetails) {
        Write-Host "`nRecipient type '$($Recipient.RecipientTypeDetails)' cannot be assigned as a distribution group owner." -ForegroundColor Red
        return
    }

    $ExistingOwner = @(
        $Group.ManagedBy | Where-Object {
            $_ -eq $Recipient.Identity -or
            $_ -eq $Recipient.DistinguishedName -or
            $_ -eq $Recipient.Alias -or
            $_ -eq $Recipient.PrimarySmtpAddress
        }
    )

    if ($ExistingOwner.Count -gt 0) {
        Write-Host "`nThe recipient is already an owner of this distribution group." -ForegroundColor Yellow
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Add Distribution Group Owner           |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $GroupDisplayName = [string]$Group.DisplayName

    if ($GroupDisplayName.Length -gt 36) {
        $GroupDisplayName = $GroupDisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group : {0,-36}|" -f $GroupDisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nGROUP" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Group.DisplayName)
    Write-Host ("Alias        : {0}" -f $Group.Alias)
    Write-Host ("Primary SMTP : {0}" -f $Group.PrimarySmtpAddress)

    Write-Host "`nNEW OWNER" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Recipient.DisplayName)
    Write-Host ("Alias        : {0}" -f $Recipient.Alias)
    Write-Host ("SMTP         : {0}" -f $Recipient.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $Recipient.RecipientTypeDetails)

    Write-Host ""
    $Confirmation = Read-Host "Type YES to add this owner"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "Use bypass security group manager check?" -ForegroundColor Cyan
    Write-Host "[1] No"
    Write-Host "[2] Yes"

    $BypassChoice = Read-Host "Select option"

    switch ($BypassChoice) {
        '1' {
            $UseBypass = $false
        }
        '2' {
            $UseBypass = $true
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            return
        }
    }

    try {
        Write-Host "`nAdding owner..." -ForegroundColor Yellow

        $Parameters = @{
            Identity = $Group.Identity
            ManagedBy = @{
                Add = $Recipient.Identity
            }
            ErrorAction = 'Stop'
        }

        if ($UseBypass) {
            $Parameters.BypassSecurityGroupManagerCheck = $true
        }

        Set-DistributionGroup @Parameters

        Write-Host "`nOwner added successfully." -ForegroundColor Green
        Write-Host ("Group : {0}" -f $Group.DisplayName)
        Write-Host ("Owner : {0}" -f $Recipient.DisplayName)
    }
    catch {
        Write-Host "`nFailed to add owner." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}