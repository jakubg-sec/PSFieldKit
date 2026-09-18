function Get-ADGroupMembers {

    $Identity = Read-Host "Enter group name, SamAccountName or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nGroup identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Group = Get-ADGroup `
            -Identity $Identity `
            -ErrorAction Stop

        Write-Host "`nGroup Information" -ForegroundColor Cyan
        Write-Host "-----------------"
        Write-Host "Name : $($Group.Name)"
        Write-Host "SAM  : $($Group.SamAccountName)"

        $Members = Get-ADGroupMember `
            -Identity $Group `
            -ErrorAction Stop

        if (-not $Members) {

            Write-Host "`nGroup has no members." `
                -ForegroundColor Yellow

            return
        }

        Write-Host "`nGroup Members" -ForegroundColor Cyan
        Write-Host "-------------"

        $Members |
            Select-Object `
                Name,
                SamAccountName,
                ObjectClass,
                DistinguishedName |
            Sort-Object ObjectClass, Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve group members." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}