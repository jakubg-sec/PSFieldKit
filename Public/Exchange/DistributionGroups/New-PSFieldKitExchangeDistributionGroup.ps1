function New-PSFieldKitExchangeDistributionGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command New-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'New-DistributionGroup' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|         Create Distribution Group            |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    $Name = Read-Host "Enter distribution group name"

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host "`nGroup name cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($Name.Length -gt 64) {
        Write-Host "`nGroup name cannot exceed 64 characters." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $Alias = Read-Host "Enter alias"

    if ([string]::IsNullOrWhiteSpace($Alias)) {
        Write-Host "`nAlias cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($Alias.Length -gt 64) {
        Write-Host "`nAlias cannot exceed 64 characters." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $DisplayName = Read-Host "Enter display name (press Enter to use group name)"

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = $Name
    }

    if ($DisplayName.Length -gt 64) {
        Write-Host "`nDisplay name cannot exceed 64 characters." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nGroup type:" -ForegroundColor Cyan
    Write-Host "[1] Distribution group"
    Write-Host "[2] Mail-enabled security group"
    Write-Host "[3] Room list"

    $TypeChoice = Read-Host "`nSelect type"

    switch ($TypeChoice) {
        '1' {
            $Type = 'Distribution'
            $RoomList = $false
        }
        '2' {
            $Type = 'Security'
            $RoomList = $false
        }
        '3' {
            $Type = 'Distribution'
            $RoomList = $true
        }
        default {
            Write-Host "`nInvalid group type." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    $PrimarySmtpAddress = Read-Host "Enter primary SMTP address (optional)"

    if (-not [string]::IsNullOrWhiteSpace($PrimarySmtpAddress)) {
        try {
            $null = [System.Net.Mail.MailAddress]$PrimarySmtpAddress

            if ($PrimarySmtpAddress -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
                throw "Invalid SMTP address."
            }
        }
        catch {
            Write-Host "`nInvalid SMTP address." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    $ManagedBy = Read-Host "Enter owner/manager (optional, name, alias or email)"

    $MemberJoinRestriction = 'Closed'
    $MemberDepartRestriction = 'Closed'

    Write-Host "`nMember join restriction:" -ForegroundColor Cyan
    Write-Host "[1] Closed"
    Write-Host "[2] Open"
    Write-Host "[3] ApprovalRequired"

    $JoinChoice = Read-Host "`nSelect option"

    switch ($JoinChoice) {
        '1' {
            $MemberJoinRestriction = 'Closed'
        }
        '2' {
            $MemberJoinRestriction = 'Open'
        }
        '3' {
            $MemberJoinRestriction = 'ApprovalRequired'
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nMember depart restriction:" -ForegroundColor Cyan
    Write-Host "[1] Closed"
    Write-Host "[2] Open"

    $DepartChoice = Read-Host "`nSelect option"

    switch ($DepartChoice) {
        '1' {
            $MemberDepartRestriction = 'Closed'
        }
        '2' {
            $MemberDepartRestriction = 'Open'
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nRequire authenticated senders?" -ForegroundColor Cyan
    Write-Host "[1] Yes"
    Write-Host "[2] No"

    $AuthChoice = Read-Host "`nSelect option"

    switch ($AuthChoice) {
        '1' {
            $RequireSenderAuthenticationEnabled = $true
        }
        '2' {
            $RequireSenderAuthenticationEnabled = $false
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    $Notes = Read-Host "Enter notes (optional)"

    Write-Host "`nGroup configuration:" -ForegroundColor Cyan
    Write-Host "Name                       : $Name"
    Write-Host "Display Name               : $DisplayName"
    Write-Host "Alias                      : $Alias"
    Write-Host "Type                       : $Type"
    Write-Host "Room List                  : $RoomList"
    Write-Host "Primary SMTP               : $PrimarySmtpAddress"
    Write-Host "Owner                      : $(if ([string]::IsNullOrWhiteSpace($ManagedBy)) { 'None' } else { $ManagedBy })"
    Write-Host "Member Join                : $MemberJoinRestriction"
    Write-Host "Member Depart              : $MemberDepartRestriction"
    Write-Host "Require Authenticated      : $RequireSenderAuthenticationEnabled"
    Write-Host "Notes                      : $(if ([string]::IsNullOrWhiteSpace($Notes)) { 'None' } else { $Notes })"
    Write-Host ""

    $Confirmation = Read-Host "Type YES to create this distribution group"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $Parameters = @{
            Name                              = $Name
            Alias                             = $Alias
            DisplayName                       = $DisplayName
            Type                              = $Type
            MemberJoinRestriction             = $MemberJoinRestriction
            MemberDepartRestriction           = $MemberDepartRestriction
            RequireSenderAuthenticationEnabled = $RequireSenderAuthenticationEnabled
            ErrorAction                       = 'Stop'
        }

        if ($RoomList) {
            $Parameters.RoomList = $true
        }

        if (-not [string]::IsNullOrWhiteSpace($PrimarySmtpAddress)) {
            $Parameters.PrimarySmtpAddress = $PrimarySmtpAddress
        }

        if (-not [string]::IsNullOrWhiteSpace($ManagedBy)) {
            $Parameters.ManagedBy = $ManagedBy
        }

        if (-not [string]::IsNullOrWhiteSpace($Notes)) {
            $Parameters.Notes = $Notes
        }

        Write-Host "`nCreating distribution group..." -ForegroundColor Yellow

        $NewGroup = New-DistributionGroup @Parameters

        Write-Host "`nDistribution group created successfully." -ForegroundColor Green
        Write-Host "Name         : $($NewGroup.Name)"
        Write-Host "Alias        : $($NewGroup.Alias)"
        Write-Host "Display Name : $($NewGroup.DisplayName)"
        Write-Host "Primary SMTP : $($NewGroup.PrimarySmtpAddress)"
        Write-Host "Type         : $($NewGroup.RecipientTypeDetails)"
    }
    catch {
        Write-Host "`nFailed to create distribution group." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}