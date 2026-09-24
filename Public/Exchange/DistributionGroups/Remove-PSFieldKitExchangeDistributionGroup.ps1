function Remove-PSFieldKitExchangeDistributionGroup {
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

    if (-not (Get-Command Remove-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Remove-DistributionGroup' is not available." -ForegroundColor Red
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

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Remove Distribution Group           |" -ForegroundColor Cyan
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

    Write-Host "`nGROUP INFORMATION" -ForegroundColor DarkCyan
    Write-Host ("Display Name       : {0}" -f $Group.DisplayName)
    Write-Host ("Name               : {0}" -f $Group.Name)
    Write-Host ("Alias              : {0}" -f $Group.Alias)
    Write-Host ("Primary SMTP       : {0}" -f $Group.PrimarySmtpAddress)
    Write-Host ("Group Type         : {0}" -f $Group.RecipientTypeDetails)

    Write-Host "`nWARNING" -ForegroundColor Red
    Write-Host "This operation will permanently remove the distribution group." -ForegroundColor Red
    Write-Host "The group object and its Exchange configuration will be deleted." -ForegroundColor Yellow

    Write-Host ""
    $Confirmation = Read-Host "Type YES to permanently remove '$($Group.DisplayName)'"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nRemoving distribution group..." -ForegroundColor Yellow

        Remove-DistributionGroup `
            -Identity $Group.Identity `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "`nDistribution group removed successfully." -ForegroundColor Green
        Write-Host "Group: $($Group.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to remove distribution group." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        if ($_.Exception.Message -match 'manager|owner|permission|bypass') {
            Write-Host "`nThe group may require -BypassSecurityGroupManagerCheck." -ForegroundColor Yellow
        }
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}