function Move-PSFieldKitExchangeActiveDatabase {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    while ($true) {
        Clear-Host

        Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              ACTIVATE DATABASE COPY              |" -ForegroundColor Cyan
        Write-Host "|                    PSFieldKit                    |" -ForegroundColor Cyan
        Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        try {
            $DatabaseCopies = Get-MailboxDatabaseCopyStatus -ErrorAction Stop |
                Where-Object {
                    $_.Status -eq "Healthy" -or
                    $_.Status -eq "Mounted"
                }

            if (-not $DatabaseCopies) {
                Write-Host "No suitable database copies were found." -ForegroundColor Yellow
                Read-Host "`nPress Enter to continue" | Out-Null
                return
            }

            $DatabaseCopies |
                Select-Object `
                    @{Name = "Database"; Expression = { $_.Name } },
                    @{Name = "Server"; Expression = { $_.MailboxServer } },
                    Status,
                    CopyQueueLength,
                    ReplayQueueLength |
                Format-Table -AutoSize

            Write-Host ""

            $DatabaseName = Read-Host "Enter database name"
            if ([string]::IsNullOrWhiteSpace($DatabaseName)) {
                return
            }

            $SelectedCopies = $DatabaseCopies |
                Where-Object {
                    $_.Name -eq $DatabaseName
                }

            if (-not $SelectedCopies) {
                Write-Host ""
                Write-Host "Database not found." -ForegroundColor Red
                Read-Host "`nPress Enter to continue" | Out-Null
                continue
            }

            Write-Host ""
            $TargetServer = Read-Host "Enter target server"

            if ([string]::IsNullOrWhiteSpace($TargetServer)) {
                return
            }

            Write-Host ""
            Write-Host "Database : $DatabaseName" -ForegroundColor White
            Write-Host "Target   : $TargetServer" -ForegroundColor White
            Write-Host ""

            if (
                $PSCmdlet.ShouldProcess(
                    "$DatabaseName",
                    "Activate database copy on $TargetServer"
                )
            ) {
                Move-ActiveMailboxDatabase `
                    -Identity $DatabaseName `
                    -ActivateOnServer $TargetServer `
                    -Confirm:$false `
                    -ErrorAction Stop

                Write-Host ""
                Write-Host "Database activation completed." -ForegroundColor Green
            }
        }
        catch {
            Write-Host ""
            Write-Host "Failed to activate database copy." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }

        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }
}