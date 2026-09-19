function Get-PSFieldKitSession {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if ($Context.IsMultiTarget) {
        Write-Host "`nPSSession information is not available for multiple targets." -ForegroundColor Yellow
        return
    }

    if (-not $Context.IsRemote) {
        Write-Host "`nPSSession requires a remote target." -ForegroundColor Yellow
        return
    }

    if ($null -eq $Context.Session) {
        Write-Host "`nNo PSSession exists for $($Context.ComputerName)." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nPSSession Information" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan

        $Session = $Context.Session

        Write-Host "Computer Name : $($Session.ComputerName)"
        Write-Host "Session ID    : $($Session.Id)"
        Write-Host "State         : $($Session.State)"
        Write-Host "Name          : $($Session.Name)"
        Write-Host "Instance ID   : $($Session.InstanceId)"
        Write-Host "Configuration : $($Session.ConfigurationName)"
        Write-Host "Availability  : $($Session.Availability)"
        Write-Host "Transport     : $($Session.Transport)"
        Write-Host "Computer Type : $($Session.ComputerType)"
    }
    catch {
        Write-Host "`nFailed to retrieve PSSession information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}