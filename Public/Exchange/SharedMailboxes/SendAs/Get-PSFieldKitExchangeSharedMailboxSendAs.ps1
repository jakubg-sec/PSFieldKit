function Get-PSFieldKitExchangeSharedMailboxSendAs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    $ServerName = "Unknown"

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
        -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
    ) {
        $ServerName = [string]$ExchangeContext.ServerName
    }

    if ($ServerName.Length -gt 35) {
        $ServerName = $ServerName.Substring(0, 32) + "..."
    }

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|         Shared Mailbox - Send As             |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $MailboxIdentity = Read-Host "Enter shared mailbox identity"

    if ([string]::IsNullOrWhiteSpace($MailboxIdentity)) {
        Write-Host ""
        Write-Host "Mailbox identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to find mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($Mailbox.RecipientTypeDetails -ne "SharedMailbox") {
        Write-Host ""
        Write-Host "The selected mailbox is not a shared mailbox." -ForegroundColor Red
        Write-Host "Current type: $($Mailbox.RecipientTypeDetails)" -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Permissions = @(
            Get-ADPermission -Identity $Mailbox.DistinguishedName -ErrorAction Stop |
                Where-Object {
                    -not $_.Deny -and
                    -not $_.IsInherited -and
                    $_.ExtendedRights -like "Send*"
                } |
                Sort-Object User
        )
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve Send As permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Shared mailbox:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Alias        : $($Mailbox.Alias)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host ""

    if ($Permissions.Count -eq 0) {
        Write-Host "No explicit Send As permissions were found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "SEND AS PERMISSIONS" -ForegroundColor DarkCyan
    Write-Host ""

    $Permissions |
        Select-Object @{
            Name = "Trustee"
            Expression = {
                [string]$_.User
            }
        }, @{
            Name = "Access Rights"
            Expression = {
                ($_.ExtendedRights -join ", ")
            }
        }, @{
            Name = "Access Type"
            Expression = {
                [string]$_.AccessControlType
            }
        }, @{
            Name = "Inheritance"
            Expression = {
                [string]$_.InheritanceType
            }
        } |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "Showing explicit Send As permissions only." -ForegroundColor DarkGray
    Read-Host "`nPress Enter to continue" | Out-Null
}