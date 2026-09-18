function Remove-ADGroupMemberAccount {

    $GroupIdentity = Read-Host "Enter group name, SamAccountName or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($GroupIdentity)) {

        Write-Host "`nGroup identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    $MemberIdentity = Read-Host "Enter member username, computer name or group"

    if ([string]::IsNullOrWhiteSpace($MemberIdentity)) {

        Write-Host "`nMember identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Group = Get-ADGroup `
            -Identity $GroupIdentity `
            -ErrorAction Stop

        $Member = Get-ADObject `
            -Identity $MemberIdentity `
            -Properties ObjectClass `
            -ErrorAction Stop

        $ExistingMember = Get-ADGroupMember `
            -Identity $Group `
            -ErrorAction Stop |
            Where-Object {
                $_.DistinguishedName -eq $Member.DistinguishedName
            }

        if (-not $ExistingMember) {

            Write-Host "`nObject is not a member of '$($Group.Name)'." `
                -ForegroundColor Yellow

            return
        }

        Write-Host "`nGroup Information" -ForegroundColor Cyan
        Write-Host "-----------------"
        Write-Host "Group  : $($Group.Name)"
        Write-Host "Member : $($Member.Name)"
        Write-Host "Type   : $($Member.ObjectClass)"

        $Confirmation = Read-Host "`nRemove this member from the group? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." `
                -ForegroundColor Yellow

            return
        }

        Remove-ADGroupMember `
            -Identity $Group `
            -Members $Member.DistinguishedName `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "`nMember '$($Member.Name)' removed from '$($Group.Name)' successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to remove group member." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}