function Invoke-PSFieldKitCommand {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $Command = Read-Host "Enter PowerShell command"

    if ([string]::IsNullOrWhiteSpace($Command)) {
        Write-Host "`nCommand cannot be empty." -ForegroundColor Red
        return
    }

    try {
        Write-Host "`nRemote Command Execution" -ForegroundColor Cyan
        Write-Host "------------------------" -ForegroundColor DarkCyan

        $ScriptBlock = [scriptblock]::Create($Command)

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow
            Write-Host "Command: $Command" -ForegroundColor DarkGray
            Write-Host

            try {
                $Result = Invoke-Command `
                    -ComputerName $Target.ComputerName `
                    -ScriptBlock $ScriptBlock `
                    -ErrorAction Stop

                if ($null -ne $Result) {
                    $Result | Out-Host
                }

                Write-Host "`nCommand completed successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Command failed." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to execute remote command." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}