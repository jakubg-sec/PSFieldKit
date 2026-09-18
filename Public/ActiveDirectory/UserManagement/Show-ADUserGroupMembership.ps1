function Show-ADUserGroupMembership {

    $Identity = Read-Host "Enter username or UPN"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nUsername cannot be empty." -ForegroundColor Red
        return
    }

    try {

        $User = Get-ADUser `
            -Identity $Identity `
            -Properties UserPrincipalName `
            -ErrorAction Stop

        Write-Host "`nUser Information" -ForegroundColor Cyan
        Write-Host "----------------"
        Write-Host "Name  : $($User.Name)"
        Write-Host "Login : $($User.SamAccountName)"
        Write-Host "UPN   : $($User.UserPrincipalName)"

        $Groups = Get-ADPrincipalGroupMembership `
            -Identity $User `
            -ErrorAction Stop

        if (-not $Groups) {

            Write-Host "`nUser is not a member of any groups." `
                -ForegroundColor Yellow

            return
        }

        Write-Host "`nGroup Membership" -ForegroundColor Cyan
        Write-Host "----------------"

        $Groups |
            Select-Object `
                Name,
                SamAccountName,
                GroupScope,
                GroupCategory,
                DistinguishedName |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve user group membership." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}