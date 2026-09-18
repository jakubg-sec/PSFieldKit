function Test-ADDomainControllerConnectivity {

    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nDomain controller name cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $HostName = $DC.HostName
        $IPv4Address = $DC.IPv4Address

        Write-Host "`nDomain Controller Connectivity" -ForegroundColor Cyan
        Write-Host "------------------------------" -ForegroundColor DarkCyan
        Write-Host "DC   : $HostName"
        Write-Host "IPv4 : $IPv4Address"
        Write-Host ""

        # DNS
        $DNS = $false

        try {
            Resolve-DnsName `
                -Name $HostName `
                -ErrorAction Stop |
                Out-Null

            $DNS = $true
        }
        catch {
        }

        # Ping
        $Ping = Test-Connection `
            -ComputerName $HostName `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue

        # TCP test helper
        function Test-TCPPort {
            param(
                [string]$ComputerName,
                [int]$Port,
                [int]$Timeout = 1500
            )

            try {

                $Client = New-Object System.Net.Sockets.TcpClient

                $AsyncResult = $Client.BeginConnect(
                    $ComputerName,
                    $Port,
                    $null,
                    $null
                )

                $Success = $AsyncResult.AsyncWaitHandle.WaitOne($Timeout)

                if ($Success -and $Client.Connected) {
                    $Client.EndConnect($AsyncResult)
                    $Client.Close()
                    return $true
                }

                $Client.Close()
                return $false
            }
            catch {
                return $false
            }
        }

        $Ports = @(
            @{ Name = 'DNS';      Port = 53   }
            @{ Name = 'Kerberos'; Port = 88   }
            @{ Name = 'RPC';      Port = 135  }
            @{ Name = 'LDAP';     Port = 389  }
            @{ Name = 'SMB';      Port = 445  }
            @{ Name = 'GC';       Port = 3268 }
            @{ Name = 'WinRM';    Port = 5985 }
        )

        $Results = foreach ($Service in $Ports) {

            [PSCustomObject]@{
                Service = $Service.Name
                Port    = $Service.Port
                Status  = if (
                    Test-TCPPort `
                        -ComputerName $HostName `
                        -Port $Service.Port
                ) {
                    'OPEN'
                }
                else {
                    'CLOSED'
                }
            }
        }

        [PSCustomObject]@{
            Test   = 'DNS'
            Status = if ($DNS) { 'PASS' } else { 'FAIL' }
        }

        [PSCustomObject]@{
            Test   = 'Ping'
            Status = if ($Ping) { 'PASS' } else { 'FAIL' }
        }

        Write-Host "`nService Connectivity" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        $Results |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to test domain controller connectivity." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}