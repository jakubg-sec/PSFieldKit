function Write-PSFieldKitMenuOption {
    param(
        [Parameter(Mandatory)]
        [string]$Number,

        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [bool]$Enabled
    )

    $Content = "  [$Number] $Text"

    if ($Content.Length -gt 46) {
        $Content = $Content.Substring(0, 46)
    }
    else {
        $Content = $Content.PadRight(46)
    }

    if ($Enabled) {
        Write-Host "|$Content|"
    }
    else {
        Write-Host "|$Content|" -ForegroundColor DarkGray
    }
}