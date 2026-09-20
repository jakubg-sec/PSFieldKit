function Get-PowerShellActivityAudit {

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

        #
        # Evt collections
        #

        $OperationalEvts = @()
        $ClassicEvts = @()

        #
        # PowerShell Operational Log
        #

        $OperationalLog = Get-WinEvt `
            -ListLog 'Microsoft-Windows-PowerShell/Operational' `
            -ErrorAction SilentlyContinue

        if ($null -ne $OperationalLog -and $OperationalLog.IsEnabled) {

            $OperationalEvts = @(
                Get-WinEvt `
                    -FilterHashtable @{
                        LogName   = 'Microsoft-Windows-PowerShell/Operational'
                        StartTime = $Since
                        Id        = 4103, 4104
                    } `
                    -MaxEvts 5000 `
                    -ErrorAction SilentlyContinue
            )
        }

        #
        # Classic Windows PowerShell Log
        #

        $ClassicLog = Get-WinEvt `
            -ListLog 'Windows PowerShell' `
            -ErrorAction SilentlyContinue

        if ($null -ne $ClassicLog -and $ClassicLog.IsEnabled) {

            $ClassicEvts = @(
                Get-WinEvt `
                    -FilterHashtable @{
                        LogName   = 'Windows PowerShell'
                        StartTime = $Since
                        Id        = 400, 403, 600, 800
                    } `
                    -MaxEvts 5000 `
                    -ErrorAction SilentlyContinue
            )
        }

        #
        # Combine Evt collections
        #

        $AllEvts = @(
            $OperationalEvts
            $ClassicEvts
        )

        #
        # Evt counters
        #
        # Use normal properties instead of an indexed dictionary.
        # This survives Invoke-Command / PowerShell remoting reliably.
        #

        $Evt400Count = 0
        $Evt403Count = 0
        $Evt4103Count = 0
        $Evt4104Count = 0
        $Evt600Count = 0
        $Evt800Count = 0

        foreach ($Evt in $AllEvts) {

            switch ($Evt.Id) {

                400 {
                    $Evt400Count++
                }

                403 {
                    $Evt403Count++
                }

                4103 {
                    $Evt4103Count++
                }

                4104 {
                    $Evt4104Count++
                }

                600 {
                    $Evt600Count++
                }

                800 {
                    $Evt800Count++
                }
            }
        }

        #
        # Script Block Logging
        #

        $ScriptBlockEvts = @(
            $OperationalEvts |
            Where-Object {
                $_.Id -eq 4104
            } |
            Sort-Object TimeCreated -Descending
        )

        #
        # Module Logging
        #

        $ModuleEvts = @(
            $OperationalEvts |
            Where-Object {
                $_.Id -eq 4103
            } |
            Sort-Object TimeCreated -Descending
        )

        #
        # PowerShell Engine Evts
        #

        $EngineEvts = @(
            $ClassicEvts |
            Where-Object {
                $_.Id -in @(400, 403, 600)
            } |
            Sort-Object TimeCreated -Descending
        )

        #
        # Pipeline Evts
        #

        $PipelineEvts = @(
            $ClassicEvts |
            Where-Object {
                $_.Id -eq 800
            } |
            Sort-Object TimeCreated -Descending
        )

        #
        # Script Block Details
        #

        $ScriptBlockDetails = foreach (
            $Evt in $ScriptBlockEvts | Select-Object -First 50
        ) {

            $Message = [string]$Evt.Message

            if ($Message.Length -gt 1000) {
                $Message = $Message.Substring(0, 1000) + '...'
            }

            [PSCustomObject]@{
                Time    = $Evt.TimeCreated
                EvtId = $Evt.Id
                Message = $Message
            }
        }

        #
        # Module Details
        #

        $ModuleDetails = foreach (
            $Evt in $ModuleEvts | Select-Object -First 50
        ) {

            $Message = [string]$Evt.Message

            if ($Message.Length -gt 1000) {
                $Message = $Message.Substring(0, 1000) + '...'
            }

            [PSCustomObject]@{
                Time    = $Evt.TimeCreated
                EvtId = $Evt.Id
                Message = $Message
            }
        }

        #
        # Engine Details
        #

        $EngineDetails = foreach (
            $Evt in $EngineEvts | Select-Object -First 50
        ) {

            $Message = [string]$Evt.Message

            if ($Message.Length -gt 500) {
                $Message = $Message.Substring(0, 500) + '...'
            }

            [PSCustomObject]@{
                Time    = $Evt.TimeCreated
                EvtId = $Evt.Id
                Message = $Message
            }
        }

        #
        # Pipeline Details
        #

        $PipelineDetails = foreach (
            $Evt in $PipelineEvts | Select-Object -First 50
        ) {

            $Message = [string]$Evt.Message

            if ($Message.Length -gt 500) {
                $Message = $Message.Substring(0, 500) + '...'
            }

            [PSCustomObject]@{
                Time    = $Evt.TimeCreated
                EvtId = $Evt.Id
                Message = $Message
            }
        }

        #
        # Return remoting-safe object
        #

        [PSCustomObject]@{

            OperationalLogEnabled = if ($null -ne $OperationalLog) {
                [bool]$OperationalLog.IsEnabled
            }
            else {
                $false
            }

            ClassicLogEnabled = if ($null -ne $ClassicLog) {
                [bool]$ClassicLog.IsEnabled
            }
            else {
                $false
            }

            Evt400EngineStart       = $Evt400Count
            Evt403EngineStop        = $Evt403Count
            Evt4103ModuleLogging    = $Evt4103Count
            Evt4104ScriptBlock      = $Evt4104Count
            Evt600ProviderActivity  = $Evt600Count
            Evt800PipelineActivity  = $Evt800Count

            TotalEvts = $AllEvts.Count

            ScriptBlockEvts = @($ScriptBlockDetails)
            ModuleEvts      = @($ModuleDetails)
            EngineEvts      = @($EngineDetails)
            PipelineEvts    = @($PipelineDetails)
        }
    }

    try {

        Write-Host "`nPowerShell Activity Audit" -ForegroundColor Cyan
        Write-Host "-------------------------" -ForegroundColor DarkCyan
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

                #
                # Logging Sources
                #

                Write-Host "`nLogging Sources" -ForegroundColor Cyan
                Write-Host "---------------" -ForegroundColor DarkCyan

                if ($Result.OperationalLogEnabled) {

                    Write-Host `
                        "PowerShell Operational Log : Enabled" `
                        -ForegroundColor Green
                }
                else {

                    Write-Host `
                        "PowerShell Operational Log : Disabled" `
                        -ForegroundColor Yellow
                }

                if ($Result.ClassicLogEnabled) {

                    Write-Host `
                        "Windows PowerShell Log      : Enabled" `
                        -ForegroundColor Green
                }
                else {

                    Write-Host `
                        "Windows PowerShell Log      : Disabled" `
                        -ForegroundColor Yellow
                }

                #
                # Activity Summary
                #

                Write-Host "`nActivity Summary" -ForegroundColor Cyan
                Write-Host "----------------" -ForegroundColor DarkCyan

                Write-Host `
                    "Engine Start (400)             : $($Result.Evt400EngineStart)"

                Write-Host `
                    "Engine Stop (403)              : $($Result.Evt403EngineStop)"

                Write-Host `
                    "Provider Activity (600)        : $($Result.Evt600ProviderActivity)"

                Write-Host `
                    "Module Logging (4103)          : $($Result.Evt4103ModuleLogging)"

                Write-Host `
                    "Script Block Logging (4104)    : $($Result.Evt4104ScriptBlock)"

                Write-Host `
                    "Pipeline Activity (800)        : $($Result.Evt800PipelineActivity)"

                Write-Host `
                    "Total Evts                   : $($Result.TotalEvts)"

                #
                # Script Block Activity
                #

                if ($Result.ScriptBlockEvts.Count -gt 0) {

                    Write-Host "`nRecent Script Block Activity" `
                        -ForegroundColor Cyan

                    Write-Host "----------------------------" `
                        -ForegroundColor DarkCyan

                    $Result.ScriptBlockEvts |
                        Select-Object `
                            Time,
                            EvtId,
                            Message |
                        Format-Table -Wrap -AutoSize
                }
                else {

                    Write-Host `
                        "`nNo Script Block activity was found." `
                        -ForegroundColor Yellow
                }

                #
                # Module Activity
                #

                if ($Result.ModuleEvts.Count -gt 0) {

                    Write-Host "`nRecent Module Activity" `
                        -ForegroundColor Cyan

                    Write-Host "----------------------" `
                        -ForegroundColor DarkCyan

                    $Result.ModuleEvts |
                        Select-Object `
                            Time,
                            EvtId,
                            Message |
                        Format-Table -Wrap -AutoSize
                }

                #
                # Engine Activity
                #

                if ($Result.EngineEvts.Count -gt 0) {

                    Write-Host "`nRecent Engine Activity" `
                        -ForegroundColor Cyan

                    Write-Host "----------------------" `
                        -ForegroundColor DarkCyan

                    $Result.EngineEvts |
                        Select-Object `
                            Time,
                            EvtId,
                            Message |
                        Format-Table -Wrap -AutoSize
                }

                #
                # Pipeline Activity
                #

                if ($Result.PipelineEvts.Count -gt 0) {

                    Write-Host "`nRecent Pipeline Activity" `
                        -ForegroundColor Cyan

                    Write-Host "------------------------" `
                        -ForegroundColor DarkCyan

                    $Result.PipelineEvts |
                        Select-Object `
                            Time,
                            EvtId,
                            Message |
                        Format-Table -Wrap -AutoSize
                }
            }
            catch {

                Write-Host "Failed to retrieve PowerShell activity." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message `
                    -ForegroundColor Yellow
            }
        }
    }
    catch {

        Write-Host "`nFailed to perform PowerShell activity audit." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}