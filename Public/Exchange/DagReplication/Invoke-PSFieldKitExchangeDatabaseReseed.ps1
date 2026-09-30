function Invoke-PSFieldKitExchangeDatabaseReseed {
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

    Clear-Host

    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                 DATABASE RESEED                  |" -ForegroundColor Cyan
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

        $SelectedCopies = @(
            $DatabaseCopies |
                Where-Object {
                    $_.Name -eq $DatabaseName
                }
        )

        if ($SelectedCopies.Count -eq 0) {
            Write-Host ""
            Write-Host "Database copy not found." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""
        Write-Host "Available copies:" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $SelectedCopies.Count; $i++) {
            $Copy = $SelectedCopies[$i]

            Write-Host ("[{0}] {1} - {2}" -f `
                ($i + 1),
                $Copy.MailboxServer,
                $Copy.Status)
        }

        Write-Host ""
        $Selection = Read-Host "Select target copy"

        if (-not $Selection -match '^\d+$') {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $Index = [int]$Selection - 1

        if ($Index -lt 0 -or $Index -ge $SelectedCopies.Count) {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $TargetCopy  = $SelectedCopies[$Index]
        $ServerName  = $TargetCopy.MailboxServer
        $CopyIdentity = "$DatabaseName\$ServerName"

        Write-Host ""
        Write-Host "Database : $DatabaseName" -ForegroundColor White
        Write-Host "Server   : $ServerName" -ForegroundColor White
        Write-Host "Status   : $($TargetCopy.Status)" -ForegroundColor White
        Write-Host ""

        Write-Host "WARNING: This operation will reseed the selected database copy." -ForegroundColor Yellow
        Write-Host ""

        $Confirmation = Read-Host "Type RESEED to continue"

        if ($Confirmation -cne "RESEED") {
            Write-Host ""
            Write-Host "Reseed cancelled." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if (
            $PSCmdlet.ShouldProcess(
                $CopyIdentity,
                "Reseed Exchange database copy"
            )
        ) {
            Update-MailboxDatabaseCopy `
                -Identity $CopyIdentity `
                -DeleteExistingFiles `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Host ""
            Write-Host "Database reseed started successfully." -ForegroundColor Green
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to reseed database copy." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}