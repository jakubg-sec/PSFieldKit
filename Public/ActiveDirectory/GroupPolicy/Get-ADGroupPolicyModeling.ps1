function Get-ADGroupPolicyModeling {

    Write-Host "`nGroup Policy Modeling" -ForegroundColor Cyan
    Write-Host "---------------------" -ForegroundColor DarkCyan

    Write-Host "`nGroup Policy Modeling is performed using GPMC."
    Write-Host "Launching Group Policy Management Console..." `
        -ForegroundColor Yellow

    try {

        Start-Process `
            -FilePath "gpmc.msc" `
            -ErrorAction Stop

        Write-Host "`nGPMC started successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nUnable to start GPMC." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}