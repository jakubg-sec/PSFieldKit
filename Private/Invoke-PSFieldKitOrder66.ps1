function Invoke-PSFieldKitOrder66 {
    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkRed
    Write-Host "|               ORDER 66 EXECUTED              |" -ForegroundColor Red
    Write-Host "|                  PSFieldKit                  |" -ForegroundColor Red
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkRed
    Write-Host

    Write-Host "Executing administrative purge..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 1000

    Write-Host "Disabling Jedi protections..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 1000

    Write-Host "Searching for Windows.exe..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 1000

    Write-Host
    Write-Host "ERROR: Windows.exe not found." -ForegroundColor Red
    Write-Host
    Start-Sleep -Milliseconds 1000

    Write-Host "Order 66 has been cancelled." -ForegroundColor Green
    Write-Host "The Republic is safe. For now." -ForegroundColor DarkGray
    Write-Host
    Start-Sleep -Milliseconds 1000
    
    Write-Host "Preparing emergency hyperspace jump..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 700

    for ($Seconds = 3; $Seconds -gt 0; $Seconds--) {
        Write-Host "`rEntering hyperspace in $Seconds..." `
            -NoNewline `
            -ForegroundColor Cyan

        Start-Sleep -Seconds 1
    }

    Write-Host "`rJumping to hyperspace...                " `
        -ForegroundColor Magenta

    Start-Sleep -Milliseconds 500

    for ($i = 0; $i -lt 3; $i++) {
        Write-Host "." -NoNewline -ForegroundColor Magenta
        Start-Sleep -Milliseconds 300
    }

    Write-Host
    Start-Sleep -Milliseconds 500

    Write-Host "Hyperspace jump complete." -ForegroundColor Green
    Start-Sleep -Milliseconds 700
}