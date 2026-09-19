function Enter-PSFieldKitRemotePowerShell {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if ($Context.IsMultiTarget) {
        Write-Host "`nInteractive Remote PowerShell is not available for multiple targets." `
            -ForegroundColor Yellow
        return
    }

    if (-not $Context.IsRemote) {
        Write-Host "`nInteractive Remote PowerShell requires a remote target." `
            -ForegroundColor Yellow
        return
    }

    try {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            $ShellPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
        }
        else {
            $ShellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        }

        $ComputerName = $Context.ComputerName.Replace("'", "''")

        Write-Host "`nOpening Remote PowerShell on $($Context.ComputerName)..." `
            -ForegroundColor Cyan

        Start-Process `
            -FilePath $ShellPath `
            -ArgumentList @(
                '-NoLogo'
                '-NoProfile'
                '-NoExit'
                '-Command'
                "Enter-PSSession -ComputerName '$ComputerName'"
            ) `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to open Remote PowerShell on $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}