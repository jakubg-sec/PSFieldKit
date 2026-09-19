function Get-PSFieldKitTargets {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('List', 'Range', 'CIDR', 'File')]
        [string]$Mode
    )

    switch ($Mode) {
        'List' {
            $InputValue = Read-Host "Enter computer names or IPs separated by commas"

            if ([string]::IsNullOrWhiteSpace($InputValue)) {
                Write-Host "`nTarget list cannot be empty." -ForegroundColor Red
                return
            }

            return @(
                $InputValue -split ',' |
                    ForEach-Object {
                        $_.Trim()
                    } |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace($_)
                    } |
                    Select-Object -Unique
            )
        }

        'Range' {
            $InputValue = Read-Host "Enter IPv4 range (example: 10.1.50.10-10.1.50.50)"

            if ($InputValue -notmatch '^\s*(\d{1,3}(?:\.\d{1,3}){3})\s*-\s*(\d{1,3}(?:\.\d{1,3}){3})\s*$') {
                Write-Host "`nInvalid IPv4 range." -ForegroundColor Red
                return
            }

            try {
                $StartIP = [System.Net.IPAddress]::Parse($Matches[1])
                $EndIP = [System.Net.IPAddress]::Parse($Matches[2])
            }
            catch {
                Write-Host "`nInvalid IPv4 address." -ForegroundColor Red
                return
            }

            if ($StartIP.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork -or
                $EndIP.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                Write-Host "`nOnly IPv4 addresses are supported." -ForegroundColor Red
                return
            }

            $StartBytes = $StartIP.GetAddressBytes()
            $EndBytes = $EndIP.GetAddressBytes()

            [uint32]$StartValue = (
                ([uint32]$StartBytes[0] -shl 24) -bor
                ([uint32]$StartBytes[1] -shl 16) -bor
                ([uint32]$StartBytes[2] -shl 8) -bor
                [uint32]$StartBytes[3]
            )

            [uint32]$EndValue = (
                ([uint32]$EndBytes[0] -shl 24) -bor
                ([uint32]$EndBytes[1] -shl 16) -bor
                ([uint32]$EndBytes[2] -shl 8) -bor
                [uint32]$EndBytes[3]
            )

            if ($StartValue -gt $EndValue) {
                Write-Host "`nStart address cannot be greater than end address." -ForegroundColor Red
                return
            }

            if (($EndValue - $StartValue + 1) -gt 4096) {
                Write-Host "`nThe selected range contains more than 4096 addresses." -ForegroundColor Red
                return
            }

            $Targets = foreach ($Value in $StartValue..$EndValue) {
                $Bytes = [BitConverter]::GetBytes([uint32]$Value)
                [Array]::Reverse($Bytes)
                ([System.Net.IPAddress]::new($Bytes)).ToString()
            }

            return @($Targets)
        }

        'CIDR' {
            $InputValue = Read-Host "Enter IPv4 network (example: 10.1.50.0/24)"

            if ($InputValue -notmatch '^\s*(\d{1,3}(?:\.\d{1,3}){3})\/(\d{1,2})\s*$') {
                Write-Host "`nInvalid CIDR notation." -ForegroundColor Red
                return
            }

            try {
                $NetworkIP = [System.Net.IPAddress]::Parse($Matches[1])
                $PrefixLength = [int]$Matches[2]
            }
            catch {
                Write-Host "`nInvalid IPv4 address." -ForegroundColor Red
                return
            }

            if ($NetworkIP.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                Write-Host "`nOnly IPv4 networks are supported." -ForegroundColor Red
                return
            }

            if ($PrefixLength -lt 1 -or $PrefixLength -gt 32) {
                Write-Host "`nPrefix length must be between 1 and 32." -ForegroundColor Red
                return
            }

            $HostCount = [math]::Pow(2, 32 - $PrefixLength)

            if ($HostCount -gt 4096) {
                Write-Host "`nThe selected network contains more than 4096 addresses." -ForegroundColor Red
                return
            }

            $NetworkBytes = $NetworkIP.GetAddressBytes()

            [uint32]$NetworkValue = (
                ([uint32]$NetworkBytes[0] -shl 24) -bor
                ([uint32]$NetworkBytes[1] -shl 16) -bor
                ([uint32]$NetworkBytes[2] -shl 8) -bor
                [uint32]$NetworkBytes[3]
            )

            [uint32]$Mask = if ($PrefixLength -eq 32) {
                [uint32]0xFFFFFFFF
            }
            else {
                [uint32]([uint64]0xFFFFFFFF -shl (32 - $PrefixLength))
            }

            [uint32]$NetworkAddress = $NetworkValue -band $Mask

            $Targets = foreach ($Offset in 0..([int]$HostCount - 1)) {
                [uint32]$Value = $NetworkAddress + $Offset

                $Bytes = [BitConverter]::GetBytes($Value)
                [Array]::Reverse($Bytes)
                ([System.Net.IPAddress]::new($Bytes)).ToString()
            }

            return @($Targets)
        }

        'File' {
            $FilePath = Read-Host "Enter path to target file"

            if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
                Write-Host "`nTarget file was not found." -ForegroundColor Red
                return
            }

            try {
                $Targets = Get-Content -LiteralPath $FilePath -ErrorAction Stop |
                    ForEach-Object {
                        $_.Trim()
                    } |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace($_) -and
                        -not $_.StartsWith('#')
                    } |
                    Select-Object -Unique

                if ($Targets.Count -gt 4096) {
                    Write-Host "`nThe target file contains more than 4096 entries." -ForegroundColor Red
                    return
                }

                return @($Targets)
            }
            catch {
                Write-Host "`nFailed to read target file." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Yellow
                return
            }
        }
    }
}