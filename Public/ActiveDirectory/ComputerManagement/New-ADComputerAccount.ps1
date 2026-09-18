function New-ADComputerAccount {

    try {

        $Domain = Get-ADDomain -ErrorAction Stop

        # Default container for computer accounts
        $DefaultPath = $Domain.ComputersContainer

        Write-Host "`nCreate Computer Account" -ForegroundColor Cyan
        Write-Host "-----------------------" -ForegroundColor DarkCyan

        # Computer name
        $Name = Read-Host "Computer name"

        if ([string]::IsNullOrWhiteSpace($Name)) {

            Write-Host "`nComputer name cannot be empty." `
                -ForegroundColor Red

            return
        }

        # Normalize computer name
        $Name = $Name.Trim()

        # SamAccountName
        $SamAccountName = "$Name`$"

        # DNS hostname
        $DNSHostName = "$Name.$($Domain.DNSRoot)"

        # OU / Container
        $Path = Read-Host "OU [$DefaultPath]"

        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = $DefaultPath
        }

        # Validate OU / container
        try {

            Get-ADObject `
                -Identity $Path `
                -ErrorAction Stop |
                Out-Null
        }
        catch {

            Write-Host "`nOU or container not found: $Path" `
                -ForegroundColor Red

            return
        }

        # Check existing computer account
        $ExistingComputer = Get-ADComputer `
            -Identity $Name `
            -ErrorAction SilentlyContinue

        if ($ExistingComputer) {

            Write-Host "`nComputer '$Name' already exists." `
                -ForegroundColor Red

            return
        }

        # Summary
        Write-Host "`n----------------------------------------------"
        Write-Host "Computer Summary" -ForegroundColor Cyan
        Write-Host "----------------------------------------------"

        Write-Host "Name        : $Name"
        Write-Host "SAM Account : $SamAccountName"
        Write-Host "DNS Hostname: $DNSHostName"
        Write-Host "Path        : $Path"
        Write-Host "Status      : Enabled"

        Write-Host "----------------------------------------------"

        $Confirmation = Read-Host "Create computer account? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." `
                -ForegroundColor Yellow

            return
        }

        New-ADComputer `
            -Name $Name `
            -SamAccountName $SamAccountName `
            -DNSHostName $DNSHostName `
            -Path $Path `
            -Enabled $true `
            -ErrorAction Stop

        Write-Host "`nComputer account '$Name' created successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to create computer account." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}