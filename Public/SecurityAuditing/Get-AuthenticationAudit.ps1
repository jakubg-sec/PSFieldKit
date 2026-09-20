function Get-AuthenticationAudit {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $HoursInput = Read-Host "Enter analysis window in hours (default: 24)"

    if ([string]::IsNullOrWhiteSpace($HoursInput)) {
        $Hours = 24
    }
    elseif (-not [int]::TryParse($HoursInput, [ref]$Hours)) {
        Write-Host "`nInvalid number of hours." -ForegroundColor Red
        return
    }
    elseif ($Hours -lt 1 -or $Hours -gt 720) {
        Write-Host "`nAnalysis window must be between 1 and 720 hours." -ForegroundColor Red
        return
    }

    $ScriptBlock = {

        param(
            [int]$Hours
        )

        $Since = (Get-Date).AddHours(-$Hours)

        function Get-EvtDataValue {

            param(
                [Parameter(Mandatory)]
                [System.Diagnostics.Eventing.Reader.EventRecord]$Evt,

                [Parameter(Mandatory)]
                [string]$Name
            )

            $EvtXml = [xml]$Evt.ToXml()

            $Node = $EvtXml.Event.EventData.Data |
                Where-Object {
                    $_.Name -eq $Name
                } |
                Select-Object -First 1

            if ($Node) {
                return [string]$Node.'#text'
            }

            return 'Unknown'
        }

        $Evts = @(
            Get-WinEvent `
                -FilterHashtable @{
                    LogName   = 'Security'
                    StartTime = $Since
                    Id        = 4624, 4625, 4634, 4647, 4740, 4771, 4776
                } `
                -MaxEvents 10000 `
                -ErrorAction SilentlyContinue
        )

        #
        # Do NOT return an indexed Hashtable/OrderedDictionary here.
        # Invoke-Command serializes it and numeric indexing such as [4624]
        # may fail on the client side.
        #

        $Event4624Count = 0
        $Event4625Count = 0
        $Event4634Count = 0
        $Event4647Count = 0
        $Event4740Count = 0
        $Event4771Count = 0
        $Event4776Count = 0

        foreach ($Evt in $Evts) {

            switch ($Evt.Id) {

                4624 {
                    $Event4624Count++
                }

                4625 {
                    $Event4625Count++
                }

                4634 {
                    $Event4634Count++
                }

                4647 {
                    $Event4647Count++
                }

                4740 {
                    $Event4740Count++
                }

                4771 {
                    $Event4771Count++
                }

                4776 {
                    $Event4776Count++
                }
            }
        }

        $LogonTypes = [ordered]@{
            2  = 'Interactive'
            3  = 'Network'
            4  = 'Batch'
            5  = 'Service'
            7  = 'Unlock'
            8  = 'NetworkCleartext'
            9  = 'NewCredentials'
            10 = 'RemoteInteractive'
            11 = 'CachedInteractive'
        }

        $SuccessfulLogons = @(
            foreach ($Evt in $Evts | Where-Object {
                $_.Id -eq 4624
            }) {

                $UserName = Get-EvtDataValue -Evt $Evt -Name 'TargetUserName'
                $Domain = Get-EvtDataValue -Evt $Evt -Name 'TargetDomainName'
                $LogonTypeId = Get-EvtDataValue -Evt $Evt -Name 'LogonType'
                $SourceIP = Get-EvtDataValue -Evt $Evt -Name 'IpAddress'
                $Workstation = Get-EvtDataValue -Evt $Evt -Name 'WorkstationName'

                $LogonType = 'Unknown'

                if ($LogonTypeId -match '^\d+$') {

                    $LogonTypeNumber = [int]$LogonTypeId

                    if ($LogonTypes.Contains($LogonTypeNumber)) {
                        $LogonType = "$LogonTypeNumber - $($LogonTypes[$LogonTypeNumber])"
                    }
                    else {
                        $LogonType = "$LogonTypeNumber - Unknown"
                    }
                }

                [PSCustomObject]@{
                    Time        = $Evt.TimeCreated
                    User        = "$Domain\$UserName"
                    LogonType   = $LogonType
                    SourceIP    = $SourceIP
                    Workstation = $Workstation
                }
            }
        )

        $FailedLogons = @(
            foreach ($Evt in $Evts | Where-Object {
                $_.Id -eq 4625
            }) {

                $UserName = Get-EvtDataValue -Evt $Evt -Name 'TargetUserName'
                $Domain = Get-EvtDataValue -Evt $Evt -Name 'TargetDomainName'
                $LogonTypeId = Get-EvtDataValue -Evt $Evt -Name 'LogonType'
                $SourceIP = Get-EvtDataValue -Evt $Evt -Name 'IpAddress'
                $Status = Get-EvtDataValue -Evt $Evt -Name 'Status'
                $SubStatus = Get-EvtDataValue -Evt $Evt -Name 'SubStatus'

                $LogonType = 'Unknown'

                if ($LogonTypeId -match '^\d+$') {

                    $LogonTypeNumber = [int]$LogonTypeId

                    if ($LogonTypes.Contains($LogonTypeNumber)) {
                        $LogonType = "$LogonTypeNumber - $($LogonTypes[$LogonTypeNumber])"
                    }
                    else {
                        $LogonType = "$LogonTypeNumber - Unknown"
                    }
                }

                [PSCustomObject]@{
                    Time      = $Evt.TimeCreated
                    User      = "$Domain\$UserName"
                    LogonType = $LogonType
                    SourceIP  = $SourceIP
                    Status    = $Status
                    SubStatus = $SubStatus
                }
            }
        )

        $Lockouts = @(
            foreach ($Evt in $Evts | Where-Object {
                $_.Id -eq 4740
            }) {

                $UserName = Get-EvtDataValue -Evt $Evt -Name 'TargetUserName'
                $CallerComputer = Get-EvtDataValue -Evt $Evt -Name 'CallerComputerName'

                [PSCustomObject]@{
                    Time           = $Evt.TimeCreated
                    User           = $UserName
                    CallerComputer = $CallerComputer
                }
            }
        )

        $KerberosFailures = @(
            foreach ($Evt in $Evts | Where-Object {
                $_.Id -eq 4771
            }) {

                $UserName = Get-EvtDataValue -Evt $Evt -Name 'TargetUserName'
                $ClientAddress = Get-EvtDataValue -Evt $Evt -Name 'IpAddress'
                $Status = Get-EvtDataValue -Evt $Evt -Name 'Status'

                [PSCustomObject]@{
                    Time          = $Evt.TimeCreated
                    User          = $UserName
                    ClientAddress = $ClientAddress
                    Status        = $Status
                }
            }
        )

        $NTLMFailures = @(
            foreach ($Evt in $Evts | Where-Object {
                $_.Id -eq 4776
            }) {

                $UserName = Get-EvtDataValue -Evt $Evt -Name 'TargetUserName'
                $SourceWorkstation = Get-EvtDataValue -Evt $Evt -Name 'Workstation'
                $Status = Get-EvtDataValue -Evt $Evt -Name 'Status'

                [PSCustomObject]@{
                    Time              = $Evt.TimeCreated
                    User              = $UserName
                    SourceWorkstation = $SourceWorkstation
                    Status            = $Status
                }
            }
        )

        $FailedBySource = @(
            $FailedLogons |
                Where-Object {
                    $_.SourceIP -notin @(
                        '',
                        '-',
                        'Unknown',
                        '::1',
                        '127.0.0.1'
                    )
                } |
                Group-Object SourceIP |
                Sort-Object Count -Descending |
                Select-Object `
                    @{Name = 'SourceIP'; Expression = { $_.Name }},
                    Count
        )

        $FailedByUser = @(
            $FailedLogons |
                Group-Object User |
                Sort-Object Count -Descending |
                Select-Object `
                    @{Name = 'User'; Expression = { $_.Name }},
                    Count
        )

        #
        # Return plain properties instead of an indexed dictionary.
        # This survives PowerShell remoting correctly.
        #

        [PSCustomObject]@{

            Event4624SuccessfulLogons = $Event4624Count
            Event4625FailedLogons      = $Event4625Count
            Event4634Logoffs           = $Event4634Count
            Event4647UserLogoffs       = $Event4647Count
            Event4740Lockouts          = $Event4740Count
            Event4771KerberosFailures  = $Event4771Count
            Event4776NTLMFailures     = $Event4776Count

            SuccessfulLogons = $SuccessfulLogons
            FailedLogons     = $FailedLogons
            Lockouts         = $Lockouts
            KerberosFailures = $KerberosFailures
            NTLMFailures     = $NTLMFailures
            FailedBySource   = $FailedBySource
            FailedByUser     = $FailedByUser
        }
    }

    try {

        Write-Host "`nAuthentication Audit" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan
        Write-Host "Analysis window: $Hours hour(s)" -ForegroundColor DarkGray

        foreach ($Target in $Context.Targets) {

            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {

                if ($Target.IsRemote) {

                    $Result = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ArgumentList $Hours `
                        -ErrorAction Stop
                }
                else {

                    $Result = & $ScriptBlock $Hours
                }

                Write-Host "`nAuthentication Summary" -ForegroundColor Cyan
                Write-Host "---------------------" -ForegroundColor DarkCyan

                Write-Host "4624 Successful Logons          : $($Result.Event4624SuccessfulLogons)"
                Write-Host "4625 Failed Logons              : $($Result.Event4625FailedLogons)"
                Write-Host "4634 Logoffs                    : $($Result.Event4634Logoffs)"
                Write-Host "4647 User-Initiated Logoffs     : $($Result.Event4647UserLogoffs)"
                Write-Host "4740 Account Lockouts            : $($Result.Event4740Lockouts)"
                Write-Host "4771 Kerberos Pre-auth Failures  : $($Result.Event4771KerberosFailures)"
                Write-Host "4776 NTLM Credential Validation  : $($Result.Event4776NTLMFailures)"

                if ($Result.FailedBySource.Count -gt 0) {

                    Write-Host "`nFailed Logons by Source" -ForegroundColor Cyan
                    Write-Host "------------------------" -ForegroundColor DarkCyan

                    $Result.FailedBySource |
                        Format-Table `
                            SourceIP,
                            Count `
                        -AutoSize
                }
                else {

                    Write-Host "`nNo source-based failed logons found." -ForegroundColor Green
                }

                if ($Result.FailedByUser.Count -gt 0) {

                    Write-Host "`nFailed Logons by User" -ForegroundColor Cyan
                    Write-Host "---------------------" -ForegroundColor DarkCyan

                    $Result.FailedByUser |
                        Format-Table `
                            User,
                            Count `
                        -AutoSize
                }

                if ($Result.FailedLogons.Count -gt 0) {

                    Write-Host "`nRecent Failed Logons" -ForegroundColor Cyan
                    Write-Host "--------------------" -ForegroundColor DarkCyan

                    $Result.FailedLogons |
                        Sort-Object Time -Descending |
                        Select-Object -First 20 |
                        Format-Table `
                            Time,
                            User,
                            LogonType,
                            SourceIP,
                            Status,
                            SubStatus `
                        -Wrap `
                        -AutoSize
                }

                if ($Result.Lockouts.Count -gt 0) {

                    Write-Host "`nAccount Lockouts" -ForegroundColor Cyan
                    Write-Host "----------------" -ForegroundColor DarkCyan

                    $Result.Lockouts |
                        Sort-Object Time -Descending |
                        Format-Table `
                            Time,
                            User,
                            CallerComputer `
                        -AutoSize
                }

                if ($Result.KerberosFailures.Count -gt 0) {

                    Write-Host "`nKerberos Authentication Failures" -ForegroundColor Cyan
                    Write-Host "--------------------------------" -ForegroundColor DarkCyan

                    $Result.KerberosFailures |
                        Sort-Object Time -Descending |
                        Select-Object -First 20 |
                        Format-Table `
                            Time,
                            User,
                            ClientAddress,
                            Status `
                        -AutoSize
                }

                if ($Result.NTLMFailures.Count -gt 0) {

                    Write-Host "`nNTLM Credential Validation" -ForegroundColor Cyan
                    Write-Host "--------------------------" -ForegroundColor DarkCyan

                    $Result.NTLMFailures |
                        Sort-Object Time -Descending |
                        Select-Object -First 20 |
                        Format-Table `
                            Time,
                            User,
                            SourceWorkstation,
                            Status `
                        -AutoSize
                }
            }
            catch {

                Write-Host "Failed to retrieve authentication audit data." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {

        Write-Host "`nFailed to perform authentication audit." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}