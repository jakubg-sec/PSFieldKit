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
                    ForEach-Object { $_.Trim() } |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                    Select-Object -Unique
            )
        }

        'Range' {
            $InputValue = Read-Host "Enter IPv4 range (example: 192.168.1.10-192.168.1.50)"

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

            [uint64]$StartValue = (
                ([uint64]$StartBytes[0] * 16777216) +
                ([uint64]$StartBytes[1] * 65536) +
                ([uint64]$StartBytes[2] * 256) +
                [uint64]$StartBytes[3]
            )

            [uint64]$EndValue = (
                ([uint64]$EndBytes[0] * 16777216) +
                ([uint64]$EndBytes[1] * 65536) +
                ([uint64]$EndBytes[2] * 256) +
                [uint64]$EndBytes[3]
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
                $Byte0 = [byte][math]::Floor($Value / 16777216)
                $Remaining = $Value % 16777216
                $Byte1 = [byte][math]::Floor($Remaining / 65536)
                $Remaining = $Remaining % 65536
                $Byte2 = [byte][math]::Floor($Remaining / 256)
                $Byte3 = [byte]($Remaining % 256)

                "{0}.{1}.{2}.{3}" -f $Byte0, $Byte1, $Byte2, $Byte3
            }

            return @($Targets)
        }

        'CIDR' {
            $InputValue = Read-Host "Enter IPv4 network (example: 192.168.1.0/24)"

            if ($InputValue -notmatch '^\s*(\d{1,3}(?:\.\d{1,3}){3})/(\d{1,2})\s*$') {
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

            [uint64]$AddressCount = [math]::Pow(2, 32 - $PrefixLength)

            if ($AddressCount -gt 4096) {
                Write-Host "`nThe selected network contains more than 4096 addresses." -ForegroundColor Red
                return
            }

            $NetworkBytes = $NetworkIP.GetAddressBytes()

            [uint64]$NetworkValue = (
                ([uint64]$NetworkBytes[0] * 16777216) +
                ([uint64]$NetworkBytes[1] * 65536) +
                ([uint64]$NetworkBytes[2] * 256) +
                [uint64]$NetworkBytes[3]
            )

            [uint64]$MaskValue = [math]::Pow(2, 32) - [math]::Pow(2, 32 - $PrefixLength)
            [uint64]$NetworkAddress = $NetworkValue -band $MaskValue

            if ($PrefixLength -lt 31) {
                [uint64]$FirstHost = $NetworkAddress + 1
                [uint64]$LastHost = $NetworkAddress + $AddressCount - 2
            }
            else {
                [uint64]$FirstHost = $NetworkAddress
                [uint64]$LastHost = $NetworkAddress + $AddressCount - 1
            }

            $Targets = foreach ($Value in $FirstHost..$LastHost) {
                $Byte0 = [byte][math]::Floor($Value / 16777216)
                $Remaining = $Value % 16777216
                $Byte1 = [byte][math]::Floor($Remaining / 65536)
                $Remaining = $Remaining % 65536
                $Byte2 = [byte][math]::Floor($Remaining / 256)
                $Byte3 = [byte]($Remaining % 256)

                "{0}.{1}.{2}.{3}" -f $Byte0, $Byte1, $Byte2, $Byte3
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
                    ForEach-Object { $_.Trim() } |
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