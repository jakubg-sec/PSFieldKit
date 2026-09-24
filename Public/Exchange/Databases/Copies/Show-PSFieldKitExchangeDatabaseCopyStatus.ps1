function Show-PSFieldKitExchangeDatabaseCopyStatus {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$Server,

        [Parameter()]
        [switch]$Local,

        [Parameter()]
        [switch]$ExtendedErrorInfo

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Get-MailboxDatabaseCopyStatus -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Get-MailboxDatabaseCopyStatus' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if (
        -not [string]::IsNullOrWhiteSpace($Identity) -and
        -not [string]::IsNullOrWhiteSpace($Server)
    ) {

        Write-Host "`nIdentity and Server cannot be used together." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if (
        $Local -and
        -not [string]::IsNullOrWhiteSpace($Server)
    ) {

        Write-Host "`nLocal and Server cannot be used together." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ([string]::IsNullOrWhiteSpace($Identity) -and
        [string]::IsNullOrWhiteSpace($Server) -and
        -not $Local) {

        $Identity = Read-Host "Enter database name, database\server or press Enter for all copies"

        if ([string]::IsNullOrWhiteSpace($Identity)) {
            $Identity = $null
        }

    }

    try {

        Write-Host "`nRetrieving database copy status..." -ForegroundColor Yellow

        $Parameters = @{
            ErrorAction = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($Identity)) {
            $Parameters['Identity'] = $Identity
        }

        if (-not [string]::IsNullOrWhiteSpace($Server)) {
            $Parameters['Server'] = $Server
        }

        if ($Local) {
            $Parameters['Local'] = $true
        }

        if ($ExtendedErrorInfo) {
            $Parameters['ExtendedErrorInfo'] = $true
        }

        $Copies = @(
            Get-MailboxDatabaseCopyStatus @Parameters |
                Sort-Object DatabaseName, MailboxServerName
        )

    }
    catch {

        Write-Host "`nFailed to retrieve database copy status." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Database Copy Status                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    if (-not [string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host ("|  Database : {0,-33}|" -f $Identity)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Server)) {
        Write-Host ("|  Server   : {0,-33}|" -f $Server)
    }
    elseif ($Local) {
        Write-Host "|  Scope    : Local server                    |"
    }
    else {
        Write-Host "|  Scope    : Organization                    |"
    }

    Write-Host ("|  Copies   : {0,-33}|" -f $Copies.Count)
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($Copies.Count -eq 0) {

        Write-Host "`nNo database copies were found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    Write-Host "`nCOPY STATUS" -ForegroundColor DarkCyan
    Write-Host ""

    foreach ($Copy in $Copies) {

        $DatabaseName = $Copy.DatabaseName
        $ServerName = $Copy.MailboxServerName
        $Status = [string]$Copy.Status
        $ContentIndexState = [string]$Copy.ContentIndexState

        if ([string]::IsNullOrWhiteSpace($DatabaseName)) {

            if ($Copy.PSObject.Properties.Name -contains 'Identity') {

                $IdentityParts = $Copy.Identity.ToString().Split('\')

                if ($IdentityParts.Count -gt 0) {
                    $DatabaseName = $IdentityParts[0]
                }

                if (
                    [string]::IsNullOrWhiteSpace($ServerName) -and
                    $IdentityParts.Count -gt 1
                ) {
                    $ServerName = $IdentityParts[1]
                }

            }

        }

        $StatusColor = switch ($Status) {

            'Mounted' {
                'Green'
            }

            'Healthy' {
                'Green'
            }

            'DisconnectedAndHealthy' {
                'Yellow'
            }

            'FailedAndSuspended' {
                'Red'
            }

            'Failed' {
                'Red'
            }

            'ServiceDown' {
                'Red'
            }

            default {
                'Yellow'
            }

        }

        $ContentIndexColor = switch ($ContentIndexState) {

            'Healthy' {
                'Green'
            }

            'Failed' {
                'Red'
            }

            'Crawling' {
                'Yellow'
            }

            'FailedAndSuspended' {
                'Red'
            }

            default {
                'Yellow'
            }

        }

        Write-Host ("DATABASE : {0}" -f $DatabaseName) -ForegroundColor Cyan
        Write-Host ("SERVER   : {0}" -f $ServerName)

        Write-Host "STATUS   : " -NoNewline
        Write-Host $Status -ForegroundColor $StatusColor

        Write-Host "CONTENT INDEX : " -NoNewline
        Write-Host $ContentIndexState -ForegroundColor $ContentIndexColor

        if ($Copy.PSObject.Properties.Name -contains 'CopyQueueLength') {
            Write-Host ("COPY QUEUE    : {0}" -f $Copy.CopyQueueLength)
        }

        if ($Copy.PSObject.Properties.Name -contains 'ReplayQueueLength') {
            Write-Host ("REPLAY QUEUE  : {0}" -f $Copy.ReplayQueueLength)
        }

        if ($Copy.PSObject.Properties.Name -contains 'ReplayLagTime') {
            Write-Host ("REPLAY LAG    : {0}" -f $Copy.ReplayLagTime)
        }

        if ($Copy.PSObject.Properties.Name -contains 'TruncationLagTime') {
            Write-Host ("TRUNC. LAG    : {0}" -f $Copy.TruncationLagTime)
        }

        if ($Copy.PSObject.Properties.Name -contains 'ActivationPreference') {
            Write-Host ("ACTIVATION PREF: {0}" -f $Copy.ActivationPreference)
        }

        if ($Copy.PSObject.Properties.Name -contains 'LastInspectedLogTime') {
            Write-Host ("LAST LOG CHECK : {0}" -f $Copy.LastInspectedLogTime)
        }

        if ($Copy.PSObject.Properties.Name -contains 'LastCopiedLogTime') {
            Write-Host ("LAST COPIED LOG: {0}" -f $Copy.LastCopiedLogTime)
        }

        if ($Copy.PSObject.Properties.Name -contains 'LastReplayedLogTime') {
            Write-Host ("LAST REPLAY LOG: {0}" -f $Copy.LastReplayedLogTime)
        }

        if (
            $ExtendedErrorInfo -and
            $Copy.PSObject.Properties.Name -contains 'ErrorMessage' -and
            -not [string]::IsNullOrWhiteSpace([string]$Copy.ErrorMessage)
        ) {

            Write-Host ""
            Write-Host "ERROR" -ForegroundColor Red
            Write-Host $Copy.ErrorMessage -ForegroundColor Yellow

        }

        Write-Host ""
        Write-Host "----------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""

    }

    $HealthyCount = @(
        $Copies | Where-Object {
            $_.Status -in @(
                'Mounted',
                'Healthy'
            )
        }
    ).Count

    $ProblemCount = $Copies.Count - $HealthyCount

    Write-Host "SUMMARY" -ForegroundColor DarkCyan
    Write-Host ("Total copies : {0}" -f $Copies.Count)
    Write-Host ("Healthy      : {0}" -f $HealthyCount) -ForegroundColor Green

    if ($ProblemCount -gt 0) {
        Write-Host ("Problems     : {0}" -f $ProblemCount) -ForegroundColor Red
    }
    else {
        Write-Host ("Problems     : {0}" -f $ProblemCount) -ForegroundColor Green
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}