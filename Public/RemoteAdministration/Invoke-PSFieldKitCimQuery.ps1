function Invoke-PSFieldKitCimQuery {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $Namespace = Read-Host "Enter CIM namespace (default: root/cimv2)"

    if ([string]::IsNullOrWhiteSpace($Namespace)) {
        $Namespace = 'root/cimv2'
    }

    $ClassName = Read-Host "Enter CIM class name"

    if ([string]::IsNullOrWhiteSpace($ClassName)) {
        Write-Host "`nCIM class name cannot be empty." -ForegroundColor Red
        return
    }

    $Filter = Read-Host "Enter WQL filter (optional)"

    try {
        Write-Host "`nCIM / WMI Remote Query" -ForegroundColor Cyan
        Write-Host "----------------------" -ForegroundColor DarkCyan

        Write-Host "Namespace : $Namespace"
        Write-Host "Class     : $ClassName"

        if (-not [string]::IsNullOrWhiteSpace($Filter)) {
            Write-Host "Filter    : $Filter"
        }

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            $Session = New-CimSession `
                -ComputerName $Target.ComputerName `
                -ErrorAction Stop

            try {
                $Parameters = @{
                    Namespace   = $Namespace
                    ClassName   = $ClassName
                    CimSession  = $Session
                    ErrorAction = 'Stop'
                }

                if (-not [string]::IsNullOrWhiteSpace($Filter)) {
                    $Parameters.Filter = $Filter
                }

                $Results = Get-CimInstance @Parameters

                if ($null -eq $Results) {
                    Write-Host "No results found." -ForegroundColor Yellow
                    continue
                }

                $Results | Format-Table -AutoSize
            }
            finally {
                Remove-CimSession $Session
            }
        }
    }
    catch {
        Write-Host "`nFailed to execute CIM query." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}