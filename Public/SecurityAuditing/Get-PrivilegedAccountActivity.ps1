function Get-PrivilegedAccountActivity {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $HoursInput = Read-Host "Enter analysis window in hours (default: 24)"

    if ([string]::IsNullOrWhiteSpace($HoursInput)) {
        $Hours = 24
    }
    elseif (-not [int]::TryParse($HoursInput, [ref]$Hours)) {
        Write-Host "`nInvalid number of hours." -ForegroundColor Red
        return
    }
    elseif ($Hours -lt 1 -or $Hours -gt 720) {
        Write-Host "`nAnalysis window must be between 1 and 720 hours." -ForegroundColor Red
        return
    }

    $ScriptBlock = {

        param(
            [int]$Hours
        )

        $Since = (Get-Date).AddHours(-$Hours)

        $PrivilegedGroups = @(
            'Administrators',
            'Domain Admins',
            'Enterprise Admins',
            'Schema Admins',
            'Account Operators',
            'Server Operators',
            'Backup Operators',
            'Print Operators',
            'DnsAdmins',
            'Group Policy Creator Owners',
            'Remote Desktop Users',
            'Remote Management Users',
            'Hyper-V Administrators'
        )

        $Evts = @(
            Get-WinEvent `
                -FilterHashtable @{
                    LogName   = 'Security'
                    StartTime = $Since
                    Id        = 4672, 4673, 4674, 4728, 4729, 4732, 4733, 4756, 4757
                } `
                -MaxEvents 10000 `
                -ErrorAction Stop
        )

        $GetEvtData = {

            param(
                [Parameter(Mandatory)]
                [System.Diagnostics.Eventing.Reader.EventRecord]$Evt
            )

            $Data = @{}

            try {

                $Xml = [xml]$Evt.ToXml()

                foreach ($Node in $Xml.Event.EventData.Data) {

                    if (-not [string]::IsNullOrWhiteSpace($Node.Name)) {
                        $Data[$Node.Name] = [string]$Node.'#text'
                    }
                }
            }
            catch {
                # Ignore malformed event XML.
            }

            return $Data
        }

        $Activity = foreach ($Evt in $Evts) {

            $Data = & $GetEvtData -Evt $Evt

            switch ($Evt.Id) {

                4672 {

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Special Privileges Assigned'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = $Data['SubjectUserName']
                        Group       = ''
                        Member      = ''
                        Source      = $Data['SubjectLogonId']
                        Severity    = 'High'
                        Description = 'Special privileges were assigned to a new logon.'
                    }
                }

                4673 {

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Sensitive Privilege Service Called'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = ''
                        Group       = ''
                        Member      = ''
                        Source      = $Data['SubjectLogonId']
                        Severity    = 'High'
                        Description = 'A privileged service operation was requested.'
                    }
                }

                4674 {

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Privileged Object Operation'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = $Data['ObjectName']
                        Group       = ''
                        Member      = ''
                        Source      = $Data['SubjectLogonId']
                        Severity    = 'High'
                        Description = 'A privileged operation was attempted on an object.'
                    }
                }

                4728 {

                    $Group = $Data['TargetUserName']
                    $Member = $Data['MemberName']

                    $Severity = if ($PrivilegedGroups -contains $Group) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Global Group Member Added'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = ''
                        Group       = $Group
                        Member      = $Member
                        Source      = $Data['SubjectLogonId']
                        Severity    = $Severity
                        Description = "Member '$Member' was added to group '$Group'."
                    }
                }

                4729 {

                    $Group = $Data['TargetUserName']
                    $Member = $Data['MemberName']

                    $Severity = if ($PrivilegedGroups -contains $Group) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Global Group Member Removed'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = ''
                        Group       = $Group
                        Member      = $Member
                        Source      = $Data['SubjectLogonId']
                        Severity    = $Severity
                        Description = "Member '$Member' was removed from group '$Group'."
                    }
                }

                4732 {

                    $Group = $Data['TargetUserName']
                    $Member = $Data['MemberName']

                    $Severity = if ($PrivilegedGroups -contains $Group) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Local Group Member Added'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = ''
                        Group       = $Group
                        Member      = $Member
                        Source      = $Data['SubjectLogonId']
                        Severity    = $Severity
                        Description = "Member '$Member' was added to local group '$Group'."
                    }
                }

                4733 {

                    $Group = $Data['TargetUserName']
                    $Member = $Data['MemberName']

                    $Severity = if ($PrivilegedGroups -contains $Group) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Local Group Member Removed'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = ''
                        Group       = $Group
                        Member      = $Member
                        Source      = $Data['SubjectLogonId']
                        Severity    = $Severity
                        Description = "Member '$Member' was removed from local group '$Group'."
                    }
                }

                4756 {

                    $Group = $Data['TargetUserName']
                    $Member = $Data['MemberName']

                    $Severity = if ($PrivilegedGroups -contains $Group) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Universal Group Member Added'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = ''
                        Group       = $Group
                        Member      = $Member
                        Source      = $Data['SubjectLogonId']
                        Severity    = $Severity
                        Description = "Member '$Member' was added to universal group '$Group'."
                    }
                }

                4757 {

                    $Group = $Data['TargetUserName']
                    $Member = $Data['MemberName']

                    $Severity = if ($PrivilegedGroups -contains $Group) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    [PSCustomObject]@{
                        Time        = $Evt.TimeCreated
                        EventId     = $Evt.Id
                        Activity    = 'Universal Group Member Removed'
                        Account     = $Data['SubjectUserName']
                        Domain      = $Data['SubjectDomainName']
                        Target      = ''
                        Group       = $Group
                        Member      = $Member
                        Source      = $Data['SubjectLogonId']
                        Severity    = $Severity
                        Description = "Member '$Member' was removed from universal group '$Group'."
                    }
                }
            }
        }

        return @($Activity)
    }

    try {

        Write-Host "`nPrivileged Account Activity" -ForegroundColor Cyan
        Write-Host "---------------------------" -ForegroundColor DarkCyan
        Write-Host "Analysis window: $Hours hour(s)" -ForegroundColor DarkGray

        foreach ($Target in $Context.Targets) {

            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {

                if ($Target.IsRemote) {

                    $Activity = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ArgumentList $Hours `
                        -ErrorAction Stop
                }
                else {

                    $Activity = & $ScriptBlock $Hours
                }

                $Activity = @($Activity)

                if ($Activity.Count -eq 0) {

                    Write-Host "`nNo privileged account activity was detected." `
                        -ForegroundColor Green

                    continue
                }

                $HighCount = @(
                    $Activity |
                        Where-Object {
                            $_.Severity -eq 'High'
                        }
                ).Count

                $MediumCount = @(
                    $Activity |
                        Where-Object {
                            $_.Severity -eq 'Medium'
                        }
                ).Count

                Write-Host "`nActivity Summary" -ForegroundColor Cyan
                Write-Host "----------------" -ForegroundColor DarkCyan

                Write-Host "Total Events : $($Activity.Count)"
                Write-Host "High         : $HighCount" -ForegroundColor Red
                Write-Host "Medium       : $MediumCount" -ForegroundColor Yellow

                Write-Host "`nPrivileged Activity" -ForegroundColor Cyan
                Write-Host "-------------------" -ForegroundColor DarkCyan

                $Activity |
                    Sort-Object `
                        @{Expression = {
                            if ($_.Severity -eq 'High') {
                                1
                            }
                            else {
                                2
                            }
                        }},
                        Time |
                    Select-Object `
                        Time,
                        Severity,
                        EventId,
                        Activity,
                        Account,
                        Group,
                        Member,
                        Description |
                    Format-Table -Wrap -AutoSize
            }
            catch {

                Write-Host "Failed to retrieve privileged account activity." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {

        Write-Host "`nFailed to perform privileged account audit." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}