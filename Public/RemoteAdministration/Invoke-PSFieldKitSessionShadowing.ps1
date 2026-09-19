function Invoke-PSFieldKitSessionShadowing {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if ($Context.IsMultiTarget) {
        Write-Host "`nRDP Session Shadowing requires a single remote target." `
            -ForegroundColor Yellow
        return
    }

    if (-not $Context.IsRemote) {
        Write-Host "`nRDP Session Shadowing requires a remote target." `
            -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nRDP Session Shadowing" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow
        Write-Host

        Write-Host "Active sessions:" -ForegroundColor Cyan
        Write-Host

        $SessionOutput = @(
            & qwinsta.exe /server:$($Context.ComputerName) 2>&1
        )

        if ($SessionOutput.Count -eq 0) {
            Write-Host "No RDP session information was returned." -ForegroundColor Yellow
            return
        }

        $SessionOutput | Out-Host

        $Sessions = foreach ($Line in $SessionOutput) {
            $Text = $Line.ToString().Trim()

            if ($Text -match '^(?<SessionName>\S+)\s+(?<UserName>\S*)\s+(?<SessionId>\d+)\s+(?<State>\S+)') {
                [PSCustomObject]@{
                    SessionName = $Matches.SessionName
                    UserName    = $Matches.UserName
                    SessionId   = [int]$Matches.SessionId
                    State       = $Matches.State
                }
            }
        }

        $ShadowableSessions = @(
            $Sessions |
            Where-Object {
                $_.SessionId -gt 0 -and
                $_.State -eq 'Active' -and
                $null -ne $_.UserName -and
                $_.UserName -ne ''
            }
        )

        if ($ShadowableSessions.Count -eq 0) {
            Write-Host "`nNo active user sessions were found on $($Context.ComputerName)." `
                -ForegroundColor Yellow
            return
        }

        Write-Host "`nAvailable sessions:" -ForegroundColor Cyan

        $ShadowableSessions |
            Format-Table `
                SessionId,
                SessionName,
                UserName,
                State `
            -AutoSize

        Write-Host

        $SessionIdInput = Read-Host "Enter session ID"

        $SessionId = 0

        if (-not [int]::TryParse($SessionIdInput, [ref]$SessionId)) {
            Write-Host "`nInvalid session ID." -ForegroundColor Red
            return
        }

        $SelectedSession = $ShadowableSessions |
            Where-Object {
                $_.SessionId -eq $SessionId
            }

        if ($null -eq $SelectedSession) {
            Write-Host "`nThe selected session is not available for shadowing." `
                -ForegroundColor Red
            return
        }

        Write-Host "`nSelect shadowing mode:" -ForegroundColor Cyan
        Write-Host "[1] View only"
        Write-Host "[2] Control session"
        Write-Host "[0] Cancel"

        $Mode = Read-Host "`nSelect option"

        switch ($Mode) {
            '1' {
                Write-Host "`nStarting RDP shadowing in view-only mode..." `
                    -ForegroundColor Yellow

                Start-Process `
                    -FilePath 'mstsc.exe' `
                    -ArgumentList `
                        "/shadow:$SessionId",
                        "/v:$($Context.ComputerName)" `
                    -ErrorAction Stop
            }

            '2' {
                Write-Host "`nControl mode allows keyboard and mouse input in the target session." `
                    -ForegroundColor Yellow

                $Confirmation = Read-Host "Type YES to continue"

                if ($Confirmation -ne 'YES') {
                    Write-Host "`nShadowing cancelled." -ForegroundColor Yellow
                    return
                }

                Start-Process `
                    -FilePath 'mstsc.exe' `
                    -ArgumentList `
                        "/shadow:$SessionId",
                        "/v:$($Context.ComputerName)",
                        "/control" `
                    -ErrorAction Stop
            }

            '0' {
                return
            }

            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                return
            }
        }

        Write-Host "`nRDP shadowing request started successfully." `
            -ForegroundColor Green

        Write-Host "Target    : $($Context.ComputerName)"
        Write-Host "Session ID: $SessionId"

        if ($Mode -eq '1') {
            Write-Host "Mode      : View only"
        }
        else {
            Write-Host "Mode      : Control"
        }
    }
    catch {
        Write-Host "`nFailed to start RDP session shadowing on $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}