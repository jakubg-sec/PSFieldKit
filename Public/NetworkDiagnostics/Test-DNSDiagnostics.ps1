function Test-DNSDiagnostics {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        $Query = Read-Host "Enter hostname or domain to resolve"

        if ([string]::IsNullOrWhiteSpace($Query)) {
            Write-Host "`nHostname cannot be empty." -ForegroundColor Red
            return
        }

        if ($Context.IsRemote) {

            $Result = Invoke-Command `
                -ComputerName $Context.ComputerName `
                -ScriptBlock {

                    param($Query)

                    $DNSConfiguration = Get-DnsClientServerAddress `
                        -AddressFamily IPv4 |
                        Where-Object {
                            $_.ServerAddresses.Count -gt 0
                        }

                    $SearchSuffix = Get-DnsClientGlobalSetting

                    $DNSResult = Resolve-DnsName `
                        -Name $Query `
                        -ErrorAction Stop

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        Query        = $Query
                        DNSServers   = @(
                            $DNSConfiguration.ServerAddresses
                        ) -join ', '
                        Suffix       = @(
                            $SearchSuffix.SuffixSearchList
                        ) -join ', '
                        Result       = @(
                            $DNSResult |
                            Where-Object {
                                $_.Type -in @('A', 'AAAA')
                            } |
                            Select-Object -ExpandProperty IPAddress
                        ) -join ', '
                    }

                } `
                -ArgumentList $Query `
                -ErrorAction Stop
        }
        else {

            $DNSConfiguration = Get-DnsClientServerAddress `
                -AddressFamily IPv4 |
                Where-Object {
                    $_.ServerAddresses.Count -gt 0
                }

            $SearchSuffix = Get-DnsClientGlobalSetting

            $DNSResult = Resolve-DnsName `
                -Name $Query `
                -ErrorAction Stop

            $Result = [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                Query        = $Query
                DNSServers   = @(
                    $DNSConfiguration.ServerAddresses
                ) -join ', '
                Suffix       = @(
                    $SearchSuffix.SuffixSearchList
                ) -join ', '
                Result       = @(
                    $DNSResult |
                    Where-Object {
                        $_.Type -in @('A', 'AAAA')
                    } |
                    Select-Object -ExpandProperty IPAddress
                ) -join ', '
            }
        }

        Write-Host "`nDNS Diagnostics" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan

        $Result | Format-List
    }
    catch {

        Write-Host "`nDNS query failed on $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}