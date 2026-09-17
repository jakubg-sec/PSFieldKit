function Test-PSFieldKitTarget {

    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    try {
        Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}