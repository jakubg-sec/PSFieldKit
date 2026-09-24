function Get-PSFieldKitExchangeDatabaseCopy {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$Server,

        [Parameter()]
        [switch]$Active,

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

    if (-not [string]::IsNullOrWhiteSpace($Identity) -and
        -not [string]::IsNullOrWhiteSpace($Server)) {

        Write-Host "`nIdentity and Server cannot be used together." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ($Local -and
        (-not [string]::IsNullOrWhiteSpace($Server))) {

        Write-Host "`nLocal and Server cannot be used together." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nRetrieving mailbox database copies..." -ForegroundColor Yellow

        $CopyStatusParameters = @{
            ErrorAction = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($Identity)) {
            $CopyStatusParameters['Identity'] = $Identity
        }

        if (-not [string]::IsNullOrWhiteSpace($Server)) {
            $CopyStatusParameters['Server'] = $Server
        }

        if ($Active) {
            $CopyStatusParameters['Active'] = $true
        }

        if ($Local) {
            $CopyStatusParameters['Local'] = $true
        }

        if ($ExtendedErrorInfo) {
            $CopyStatusParameters['ExtendedErrorInfo'] = $true
        }

        $Copies = @(
            Get-MailboxDatabaseCopyStatus @CopyStatusParameters |
                Sort-Object DatabaseName, MailboxServerName
        )

    }
    catch {

        Write-Host "`nFailed to retrieve mailbox database copies." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             Mailbox Database Copies          |" -ForegroundColor Cyan
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
        Write-Host "|  Scope    : Organization                     |"
    }

    Write-Host ("|  Copies   : {0,-33}|" -f $Copies.Count)

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($Copies.Count -eq 0) {

        Write-Host "`nNo mailbox database copies were found." -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    Write-Host "`nDATABASE COPIES" -ForegroundColor DarkCyan
    Write-Host ""

    $Copies |
        Select-Object `
            @{Name = 'Database'; Expression = {
                if ($_.PSObject.Properties.Name -contains 'DatabaseName') {
                    $_.DatabaseName
                }
                else {
                    $_.Identity.ToString().Split('\')[0]
                }
            }},
            @{Name = 'Server'; Expression = {
                if ($_.PSObject.Properties.Name -contains 'MailboxServerName') {
                    $_.MailboxServerName
                }
                elseif ($_.PSObject.Properties.Name -contains 'Server') {
                    $_.Server
                }
                else {
                    $_.Identity.ToString().Split('\')[-1]
                }
            }},
            Status,
            ContentIndexState,
            CopyQueueLength,
            ReplayQueueLength,
            ActivationPreference |
        Format-Table -AutoSize |
        Out-Host

    Write-Host ""
    Write-Host "STATUS SUMMARY" -ForegroundColor DarkCyan

    $Copies |
        Group-Object Status |
        Sort-Object Name |
        ForEach-Object {

            Write-Host ("{0,-20} : {1}" -f $_.Name, $_.Count)

        }

    Write-Host ""

    $UnhealthyCopies = @(
        $Copies | Where-Object {
            $_.Status -notin @(
                'Mounted',
                'Healthy'
            )
        }
    )

    if ($UnhealthyCopies.Count -gt 0) {

        Write-Host "WARNING" -ForegroundColor Yellow
        Write-Host "$($UnhealthyCopies.Count) database copy/copies have a non-standard status." -ForegroundColor Yellow

    }
    else {

        Write-Host "All returned database copies report a normal status." -ForegroundColor Green

    }

    Read-Host "`nPress Enter to continue" | Out-Null
}