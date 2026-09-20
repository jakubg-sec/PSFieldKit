function Connect-PSFieldKitExchangeServer {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerFQDN
    )

    $Session = $null
    $ImportedModule = $null

    try {

        Write-Host ""
        Write-Host "Connecting to Exchange server..." -ForegroundColor Cyan
        Write-Host "Server : $ServerFQDN" -ForegroundColor White
        Write-Host "Auth   : Kerberos" -ForegroundColor DarkGray
        Write-Host ""

        $ExistingSession = @(
            Get-PSSession |
                Where-Object {
                    $_.ConfigurationName -eq "Microsoft.Exchange" -and
                    $_.ComputerName -eq $ServerFQDN -and
                    $_.State -eq "Opened"
                }
        )

        if ($ExistingSession.Count -gt 0) {

            $Session = $ExistingSession[0]

            Write-Host "Existing Exchange session found." -ForegroundColor Green
        }
        else {

            $ConnectionUri = "http://$ServerFQDN/PowerShell/"

            $SessionParameters = @{
                ConfigurationName = "Microsoft.Exchange"
                ConnectionUri     = $ConnectionUri
                Authentication    = "Kerberos"
                ErrorAction       = "Stop"
            }

            Write-Host "Creating Exchange PowerShell session..." -ForegroundColor Yellow

            $Session = New-PSSession @SessionParameters

            Write-Host "Remote session created." -ForegroundColor Green
        }

        if ($null -eq $Session) {
            throw "Exchange PowerShell session could not be created."
        }

        if ($Session.State -ne "Opened") {
            throw "Exchange PowerShell session is not in the Opened state. Current state: $($Session.State)"
        }

        Write-Host "Importing Exchange cmdlets..." -ForegroundColor Yellow

        $ImportedModule = Import-PSSession `
            -Session $Session `
            -DisableNameChecking `
            -ErrorAction Stop

        if ($null -eq $ImportedModule) {
            throw "Exchange cmdlets could not be imported."
        }

        Write-Host "Exchange cmdlets imported successfully." -ForegroundColor Green

        $GetMailboxCommand = Get-Command `
            -Name "Get-Mailbox" `
            -ErrorAction SilentlyContinue

        if ($null -eq $GetMailboxCommand) {
            throw "Exchange cmdlet 'Get-Mailbox' is not available after importing the session."
        }

        Write-Host "Exchange connection verified successfully." -ForegroundColor Green

        return [PSCustomObject]@{
            ServerName     = $ServerFQDN.Split(".")[0]
            ServerFQDN     = $ServerFQDN
            ConnectionUri  = "http://$ServerFQDN/PowerShell/"
            Authentication = "Kerberos"
            Session        = $Session
            ImportedModule = $ImportedModule
            Connected      = $true
            ConnectedAt    = Get-Date
        }
    }
    catch {

        Write-Host ""
        Write-Host "Failed to connect to Exchange server." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        if ($null -ne $Session) {

            try {
                Remove-PSSession -Session $Session -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose $_.Exception.Message
            }
        }

        return $null
    }
}