function Search-PSFieldKitExchangeDistributionGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext,

        [Parameter(Mandatory = $false)]
        [string]$SearchTerm,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$ResultSize = 100
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($null -eq (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        $SearchTerm = Read-Host "Enter distribution group name or alias"
    }

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Write-Host "`nSearch term cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nSearching distribution groups for '$SearchTerm'..." -ForegroundColor Yellow

        $DistributionGroups = @(
            Get-DistributionGroup `
                -Anr $SearchTerm `
                -ResultSize $ResultSize `
                -ErrorAction Stop |
            Sort-Object DisplayName
        )

        if ($DistributionGroups.Count -eq 0) {
            Write-Host "`nNo distribution groups found." -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        Write-Host "`nFound $($DistributionGroups.Count) distribution group(s)." -ForegroundColor Green
        Write-Host ""

        $DistributionGroups |
            Select-Object `
                DisplayName,
                Alias,
                PrimarySmtpAddress,
                RecipientTypeDetails |
            Format-Table -AutoSize |
            Out-Host

        if ($DistributionGroups.Count -eq $ResultSize) {
            Write-Host "Result limit reached: $ResultSize." -ForegroundColor Yellow
        }

        Write-Host ""
        Read-Host "Press Enter to continue" | Out-Null
    }
    catch {
        Write-Host "`nFailed to search distribution groups." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
    }
}