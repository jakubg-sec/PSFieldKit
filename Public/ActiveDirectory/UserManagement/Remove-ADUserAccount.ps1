function Remove-ADUserAccount {

    $Identity = Read-Host "Enter username or UPN"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nUsername cannot be empty." -ForegroundColor Red
        return
    }

    try {

        $User = Get-ADUser `
            -Identity $Identity `
            -Properties Enabled, UserPrincipalName, DistinguishedName `
            -ErrorAction Stop

        Write-Host "`nUser Information" -ForegroundColor Cyan
        Write-Host "----------------"
        Write-Host "Name        : $($User.Name)"
        Write-Host "Login       : $($User.SamAccountName)"
        Write-Host "UPN         : $($User.UserPrincipalName)"
        Write-Host "Enabled     : $($User.Enabled)"
        Write-Host "DistinguishedName : $($User.DistinguishedName)"

        Write-Host "`nWARNING: This action will permanently remove the AD user account." `
            -ForegroundColor Red

        $Confirmation = Read-Host "Type DELETE to confirm"

        if ($Confirmation -cne 'DELETE') {

            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        Remove-ADUser `
            -Identity $User `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "`nUser '$($User.SamAccountName)' has been removed successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to remove user." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}