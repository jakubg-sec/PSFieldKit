function Update-PSFieldKitExchangeDatabaseCopy {
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
        Write-Host "|               UPDATE DATABASE COPY               |" -ForegroundColor Cyan
        Write-Host "|                    PSFieldKit                    |" -ForegroundColor Cyan
        Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        try {
            $DatabaseCopies = Get-MailboxDatabaseCopyStatus -ErrorAction Stop

            if (-not $DatabaseCopies) {
                Write-Host "No database copies were found." -ForegroundColor Yellow
                Read-Host "`nPress Enter to continue" | Out-Null
                return
            }

            $DatabaseCopies |
                Select-Object `
                    @{Name = "Database"; Expression = { $_.Name } },
                    Status,
                    CopyQueueLength,
                    ReplayQueueLength |
                Format-Table -AutoSize

            Write-Host ""

            $DatabaseName = Read-Host "Enter database copy name"

            if ([string]::IsNullOrWhiteSpace($DatabaseName)) {
                return
            }

            $SelectedCopy = $DatabaseCopies |
                Where-Object {
                    $_.Name -eq $DatabaseName
                }

            if (-not $SelectedCopy) {
                Write-Host ""
                Write-Host "Database copy not found." -ForegroundColor Red
                Read-Host "`nPress Enter to continue" | Out-Null
                continue
            }

            $ServerName = $SelectedCopy.MailboxServer

            Write-Host ""
            Write-Host "Database : $DatabaseName" -ForegroundColor White
            Write-Host "Server   : $ServerName" -ForegroundColor White
            Write-Host "Status   : $($SelectedCopy.Status)" -ForegroundColor White
            Write-Host ""

            if (
                $PSCmdlet.ShouldProcess(
                    "$DatabaseName on $ServerName",
                    "Update database copy"
                )
            ) {
                Update-MailboxDatabaseCopy `
                    -Identity "$DatabaseName\$ServerName" `
                    -Confirm:$false `
                    -ErrorAction Stop

                Write-Host ""
                Write-Host "Database copy update started successfully." -ForegroundColor Green
            }
        }
        catch {
            Write-Host ""
            Write-Host "Failed to update database copy." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }

        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }
}