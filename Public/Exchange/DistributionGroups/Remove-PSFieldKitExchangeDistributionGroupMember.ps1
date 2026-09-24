function Remove-PSFieldKitExchangeDistributionGroupMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$Member
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        return
    }

    if (-not (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        return
    }

    if (-not (Get-Command Get-DistributionGroupMember -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroupMember' is not available." -ForegroundColor Red
        return
    }

    if (-not (Get-Command Remove-DistributionGroupMember -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Remove-DistributionGroupMember' is not available." -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter distribution group name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDistribution group identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Group = Get-DistributionGroup -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find distribution group '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    if ($Group.RecipientTypeDetails -eq 'DynamicDistributionGroup') {
        Write-Host "`nDynamic distribution groups do not have manually managed members." -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrWhiteSpace($Member)) {
        $Member = Read-Host "Enter member name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Member)) {
        Write-Host "`nMember identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Members = @(
            Get-DistributionGroupMember `
                -Identity $Group.Identity `
                -ResultSize Unlimited `
                -ErrorAction Stop
        )
    }
    catch {
        Write-Host "`nFailed to retrieve distribution group members." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    $MatchingMembers = @(
        $Members | Where-Object {
            $_.Identity -eq $Member -or
            $_.Alias -eq $Member -or
            $_.Name -eq $Member -or
            $_.DisplayName -eq $Member -or
            $_.PrimarySmtpAddress -eq $Member
        }
    )

    if ($MatchingMembers.Count -eq 0) {
        Write-Host "`nThe specified member was not found in the group." -ForegroundColor Yellow
        return
    }

    if ($MatchingMembers.Count -gt 1) {
        Write-Host "`nMultiple matching members were found." -ForegroundColor Yellow
        Write-Host "Specify a more precise member identity." -ForegroundColor Yellow

        $MatchingMembers |
            Select-Object DisplayName, Alias, PrimarySmtpAddress, RecipientTypeDetails |
            Format-Table -AutoSize |
            Out-Host

        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $SelectedMember = $MatchingMembers[0]

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|     Remove Distribution Group Member         |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $GroupDisplayName = [string]$Group.DisplayName

    if ($GroupDisplayName.Length -gt 36) {
        $GroupDisplayName = $GroupDisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group  : {0,-35}|" -f $GroupDisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nGROUP" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $Group.DisplayName)
    Write-Host ("Alias        : {0}" -f $Group.Alias)
    Write-Host ("Primary SMTP : {0}" -f $Group.PrimarySmtpAddress)

    Write-Host "`nMEMBER TO REMOVE" -ForegroundColor DarkCyan
    Write-Host ("Display Name : {0}" -f $SelectedMember.DisplayName)
    Write-Host ("Alias        : {0}" -f $SelectedMember.Alias)
    Write-Host ("SMTP         : {0}" -f $SelectedMember.PrimarySmtpAddress)
    Write-Host ("Type         : {0}" -f $SelectedMember.RecipientTypeDetails)

    Write-Host "`nWARNING" -ForegroundColor Red
    Write-Host "This operation will remove the member from the distribution group." -ForegroundColor Yellow

    $Confirmation = Read-Host "`nType YES to remove this member"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    Write-Host "`nRemoving member..." -ForegroundColor Yellow

    try {
        Remove-DistributionGroupMember `
            -Identity $Group.Identity `
            -Member $SelectedMember.Identity `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "`nMember removed successfully." -ForegroundColor Green
        Write-Host ("Group  : {0}" -f $Group.DisplayName)
        Write-Host ("Member : {0}" -f $SelectedMember.DisplayName)
    }
    catch {
        Write-Host "`nFailed to remove member." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}