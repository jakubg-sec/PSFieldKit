function Add-PSFieldKitExchangeDistributionGroupMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity,
        [Parameter()]
        [string]$Member
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-Recipient -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-Recipient' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Add-DistributionGroupMember -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Add-DistributionGroupMember' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter distribution group name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDistribution group identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Group = Get-DistributionGroup -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find distribution group '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($Group.RecipientTypeDetails -eq 'DynamicDistributionGroup') {
        Write-Host "`nDynamic distribution groups do not have manually managed members." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Member)) {
        $Member = Read-Host "Enter member name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Member)) {
        Write-Host "`nMember identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Recipient = Get-Recipient -Identity $Member -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find recipient '$Member'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $SupportedTypes = @(
        'UserMailbox',
        'SharedMailbox',
        'RoomMailbox',
        'EquipmentMailbox',
        'MailUser',
        'MailContact',
        'MailUniversalDistributionGroup',
        'MailUniversalSecurityGroup'
    )

    if ($SupportedTypes -notcontains $Recipient.RecipientTypeDetails) {
        Write-Host "`nRecipient type '$($Recipient.RecipientTypeDetails)' cannot be added to this distribution group." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $ExistingMember = Get-DistributionGroupMember `
            -Identity $Group.Identity `
            -ResultSize Unlimited `
            -ErrorAction Stop |
            Where-Object {
                $_.Identity -eq $Recipient.Identity -or
                $_.PrimarySmtpAddress -eq $Recipient.PrimarySmtpAddress
            } |
            Select-Object -First 1
    }
    catch {
        Write-Host "`nFailed to check existing group membership." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($null -ne $ExistingMember) {
        Write-Host "`nThe recipient is already a member of this group." -ForegroundColor Yellow
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|      Add Distribution Group Member           |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $GroupDisplayName = [string]$Group.DisplayName

    if ($GroupDisplayName.Length -gt 36) {
        $GroupDisplayName = $GroupDisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group  : {0,-35}|" -f $GroupDisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nGROUP" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Group.DisplayName)
    Write-Host ("Alias        : {0}" -f $Group.Alias)
    Write-Host ("Primary SMTP : {0}" -f $Group.PrimarySmtpAddress)

    Write-Host "`nMEMBER" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Recipient.DisplayName)
    Write-Host ("Alias        : {0}" -f $Recipient.Alias)
    Write-Host ("SMTP         : {0}" -f $Recipient.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $Recipient.RecipientTypeDetails)
    Write-Host ""

    $Confirmation = Read-Host "Type YES to add this member"

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
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    try {
        Write-Host "`nAdding member..." -ForegroundColor Yellow

        $Parameters = @{
            Identity    = $Group.Identity
            Member      = $Recipient.Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ($UseBypass) {
            $Parameters.BypassSecurityGroupManagerCheck = $true
        }

        Add-DistributionGroupMember @Parameters

        Write-Host "`nMember added successfully." -ForegroundColor Green
        Write-Host ("Group  : {0}" -f $Group.DisplayName)
        Write-Host ("Member : {0}" -f $Recipient.DisplayName)
    }
    catch {
        Write-Host "`nFailed to add member." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}