function Remove-ADGroupAccount {

    $Identity = Read-Host "Enter group name, SamAccountName or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nGroup identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Group = Get-ADGroup `
            -Identity $Identity `
            -Properties `
                Description,
                GroupScope,
                GroupCategory,
                ManagedBy,
                DistinguishedName `
            -ErrorAction Stop

        $MemberCount = @(
            Get-ADGroupMember `
                -Identity $Group `
                -ErrorAction Stop
        ).Count

        Write-Host "`nGroup Information" -ForegroundColor Cyan
        Write-Host "-----------------"
        Write-Host "Name              : $($Group.Name)"
        Write-Host "SamAccountName    : $($Group.SamAccountName)"
        Write-Host "Scope             : $($Group.GroupScope)"
        Write-Host "Category          : $($Group.GroupCategory)"
        Write-Host "Description       : $($Group.Description)"
        Write-Host "Member Count      : $MemberCount"
        Write-Host "DistinguishedName : $($Group.DistinguishedName)"

        Write-Host "`nWARNING: This action will permanently remove the AD group." `
            -ForegroundColor Red

        if ($MemberCount -gt 0) {

            Write-Host "WARNING: This group contains $MemberCount member(s)." `
                -ForegroundColor Yellow
        }

        $Confirmation = Read-Host "Type DELETE to confirm"

        if ($Confirmation -cne 'DELETE') {

            Write-Host "`nOperation cancelled." `
                -ForegroundColor Yellow

            return
        }

        Remove-ADGroup `
            -Identity $Group `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "`nGroup '$($Group.Name)' has been removed successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to remove group." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}