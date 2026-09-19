function Get-AvailableUpdates {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

        $UpdateSearcher.Online = $true

        $SearchResult = $UpdateSearcher.Search(
            "IsInstalled=0 and IsHidden=0"
        )

        $Updates = foreach ($Update in $SearchResult.Updates) {
            $KBArticleIds = @(
                $Update.KBArticleIDs
            ) -join ', '

            $Categories = @(
                foreach ($Category in $Update.Categories) {
                    $Category.Name
                }
            ) -join ', '

            [PSCustomObject]@{
                Title          = $Update.Title
                KB             = $KBArticleIds
                Severity       = $Update.MsrcSeverity
                Category       = $Categories
                IsMandatory    = $Update.IsMandatory
                RebootRequired = $Update.RebootRequired
                UpdateID       = $Update.Identity.UpdateID
            }
        }

        return @($Updates)
    }

    try {
        Write-Host "`nAvailable Updates" -ForegroundColor Cyan
        Write-Host "-----------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Updates = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {
                    $Updates = & $ScriptBlock
                }

                $Updates = @($Updates)

                if ($Updates.Count -eq 0) {
                    Write-Host "No available updates were found." -ForegroundColor Green
                    continue
                }

                Write-Host "Available updates: $($Updates.Count)" `
                    -ForegroundColor Cyan

                $Updates |
                    Sort-Object Title |
                    Format-Table `
                        KB,
                        Severity,
                        IsMandatory,
                        RebootRequired,
                        Title `
                    -AutoSize
            }
            catch {
                Write-Host "Failed to retrieve available updates." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve available updates." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}