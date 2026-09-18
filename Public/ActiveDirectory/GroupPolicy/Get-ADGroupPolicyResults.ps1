function Get-ADGroupPolicyResults {

    Write-Host "`nEnter target information."
    Write-Host "Leave a field empty when not needed."

    $ComputerName = Read-Host "Computer name"
    $UserName = Read-Host "User name"

    if (
        [string]::IsNullOrWhiteSpace($ComputerName) -and
        [string]::IsNullOrWhiteSpace($UserName)
    ) {

        Write-Host "`nAt least Computer or User must be specified." `
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

        $TargetName = if ($ComputerName -and $UserName) {

            "$ComputerName-$UserName"
        }
        elseif ($ComputerName) {

            $ComputerName
        }
        else {

            $UserName
        }

        $SafeName = $TargetName -replace '[\\/:*?"<>|]', '_'

        $ReportPath = Join-Path `
            -Path $ReportDirectory `
            -ChildPath "RSoP-$SafeName.$Extension"

        $Parameters = @{
            ReportType = $ReportType
            Path       = $ReportPath
            ErrorAction = 'Stop'
        }

        if ($ComputerName) {

            $Parameters.Computer = $ComputerName
        }

        if ($UserName) {

            $Parameters.User = $UserName
        }

        $Result = Get-GPResultantSetOfPolicy @Parameters

        Write-Host "`nGroup Policy Results generated successfully." `
            -ForegroundColor Green

        Write-Host "Report type : $ReportType"
        Write-Host "Path        : $ReportPath"

        if ($Result) {

            Write-Host "`nRSoP Information" `
                -ForegroundColor Cyan

            $Result |
                Format-List
        }
    }
    catch {

        Write-Host "`nFailed to generate Group Policy Results." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}