function Get-ADGroupInformation {

    $Identity = Read-Host "Enter group name, SamAccountName or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nGroup identity cannot be empty." -ForegroundColor Red

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
                Created,
                Modified `
            -ErrorAction Stop

        $MemberCount = @(
            Get-ADGroupMember `
                -Identity $Group `
                -ErrorAction Stop
        ).Count

        [PSCustomObject]@{
            Name              = $Group.Name
            SamAccountName    = $Group.SamAccountName
            GroupScope        = $Group.GroupScope
            GroupCategory     = $Group.GroupCategory
            Description       = $Group.Description
            ManagedBy         = $Group.ManagedBy
            MemberCount       = $MemberCount
            Created           = $Group.Created
            Modified          = $Group.Modified
            DistinguishedName = $Group.DistinguishedName
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve group information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}