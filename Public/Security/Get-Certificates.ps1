function Get-Certificates {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    $StoreInput = Read-Host "Enter certificate store [My]"
    if ([string]::IsNullOrWhiteSpace($StoreInput)) {
        $StoreInput = 'My'
    }

    $SubjectFilter = Read-Host "Enter subject filter [All]"

    try {
        if ($Context.IsRemote) {
            $Certificates = Invoke-Command `
                -ComputerName $Context.ComputerName `
                -ScriptBlock {
                    param(
                        $StoreName,
                        $SubjectFilter
                    )

                    $Path = "Cert:\LocalMachine\$StoreName"

                    if (-not (Test-Path $Path)) {
                        throw "Certificate store '$StoreName' does not exist."
                    }

                    Get-ChildItem `
                        -Path $Path `
                        -ErrorAction Stop |
                        Where-Object {
                            [string]::IsNullOrWhiteSpace($SubjectFilter) -or
                            $_.Subject -like "*$SubjectFilter*"
                        } |
                        Select-Object `
                            @{Name = 'Store'; Expression = {
                                $StoreName
                            }},
                            Subject,
                            Issuer,
                            Thumbprint,
                            NotBefore,
                            NotAfter,
                            HasPrivateKey,
                            FriendlyName
                } `
                -ArgumentList $StoreInput, $SubjectFilter `
                -ErrorAction Stop
        }
        else {
            $Path = "Cert:\LocalMachine\$StoreInput"

            if (-not (Test-Path $Path)) {
                throw "Certificate store '$StoreInput' does not exist."
            }

            $Certificates = Get-ChildItem `
                -Path $Path `
                -ErrorAction Stop |
                Where-Object {
                    [string]::IsNullOrWhiteSpace($SubjectFilter) -or
                    $_.Subject -like "*$SubjectFilter*"
                } |
                Select-Object `
                    @{Name = 'Store'; Expression = {
                        $StoreInput
                    }},
                    Subject,
                    Issuer,
                    Thumbprint,
                    NotBefore,
                    NotAfter,
                    HasPrivateKey,
                    FriendlyName
        }

        if ($null -eq $Certificates -or $Certificates.Count -eq 0) {
            Write-Host "`nNo certificates found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nCertificates" -ForegroundColor Cyan
        Write-Host "------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow
        Write-Host "Store : LocalMachine\$StoreInput"

        $Certificates |
            Sort-Object NotAfter |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve certificates from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}