function Remove-PSFieldKitExchangeDatabaseCopy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
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

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             REMOVE DATABASE COPY             |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $Databases = @(Get-MailboxDatabase -Status -ErrorAction Stop)

        if ($Databases.Count -eq 0) {
            Write-Host "No mailbox databases found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available mailbox databases:" -ForegroundColor DarkCyan
        Write-Host ""

        for ($Index = 0; $Index -lt $Databases.Count; $Index++) {
            Write-Host ("[{0}] {1}" -f ($Index + 1), $Databases[$Index].Name)
        }

        Write-Host ""
        Write-Host "[0] Cancel"
        Write-Host ""

        $Choice = Read-Host "Select database"

        if ($Choice -eq "0") {
            return
        }

        $SelectedIndex = 0

        if (
            -not [int]::TryParse($Choice, [ref]$SelectedIndex) -or
            $SelectedIndex -lt 1 -or
            $SelectedIndex -gt $Databases.Count
        ) {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $SelectedDatabase = $Databases[$SelectedIndex - 1]

        $Copies = @(Get-MailboxDatabaseCopyStatus -Identity $SelectedDatabase.Name -ErrorAction Stop)

        if ($Copies.Count -eq 0) {
            Write-Host ""
            Write-Host "No database copies found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $PassiveCopies = @(
            $Copies | Where-Object {
                $_.Status -ne "Mounted"
            }
        )

        if ($PassiveCopies.Count -eq 0) {
            Write-Host ""
            Write-Host "No passive database copies are available for removal." -ForegroundColor Yellow
            Write-Host "The active database copy cannot be removed with this function." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""
        Write-Host "Available passive copies:" -ForegroundColor DarkCyan
        Write-Host ""

        for ($Index = 0; $Index -lt $PassiveCopies.Count; $Index++) {
            $Copy = $PassiveCopies[$Index]

            $ServerName = [string]$Copy.MailboxServer
            $Status = [string]$Copy.Status

            if ([string]::IsNullOrWhiteSpace($ServerName)) {
                $ServerName = "Unknown"
            }

            if ([string]::IsNullOrWhiteSpace($Status)) {
                $Status = "Unknown"
            }

            Write-Host ("[{0}] {1} - {2}" -f ($Index + 1), $ServerName, $Status)
        }

        Write-Host ""
        Write-Host "[0] Cancel"
        Write-Host ""

        $Choice = Read-Host "Select database copy"

        if ($Choice -eq "0") {
            return
        }

        $SelectedIndex = 0

        if (
            -not [int]::TryParse($Choice, [ref]$SelectedIndex) -or
            $SelectedIndex -lt 1 -or
            $SelectedIndex -gt $PassiveCopies.Count
        ) {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $SelectedCopy = $PassiveCopies[$SelectedIndex - 1]

        $DatabaseName = [string]$SelectedCopy.Name
        $ServerName = [string]$SelectedCopy.MailboxServer
        $Status = [string]$SelectedCopy.Status

        if ([string]::IsNullOrWhiteSpace($ServerName)) {
            Write-Host ""
            Write-Host "Unable to determine the Mailbox server for the selected copy." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if ($Status -eq "Mounted") {
            Write-Host ""
            Write-Host "The selected copy is active and cannot be removed." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $RemainingCopies = @(
            $Copies | Where-Object {
                [string]$_.MailboxServer -ine $ServerName
            }
        )

        if ($RemainingCopies.Count -eq 0) {
            Write-Host ""
            Write-Host "This appears to be the only database copy." -ForegroundColor Red
            Write-Host "The last database copy cannot be removed with this function." -ForegroundColor Yellow
            Write-Host "Use database removal procedures if you intend to remove the mailbox database itself." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $DAGName = "Unknown"

        try {
            $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

            foreach ($DAG in $DAGs) {
                foreach ($Member in @($DAG.Servers)) {
                    if ([string]$Member.Name -ieq $ServerName) {
                        $DAGName = [string]$DAG.Name
                        break
                    }
                }

                if ($DAGName -ne "Unknown") {
                    break
                }
            }
        }
        catch {
            $DAGName = "Unknown"
        }

        Write-Host ""
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                COPY SUMMARY                  |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Database      : {0,-25}|" -f $DatabaseName)
        Write-Host ("|  Server        : {0,-25}|" -f $ServerName)
        Write-Host ("|  DAG           : {0,-25}|" -f $DAGName)
        Write-Host ("|  Status        : {0,-25}|" -f $Status)
        Write-Host ("|  Copies left   : {0,-25}|" -f $RemainingCopies.Count)
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        Write-Host "WARNING: The database copy configuration will be removed." -ForegroundColor Red
        Write-Host "Database and transaction log files are not automatically deleted." -ForegroundColor Yellow
        Write-Host ""

        $Confirmation = Read-Host "Type REMOVE to remove the database copy"

        if ($Confirmation -cne "REMOVE") {
            Write-Host ""
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        try {
            $CopyIdentity = "$DatabaseName\$ServerName"

            if ($PSCmdlet.ShouldProcess($CopyIdentity, "Remove mailbox database copy")) {
                Remove-MailboxDatabaseCopy -Identity $CopyIdentity -Confirm:$false -ErrorAction Stop

                Write-Host ""
                Write-Host "Database copy removed successfully." -ForegroundColor Green
                Write-Host ""
                Write-Host "Database : $DatabaseName"
                Write-Host "Server   : $ServerName"
                Write-Host ""
                Write-Host "Database and transaction log files may still exist on the server." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host ""
            Write-Host "Failed to remove database copy." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve Exchange database information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}