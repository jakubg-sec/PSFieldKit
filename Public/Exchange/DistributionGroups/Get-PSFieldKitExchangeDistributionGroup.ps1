function Get-PSFieldKitExchangeDistributionGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$ResultSize = 50
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        return
    }

    $ServerName = "Unknown"

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
        -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
    ) {
        $ServerName = [string]$ExchangeContext.ServerName
    }

    if ($ServerName.Length -gt 35) {
        $ServerName = $ServerName.Substring(0, 32) + "..."
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          List Distribution Groups            |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($null -eq (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nRetrieving distribution groups..." -ForegroundColor Yellow

        $DistributionGroups = @(
            Get-DistributionGroup -ResultSize $ResultSize -ErrorAction Stop |
                Sort-Object DisplayName
        )

        if ($DistributionGroups.Count -eq 0) {
            Write-Host "`nNo distribution groups were found." -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        Write-Host "`nDistribution Groups: $($DistributionGroups.Count)" -ForegroundColor Cyan
        Write-Host ""

        $DistributionGroups |
            Select-Object `
                DisplayName,
                Alias,
                PrimarySmtpAddress,
                RecipientTypeDetails |
            Format-Table -AutoSize |
            Out-Host

        Write-Host ""
        Write-Host "Distribution groups displayed: $($DistributionGroups.Count)" -ForegroundColor DarkGray

        if ($DistributionGroups.Count -eq $ResultSize) {
            Write-Host "Result limit reached: $ResultSize." -ForegroundColor Yellow
        }

        Read-Host "Press Enter to continue" | Out-Null
    }
    catch {
        Write-Host "`nFailed to retrieve distribution groups." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
    }
}