function Remove-PSFieldKitExchangeDistributionGroupOwner {
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

    $ManagedBy = @($Group.ManagedBy)

    if ($ManagedBy.Count -eq 0) {
        Write-Host "`nThe distribution group has no owners." -ForegroundColor Red
        return
    }

    if ($ManagedBy.Count -eq 1) {
        Write-Host "`nThe last owner cannot be removed." -ForegroundColor Yellow
        Write-Host "Exchange requires every distribution group to have at least one owner." -ForegroundColor Yellow
        return
    }

    $Owners = foreach ($OwnerIdentity in $ManagedBy) {
        try {
            $Recipient = Get-Recipient -Identity $OwnerIdentity -ErrorAction Stop

            [PSCustomObject]@{
                Identity = $OwnerIdentity
                DisplayName = $Recipient.DisplayName
                Alias = $Recipient.Alias
                PrimarySmtpAddress = [string]$Recipient.PrimarySmtpAddress
                RecipientTypeDetails = $Recipient.RecipientTypeDetails
            }
        }
        catch {
            [PSCustomObject]@{
                Identity = $OwnerIdentity
                DisplayName = [string]$OwnerIdentity
                Alias = ''
                PrimarySmtpAddress = ''
                RecipientTypeDetails = 'Unknown'
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($Owner)) {
        Write-Host "`nCurrent owners:" -ForegroundColor Cyan
        Write-Host ""

        $Index = 1

        foreach ($CurrentOwner in $Owners) {
            Write-Host ("[{0}] {1}" -f $Index, $CurrentOwner.DisplayName)
            if (-not [string]::IsNullOrWhiteSpace($CurrentOwner.PrimarySmtpAddress)) {
                Write-Host ("    SMTP : {0}" -f $CurrentOwner.PrimarySmtpAddress)
            }
            Write-Host ("    Type : {0}" -f $CurrentOwner.RecipientTypeDetails)
            Write-Host ""

            $Index++
        }

        $OwnerChoice = Read-Host "Select owner to remove"

        if (-not $OwnerChoice -match '^\d+$') {
            Write-Host "`nInvalid owner selection." -ForegroundColor Red
            return
        }

        $OwnerIndex = [int]$OwnerChoice

        if ($OwnerIndex -lt 1 -or $OwnerIndex -gt $Owners.Count) {
            Write-Host "`nInvalid owner selection." -ForegroundColor Red
            return
        }

        $SelectedOwner = $Owners[$OwnerIndex - 1]
    }
    else {
        try {
            $Recipient = Get-Recipient -Identity $Owner -ErrorAction Stop
        }
        catch {
            Write-Host "`nFailed to find owner '$Owner'." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            return
        }

        $SelectedOwner = $Owners |
            Where-Object {
                $_.Identity -eq $Recipient.Identity -or
                $_.Identity -eq $Recipient.DistinguishedName -or
                $_.Alias -eq $Recipient.Alias -or
                (
                    -not [string]::IsNullOrWhiteSpace($_.PrimarySmtpAddress) -and
                    $_.PrimarySmtpAddress -eq [string]$Recipient.PrimarySmtpAddress
                )
            } |
            Select-Object -First 1

        if ($null -eq $SelectedOwner) {
            Write-Host "`nThe specified recipient is not an owner of this distribution group." -ForegroundColor Yellow
            return
        }
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Remove Distribution Group Owner        |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $GroupDisplayName = [string]$Group.DisplayName

    if ([string]::IsNullOrWhiteSpace($GroupDisplayName)) {
        $GroupDisplayName = [string]$Group.Name
    }

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

    Write-Host "`nOWNER TO REMOVE" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $SelectedOwner.DisplayName)
    Write-Host ("Alias        : {0}" -f $SelectedOwner.Alias)
    Write-Host ("SMTP         : {0}" -f $SelectedOwner.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $SelectedOwner.RecipientTypeDetails)

    Write-Host "`nWARNING" -ForegroundColor Red
    Write-Host "This operation will remove the selected owner from the distribution group." -ForegroundColor Yellow

    $Confirmation = Read-Host "`nType YES to remove this owner"

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
        Write-Host "`nRemoving owner..." -ForegroundColor Yellow

        $Parameters = @{
            Identity = $Group.Identity
            ManagedBy = @{
                Remove = $SelectedOwner.Identity
            }
            ErrorAction = 'Stop'
        }

        if ($UseBypass) {
            $Parameters.BypassSecurityGroupManagerCheck = $true
        }

        Set-DistributionGroup @Parameters

        Write-Host "`nOwner removed successfully." -ForegroundColor Green
        Write-Host ("Group : {0}" -f $Group.DisplayName)
        Write-Host ("Owner : {0}" -f $SelectedOwner.DisplayName)
    }
    catch {
        Write-Host "`nFailed to remove owner." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}