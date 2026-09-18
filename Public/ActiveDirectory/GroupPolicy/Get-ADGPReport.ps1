function Get-ADGPReport {

    $Identity = Read-Host "Enter GPO name or GUID"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nGPO identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    Write-Host "`nSelect report format"
    Write-Host "[1] HTML"
    Write-Host "[2] XML"

    $FormatChoice = Read-Host "`nSelect option"

    switch ($FormatChoice) {

        '1' {
            $ReportType = 'HTML'
            $Extension = 'html'
        }

        '2' {
            $ReportType = 'XML'
            $Extension = 'xml'
        }

        default {

            Write-Host "`nInvalid option." `
                -ForegroundColor Red

            return
        }
    }

    try {

        $Guid = [Guid]::Empty

        if ([Guid]::TryParse($Identity, [ref]$Guid)) {

            $GPO = Get-GPO `
                -Guid $Guid `
                -ErrorAction Stop
        }
        else {

            $GPO = Get-GPO `
                -Name $Identity `
                -ErrorAction Stop
        }

        $ReportDirectory = Join-Path `
            -Path $env:TEMP `
            -ChildPath 'PSFieldKit\GPOReports'

        if (-not (Test-Path $ReportDirectory)) {

            New-Item `
                -Path $ReportDirectory `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        $SafeName = $GPO.DisplayName -replace '[\\/:*?"<>|]', '_'

        $ReportPath = Join-Path `
            -Path $ReportDirectory `
            -ChildPath "$SafeName.$Extension"

        Get-GPOReport `
            -Guid $GPO.Id `
            -ReportType $ReportType `
            -Path $ReportPath `
            -ErrorAction Stop

        Write-Host "`nGPO report generated successfully." `
            -ForegroundColor Green

        Write-Host "GPO      : $($GPO.DisplayName)"
        Write-Host "Format   : $ReportType"
        Write-Host "Path     : $ReportPath"
    }
    catch {

        Write-Host "`nFailed to generate GPO report." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}