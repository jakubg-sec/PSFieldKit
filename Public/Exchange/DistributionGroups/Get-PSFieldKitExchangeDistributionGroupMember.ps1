function Get-PSFieldKitExchangeDistributionGroupMember {
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
        Read-host "`nPress Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        Read-host "`nPress Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-DistributionGroupMember -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroupMember' is not available." -ForegroundColor Red
        Read-host "`nPress Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter distribution group name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDistribution group identity cannot be empty." -ForegroundColor Yellow
        Read-host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Group = Get-DistributionGroup -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find distribution group '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($Group.RecipientTypeDetails -eq 'DynamicDistributionGroup') {
        Write-Host "`nDynamic distribution groups do not have manually managed members." -ForegroundColor Yellow
        Read-host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nRetrieving group members..." -ForegroundColor Yellow
        $Members = @(
            Get-DistributionGroupMember `
                -Identity $Group.Identity `
                -ResultSize Unlimited `
                -ErrorAction Stop |
                Sort-Object DisplayName
        )
    }
    catch {
        Write-Host "`nFailed to retrieve members of '$($Group.DisplayName)'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|         Distribution Group Members           |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Group.DisplayName
    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group   : {0,-34}|" -f $DisplayName) -ForegroundColor White
    Write-Host ("|  Members : {0,-34}|" -f $Members.Count) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($Members.Count -eq 0) {
        Write-Host "`nNo members found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "`nMEMBERS" -ForegroundColor DarkCyan
    Write-Host ""

    $Index = 1

    foreach ($Member in $Members) {
        $MemberType = if (
            $Member.PSObject.Properties.Name -contains 'RecipientTypeDetails' -and
            -not [string]::IsNullOrWhiteSpace([string]$Member.RecipientTypeDetails)
        ) {
            [string]$Member.RecipientTypeDetails
        }
        else {
            [string]$Member.RecipientType
        }

        Write-Host ("[{0}] {1}" -f $Index, $Member.DisplayName) -ForegroundColor Cyan
        Write-Host ("    Alias : {0}" -f $Member.Alias)
        Write-Host ("    SMTP  : {0}" -f $Member.PrimarySmtpAddress)
        Write-Host ("    Type  : {0}" -f $MemberType)
        Write-Host ""
        $Index++
    }

    Write-Host ("Total members: {0}" -f $Members.Count) -ForegroundColor Cyan
    Read-Host "`nPress Enter to continue" | Out-Null
}