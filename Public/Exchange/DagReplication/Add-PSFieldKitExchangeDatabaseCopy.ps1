function Add-PSFieldKitExchangeDatabaseCopy {
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
    Write-Host "|              ADD DATABASE COPY               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available DAGs:" -ForegroundColor DarkCyan
        Write-Host ""

        for ($Index = 0; $Index -lt $DAGs.Count; $Index++) {
            $MemberCount = @($DAGs[$Index].Servers).Count
            Write-Host ("[{0}] {1} ({2} member(s))" -f ($Index + 1), $DAGs[$Index].Name, $MemberCount)
        }

        Write-Host ""
        Write-Host "[0] Cancel"
        Write-Host ""

        $Choice = Read-Host "Select DAG"

        if ($Choice -eq "0") {
            return
        }

        $SelectedIndex = 0

        if (
            -not [int]::TryParse($Choice, [ref]$SelectedIndex) -or
            $SelectedIndex -lt 1 -or
            $SelectedIndex -gt $DAGs.Count
        ) {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $SelectedDAG = $DAGs[$SelectedIndex - 1]
        $DAGMembers = @($SelectedDAG.Servers)

        if ($DAGMembers.Count -eq 0) {
            Write-Host ""
            Write-Host "The selected DAG has no members." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""
        Write-Host "Available mailbox databases:" -ForegroundColor DarkCyan
        Write-Host ""

        $Databases = @(Get-MailboxDatabase -Status -ErrorAction Stop)

        if ($Databases.Count -eq 0) {
            Write-Host "No mailbox databases found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        for ($Index = 0; $Index -lt $Databases.Count; $Index++) {
            $Database = $Databases[$Index]
            Write-Host ("[{0}] {1}" -f ($Index + 1), $Database.Name)
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

        try {
            $ExistingCopies = @(Get-MailboxDatabaseCopyStatus -Identity $SelectedDatabase.Name -ErrorAction Stop)
        }
        catch {
            Write-Host ""
            Write-Host "Unable to retrieve existing database copies." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if (
            $ExistingCopies.Count -eq 1 -and
            $SelectedDatabase.CircularLoggingEnabled -eq $true
        ) {
            Write-Host ""
            Write-Host "Circular logging is enabled for this database." -ForegroundColor Red
            Write-Host "Disable circular logging before adding the first database copy." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""
        Write-Host "Available DAG members:" -ForegroundColor DarkCyan
        Write-Host ""

        $AvailableMembers = @()

        foreach ($Member in $DAGMembers) {
            $ServerName = [string]$Member.Name

            $ExistingCopy = $ExistingCopies | Where-Object {
                [string]$_.MailboxServer -ieq $ServerName
            }

            if (-not $ExistingCopy) {
                $AvailableMembers += $ServerName
            }
        }

        if ($AvailableMembers.Count -eq 0) {
            Write-Host "No available DAG members for this database." -ForegroundColor Yellow
            Write-Host "Every DAG member already has a copy of this database." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        for ($Index = 0; $Index -lt $AvailableMembers.Count; $Index++) {
            Write-Host ("[{0}] {1}" -f ($Index + 1), $AvailableMembers[$Index])
        }

        Write-Host ""
        Write-Host "[0] Cancel"
        Write-Host ""

        $Choice = Read-Host "Select target server"

        if ($Choice -eq "0") {
            return
        }

        $SelectedIndex = 0

        if (
            -not [int]::TryParse($Choice, [ref]$SelectedIndex) -or
            $SelectedIndex -lt 1 -or
            $SelectedIndex -gt $AvailableMembers.Count
        ) {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $TargetServer = $AvailableMembers[$SelectedIndex - 1]

        Write-Host ""
        Write-Host "Activation Preference" -ForegroundColor DarkCyan
        Write-Host "Enter a value of 1 or greater."
        Write-Host ""

        $ActivationPreferenceInput = Read-Host "Activation Preference"

        $ActivationPreference = 0

        if (
            -not [int]::TryParse($ActivationPreferenceInput, [ref]$ActivationPreference) -or
            $ActivationPreference -lt 1
        ) {
            Write-Host ""
            Write-Host "Invalid Activation Preference." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $CopyCountAfterAdd = $ExistingCopies.Count + 1

        if ($ActivationPreference -gt $CopyCountAfterAdd) {
            Write-Host ""
            Write-Host "Activation Preference cannot be greater than the resulting copy count." -ForegroundColor Red
            Write-Host "Maximum allowed value: $CopyCountAfterAdd" -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                COPY SUMMARY                  |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  DAG                : {0,-20}|" -f $SelectedDAG.Name)
        Write-Host ("|  Database           : {0,-20}|" -f $SelectedDatabase.Name)
        Write-Host ("|  Target Server      : {0,-20}|" -f $TargetServer)
        Write-Host ("|  Activation Pref.   : {0,-20}|" -f $ActivationPreference)
        Write-Host "|  Automatic Seeding : Enabled                |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        Write-Host "The database copy will be created and automatically seeded." -ForegroundColor Yellow
        Write-Host ""

        $Confirmation = Read-Host "Type ADD to add the database copy"

        if ($Confirmation -cne "ADD") {
            Write-Host ""
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        try {
            if ($PSCmdlet.ShouldProcess("$($SelectedDatabase.Name)\$TargetServer", "Add mailbox database copy")) {
                Add-MailboxDatabaseCopy -Identity $SelectedDatabase.Name -MailboxServer $TargetServer -ActivationPreference $ActivationPreference -Confirm:$false -ErrorAction Stop

                Write-Host ""
                Write-Host "Database copy added successfully." -ForegroundColor Green
                Write-Host ""
                Write-Host "Database          : $($SelectedDatabase.Name)"
                Write-Host "DAG               : $($SelectedDAG.Name)"
                Write-Host "Target Server     : $TargetServer"
                Write-Host "Activation Pref.  : $ActivationPreference"
                Write-Host ""
                Write-Host "The copy is now being seeded." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host ""
            Write-Host "Failed to add database copy." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve Exchange information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}