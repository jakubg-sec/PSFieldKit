# Private
Get-ChildItem `
    -Path "$PSScriptRoot\Private" `
    -Filter "*.ps1" `
    -File `
    -Recurse |
    Sort-Object FullName |
    ForEach-Object {
        . $_.FullName
    }

# Public
Get-ChildItem `
    -Path "$PSScriptRoot\Public" `
    -Filter "*.ps1" `
    -File `
    -Recurse |
    Sort-Object FullName |
    ForEach-Object {
        . $_.FullName
    }