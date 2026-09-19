function Get-AuditPolicy {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    try {
        if ($Context.IsRemote) {
            $AuditPolicy = Invoke-Command `
                -ComputerName $Context.ComputerName `
                -ScriptBlock {
                    auditpol.exe /get /category:* /r 2>&1
                } `
                -ErrorAction Stop
        }
        else {
            $AuditPolicy = auditpol.exe /get /category:* /r 2>&1

            if ($LASTEXITCODE -ne 0) {
                throw ($AuditPolicy -join "`n")
            }
        }

        if ($null -eq $AuditPolicy -or $AuditPolicy.Count -eq 0) {
            Write-Host "`nNo audit policy information found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nAudit Policy" -ForegroundColor Cyan
        Write-Host "------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        $AuditPolicy |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            ForEach-Object {
                Write-Host $_
            }
    }
    catch {
        Write-Host "`nFailed to retrieve audit policy from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}