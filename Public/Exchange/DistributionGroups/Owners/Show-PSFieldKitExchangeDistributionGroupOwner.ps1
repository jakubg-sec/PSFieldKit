function Show-PSFieldKitExchangeDistributionGroupOwner {
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

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Distribution Group Owners              |" -ForegroundColor Cyan
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

    $ManagedBy = @($Group.ManagedBy)

    if ($ManagedBy.Count -eq 0) {
        Write-Host "`nNo owners are assigned to this distribution group." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "`nOWNERS" -ForegroundColor DarkCyan
    Write-Host ""

    $Owners = foreach ($Owner in $ManagedBy) {
        try {
            $Recipient = Get-Recipient -Identity $Owner -ErrorAction Stop

            [PSCustomObject]@{
                DisplayName = $Recipient.DisplayName
                Alias = $Recipient.Alias
                PrimarySmtpAddress = $Recipient.PrimarySmtpAddress
                RecipientTypeDetails = $Recipient.RecipientTypeDetails
            }
        }
        catch {
            [PSCustomObject]@{
                DisplayName = [string]$Owner
                Alias = ''
                PrimarySmtpAddress = ''
                RecipientTypeDetails = 'Unknown'
            }
        }
    }

    $Owners |
        Format-Table `
            DisplayName,
            Alias,
            PrimarySmtpAddress,
            RecipientTypeDetails `
        -AutoSize |
        Out-Host

    Write-Host "Owners: $($Owners.Count)" -ForegroundColor Cyan
    Read-Host "`nPress Enter to continue" | Out-Null
}