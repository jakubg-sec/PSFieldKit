# PSFieldKit

**PowerShell SysAdmin Toolkit for Windows**

PSFieldKit is a PowerShell-based administration, diagnostics and troubleshooting toolkit designed for Windows system administrators.

The project provides a unified interactive console for common Windows administration tasks, Active Directory management and diagnostics, networking, processes and services, Event Logs, storage, security, remote administration, Windows Update, security auditing and on-premises Exchange Server administration.

PSFieldKit is implemented as a PowerShell script module and is designed around a simple principle:

> **One console. Many administrative tasks. Native PowerShell and Windows tooling.**

The project is intended primarily for administrators who need a practical field toolkit rather than a collection of unrelated scripts.

---

# Features

PSFieldKit currently provides the following major areas:

| Area | Description |
|---|---|
| Computer Information | System, OS, hardware, CPU, memory, disks, adapters and uptime |
| Network Diagnostics | Network adapters, IP configuration, routes, ARP/neighbor table, DNS, connectivity, ports, statistics and firewall |
| Active Directory | Domains, forests, users, computers, groups, OUs, DCs, GPOs, replication, trusts, diagnostics, searches and DNS |
| Processes & Services | Process inspection, service management and dependencies |
| Event Logs | Event inspection, search, channel information, clearing and export |
| Storage & Disks | Disk, partition, volume, health, free space, usage and Storage Spaces |
| Security | Local accounts, groups, security policy, audit policy, certificates, Defender, BitLocker and logged-on users |
| Remote Administration | WinRM, PowerShell remoting, commands, scripts, CIM/WMI, MMC tools, session shadowing and remote restart/shutdown |
| Software & Updates | Installed software, Windows features and Windows Update information |
| Security Auditing | Authentication, suspicious activity, privileged activity, persistence, PowerShell activity, audit configuration and security reports |
| Exchange | Exchange Server connectivity, mailbox administration, shared mailboxes, delegation, addresses, mailbox state and Exchange reporting |

---

# Main Menu

PSFieldKit currently exposes the following main menu:

```text
+------------------------------------------------------+
|                  PSFieldKit v1.2.0                   |
|              PowerShell SysAdmin Toolkit             |
|                    Author: jacob                     |
+------------------------------------------------------+
|                                                      |
|       "With great power there must also come         |
|                great responsibility."                |
|                                                      |
+------------------------------------------------------+
|                                                      |
|  SYSTEM                                              |
|  [1] Computer Information                            |
|  [2] Network Diagnostics                             |
|  [3] Active Directory                                |
|  [4] Processes & Services                            |
|  [5] Event Logs                                      |
|                                                      |
|  ADMINISTRATION                                      |
|  [6] Storage & Disks                                 |
|  [7] Security                                        |
|  [8] Remote Administration                           |
|  [9] Software & Updates                              |
| [10] Security Auditing                               |
| [11] Exchange                                        |
|                                                      |
+------------------------------------------------------+
|  [0] Exit                                            |
+------------------------------------------------------+
```

`Show-PSFieldKitMenu` is the main entry point of the toolkit.

The current implementation also contains an internal option `[66]`, which is not part of the normal documented administration workflow.

---

# Requirements

## Operating System

PSFieldKit is currently a **Windows-only** toolkit.

The implementation relies on Windows-specific functionality including:

- Windows PowerShell components
- Windows registry providers
- CIM/WMI
- certificate stores
- Windows Update COM APIs
- Microsoft management cmdlets
- MMC consoles
- Windows executables
- Active Directory tools
- Exchange Management Shell components

The module manifest does not currently declare a formal minimum Windows client or Windows Server version.

Exact OS compatibility should therefore be validated against the target environment.

---

# PowerShell

PSFieldKit is designed around the Windows PowerShell ecosystem, while parts of the code contain explicit compatibility handling for different PowerShell generations.

The module manifest does not currently declare a formal `PowerShellVersion`.

The source contains compatibility handling for older Windows PowerShell and newer PowerShell releases in selected operations.

Recommended environments should therefore be tested before production deployment.

---

# Administrative Privileges

A significant part of PSFieldKit requires administrative privileges.

Depending on the selected operation, elevated access may be required for:

- Active Directory administration
- Group Policy operations
- service management
- Event Log clearing
- Event Log export
- remote administration
- RDP session shadowing
- remote restart/shutdown
- Exchange administration
- security auditing
- BitLocker inspection
- Defender inspection
- system configuration inspection

PSFieldKit does not attempt to bypass Windows security controls.

It operates using the permissions available to the current operator.

---

# Dependencies

The module manifest does not automatically install feature-specific dependencies.

Depending on the selected menu, the system may require components such as:

### Active Directory

```powershell
ActiveDirectory
```

Typically supplied through:

- RSAT
- Active Directory Domain Services management tools
- domain administration tooling

### Group Policy

Group Policy management tools.

### DNS Server

DNS Server PowerShell management tools where applicable.

### Storage

Windows Storage Management cmdlets.

### Security

Windows Defender, BitLocker and security-policy tooling.

### Event Logs

Windows Event Log infrastructure and:

```text
wevtutil.exe
```

### Windows Update

Windows Update COM APIs.

### Exchange

For the Exchange subsystem, the management computer must have access to the required **on-premises Exchange Server Management Shell / Exchange PowerShell cmdlets**.

The exact Exchange functionality available depends on the Exchange environment and installed management components.

---

# Installation

## Repository-local

Clone or download the repository while preserving the complete directory structure.

Then:

```powershell
Set-Location .\PSFieldKit
Import-Module .\PSFieldKit.psd1 -Force
```

Start the toolkit:

```powershell
Show-PSFieldKitMenu
```

---

## PowerShell Module Path

The module can also be copied into a directory included in:

```powershell
$env:PSModulePath
```

Then:

```powershell
Import-Module PSFieldKit
Show-PSFieldKitMenu
```

---

## Verify Installation

Check the module:

```powershell
Get-Module PSFieldKit
```

Check the module version:

```powershell
Get-Module PSFieldKit -ListAvailable
```

Check exported commands:

```powershell
Get-Command -Module PSFieldKit
```

---

# Module Entry Point

The primary user-facing command is:

```powershell
Show-PSFieldKitMenu
```

The module manifest explicitly controls the exported surface.

The project intentionally exposes a single main administration entry point rather than turning every internal function into a public PowerShell command.

---

# Architecture

PSFieldKit uses a standard PowerShell script-module architecture.

```text
PSFieldKit/
│
├── Private/
│
├── Public/
│
├── PSFieldKit.psd1
├── PSFieldKit.psm1
├── CHANGELOG.md
├── LICENSE
└── README.md
```

The module loader recursively loads `.ps1` files from both:

```text
Private\
Public\
```

using:

```powershell
Get-ChildItem
```

and dot-sourcing them into the module scope.

This keeps the implementation modular while maintaining a single module entry point.

---

# Private Functions

The private layer provides shared infrastructure used by the public functionality.

Important helpers include:

```text
Get-PSFieldKitTargets
New-PSFieldKitContext
Test-PSFieldKitMenuOption
Test-PSFieldKitTarget
Write-PSFieldKitMenuOption
```

These functions handle:

- target selection
- target validation
- target contexts
- multi-target processing
- menu validation
- menu rendering
- target-specific option availability

---

# Target Model

One of the central architectural concepts in PSFieldKit is the **target context**.

The context represents the system or systems against which an operation will be executed.

PSFieldKit supports:

```text
Local Computer
Remote Computer
Multiple Remote Computers
```

Multi-target mode is selectively enabled by the individual menu.

---

# Target Context

`New-PSFieldKitContext` creates the shared target object.

Typical properties include:

| Property | Description |
|---|---|
| `ComputerName` | Single selected computer |
| `IsRemote` | Indicates remote operation |
| `Session` | PSSession slot |
| `Targets` | Target collection |
| `IsMultiTarget` | Indicates multi-target mode |

---

# Local Computer

Local mode uses:

```powershell
$env:COMPUTERNAME
```

The resulting context has:

```text
IsRemote = False
IsMultiTarget = False
```

---

# Single Remote Computer

The operator enters:

- hostname
- computer name
- IP address

Before the target is accepted, WinRM is tested.

PSFieldKit uses:

```powershell
Test-WSMan
```

This makes WinRM availability part of the target-selection process.

A remote computer can therefore be reachable through ICMP and still be rejected when WinRM is unavailable.

---

# Multiple Computers

Multi-target mode is currently enabled for selected functional areas.

The primary areas using it are:

- Event Logs
- Remote Administration
- Security Auditing

The target collector supports:

```text
[1] Computer List
[2] IPv4 Range
[3] IPv4 CIDR
[4] Text File
```

---

# Computer List

Example:

```text
server01,server02,server03,192.168.10.25
```

Input is normalized by:

- trimming whitespace
- removing empty entries
- removing duplicates

---

# IPv4 Range

Example:

```text
192.168.10.10-192.168.10.50
```

Requirements:

- valid IPv4 addresses
- start address cannot exceed end address
- maximum range size: 4096 addresses

---

# IPv4 CIDR

Example:

```text
192.168.10.0/24
```

Supported prefix lengths:

```text
/1 - /32
```

Networks generating more than 4096 addresses are rejected.

The implementation expands the calculated address block and does not explicitly remove network or broadcast addresses.

---

# Target File

Example:

```text
server01
server02
server03
192.168.10.25

# comments are allowed
```

The loader:

- trims lines
- ignores empty lines
- ignores lines beginning with `#`
- removes duplicates
- limits input to 4096 entries

The resulting targets are validated through the normal WinRM validation process.

---

# 1. Computer Information

The Computer Information subsystem provides basic system inventory.

Menu:

```text
[1] System Information
[2] Operating System Information
[3] Hardware Information
[4] CPU Information
[5] Memory Information
[6] Disk Information
[7] Network Adapter Information
[8] Uptime
```

Functions include:

```text
Show-ComputerMenu
Get-SystemInformation
Get-OperatingSystemInformation
Get-HardwareInformation
Get-CPUInformation
Get-MemoryInformation
Get-DiskInformation
Get-NetworkAdapterInformation
Get-Uptime
```

Information includes:

- operating system
- computer name
- manufacturer
- model
- CPU information
- processor counts
- memory
- disks
- network adapters
- uptime

The subsystem uses Windows CIM/WMI functionality.

---

# 2. Network Diagnostics

Menu:

```text
[1] Network Adapters
[2] IP Configuration
[3] Routing Table
[4] ARP / Neighbor Table
[5] DNS Diagnostics
[6] Connectivity Tests
[7] Ports & Connections
[8] Network Statistics
[9] Firewall Information
```

Functions include:

```text
Show-NetworkMenu
Get-NetworkAdapters
Get-NetworkIPConfiguration
Get-RoutingTable
Get-NetworkNeighborTable
Test-DNSDiagnostics
Test-NetworkConnectivity
Get-PortsAndConnections
Get-NetworkStatistics
Get-FirewallInformation
```

---

## Connectivity

`Test-NetworkConnectivity` provides:

```text
[1] Ping
[2] Test TCP Port
[3] Traceroute
```

TCP tests support:

```text
1-65535
```

and use:

```powershell
Test-NetConnection
```

---

# 3. Active Directory

Active Directory is one of the largest subsystems in PSFieldKit.

The AD menu loads:

```powershell
Import-Module ActiveDirectory
```

when the subsystem is entered.

If the Active Directory PowerShell module is unavailable, PSFieldKit reports the dependency problem instead of silently failing.

---

## AD Main Menu

```text
[1] Domain & Forest Information
[2] User Management
[3] Computer Management
[4] Group Management
[5] Organizational Units
[6] Domain Controllers
[7] Group Policy
[8] Replication
[9] Trusts
[10] AD Diagnostics
[11] Search Active Directory
[12] DNS
```

---

## 3.1 Domain & Forest

The subsystem provides:

```text
Domain Information
Forest Information
FSMO Roles
Domain Functional Level
Forest Functional Level
Sites & Subnets
```

Functions include:

```text
Get-ADDomainInformation
Get-ADForestInformation
Get-ADFSMORoles
Get-ADDomainFunctionalLevel
Get-ADForestFunctionalLevel
Get-ADSiteInformation
```

---

## 3.2 User Management

Menu:

```text
[1] User Information
[2] Search Users
[3] Create User
[4] Disable User
[5] Enable User
[6] Unlock User
[7] Reset Password
[8] Remove User
[9] Group Membership
```

Functions include:

```text
Get-ADUserInformation
Search-ADUsers
New-ADUserAccount
Disable-ADUserAccount
Enable-ADUserAccount
Unlock-ADUserAccount
Reset-ADUserPassword
Remove-ADUserAccount
Show-ADUserGroupMembership
```

Administrative operations require appropriate permissions.

---

## 3.3 Computer Management

Menu:

```text
[1] Computer Information
[2] Search Computers
[3] Create Computer
[4] Enable Computer
[5] Disable Computer
[6] Reset Computer
[7] Remove Computer
[8] Last Logon
```

Functions include:

```text
Get-ADComputerInformation
Search-ADComputers
New-ADComputerAccount
Enable-ADComputerAccount
Disable-ADComputerAccount
Reset-ADComputerAccount
Remove-ADComputerAccount
Get-ADComputerLastLogon
```

---

## 3.4 Group Management

Menu:

```text
[1] Group Information
[2] Search Groups
[3] Create Group
[4] Remove Group
[5] Add Group Member
[6] Remove Group Member
[7] Group Members
[8] User Group Membership
[9] Nested Group Membership
```

The group functionality covers:

- group information
- group searches
- group creation
- group removal
- membership management
- nested membership
- user membership inspection

---

## 3.5 Organizational Units

Menu:

```text
[1] OU Tree
[2] OU Information
[3] Search OUs
[4] Create OU
[5] Rename OU
[6] Remove OU
```

OU operations include:

```text
Get-ADOUTree
Get-ADOUInformation
Search-ADOUs
New-PSFKADOrganizationalUnit
Rename-PSFKADOrganizationalUnit
Remove-PSFKADOrganizationalUnit
```

---

## 3.6 Domain Controllers

The DC subsystem provides:

```text
Domain Controller Information
List Domain Controllers
Services
SYSVOL / NETLOGON
Connectivity
Event Logs
DC Diagnostics
```

Connectivity checks include commonly required AD ports such as:

```text
53    DNS
88    Kerberos
135   RPC
389   LDAP
445   SMB
3268  Global Catalog
5985  WinRM
```

---

## 3.7 Group Policy

The Group Policy area provides:

```text
GPO Information
Search GPOs
GPO Links
GPO Permissions
Generate GPReport
Force GPUpdate
Group Policy Results
Group Policy Modeling
GPO Diagnostics
```

Functions include:

```text
Get-ADGPOInformation
Search-ADGPOs
Get-ADGPOLinks
Get-ADGPOPermissions
Get-ADGPReport
Invoke-ADGPUpdate
Get-ADGroupPolicyResults
Get-ADGroupPolicyModeling
Test-ADGPODiagnostics
```

GPO reporting supports generated policy reports.

---

## 3.8 Replication

The replication subsystem provides:

```text
Replication Status
Replication Partners
Replication Failures
Replication Metadata
Synchronize Replication
Replication Summary
Repadmin Diagnostics
```

Functions include:

```text
Get-ADReplicationStatus
Get-ADReplicationPartners
Get-ADReplicationFailures
Get-ADReplicationMetadata
Sync-ADReplication
Get-ADReplicationSummary
Test-ADReplicationDiagnostics
```

---

## 3.9 Trusts

Menu:

```text
[1] Trust Information
[2] List Domain Trusts
[3] Test Trust
[4] Forest Trust Information
[5] Trust Diagnostics
```

The subsystem covers both domain and forest trust information and diagnostics.

---

## 3.10 AD Diagnostics

Menu:

```text
[1] AD Health Summary
[2] DCDIAG
[3] DNS Diagnostics
[4] LDAP Connectivity
[5] Kerberos Test
[6] Time Synchronization
[7] SYSVOL / NETLOGON
```

The diagnostics area is intended for first-line investigation of:

- DC health
- DNS
- LDAP
- Kerberos
- time synchronization
- SYSVOL
- NETLOGON
- general domain-controller health

---

## 3.11 Active Directory Search

Menu:

```text
[1] Search All Objects
[2] Search by LDAP Filter
```

The search area supports general object searches and custom LDAP filters.

---

## 3.12 DNS

The AD DNS subsystem provides:

```text
DNS Server Information
DNS Zones
Zone Information
DNS Records
DNS Forwarders
DNS Scavenging
DNS Server Statistics
```

Typical underlying cmdlets include:

```powershell
Get-DnsServerZone
Get-DnsServerResourceRecord
Get-DnsServerForwarder
Get-DnsServerScavenging
Get-DnsServerStatistics
```

---

# 4. Processes & Services

Menu:

```text
[1] Process Information
[2] Running Processes
[3] Process Details
[4] Service Information
[5] Running Services
[6] Start Service
[7] Stop Service
[8] Restart Service
[9] Service Dependencies
```

Functions include:

```text
Get-ProcessInformation
Get-RunningProcesses
Get-ProcessDetails
Get-ServiceInformation
Get-RunningServices
Start-PSFieldKitService
Stop-PSFieldKitService
Restart-PSFieldKitService
Get-ServiceDependencies
```

The implementation uses CIM sessions and methods, allowing the same workflow to operate against local and supported remote targets.

---

# 5. Event Logs

Menu:

```text
[1] System Events
[2] Application Events
[3] Security Events
[4] PowerShell Events
[5] Windows Event Channels
[6] Search Events
[7] Event Log Information
[8] Clear Event Log
[9] Export Event Logs
```

Functions include:

```text
Get-SystemEventLog
Get-ApplicationEventLog
Get-SecurityEventLog
Get-PowerShellEventLog
Get-WindowsEventChannels
Search-PSFieldKitEventLog
Get-EventLogInformation
Clear-PSFieldKitEventLog
Export-EventLogs
```

---

## Event Log Export

`Export-EventLogs` provides a structured collection workflow.

Default values include:

| Setting | Default |
|---|---|
| Logs | System, Application, Security |
| Time range | 30 days |
| Timeout | 600 seconds per log |
| Overwrite | No |
| ZIP | No |
| Destination | `C:\PSFieldKit\EventLogs` |

Exports may include:

- run ID
- operator
- source host
- UTC timestamps
- selected logs
- time range
- target count
- status
- event count
- file size
- SHA-256 hash
- destination
- error information

Generated metadata can include:

```text
ExportReport.csv
ExportManifest.json
```

Optional ZIP creation is supported.

---

## Clear Event Log

`Clear-PSFieldKitEventLog` is destructive.

The operator must explicitly confirm the action.

The function uses Windows Event Log tooling and is intended for authorized administrative use only.

---

# 6. Storage & Disks

Menu:

```text
[1] Disk Information
[2] Partition Information
[3] Volume Information
[4] Free Space
[5] Disk Health
[6] Mounted Drives
[7] Disk Usage
[8] Storage Spaces
[9] Rescan Disks
```

Functions include:

```text
Get-DiskInformation
Get-PartitionInformation
Get-VolumeInformation
Get-FreeSpace
Get-DiskHealth
Get-MountedDrives
Get-DiskUsage
Get-StorageSpaces
Update-PSFieldKitDisk
```

The storage subsystem uses Windows storage cmdlets such as:

```powershell
Get-Disk
Get-Partition
Get-Volume
Get-PhysicalDisk
Get-StoragePool
Get-VirtualDisk
Update-Disk
```

`Update-PSFieldKitDisk` performs an actual disk rescan.

---

# 7. Security

Menu:

```text
[1] Local Accounts
[2] Local Groups
[3] Security Policy
[4] Audit Policy
[5] Certificates
[6] Microsoft Defender
[7] BitLocker
[8] Logged-on Users
```

Functions include:

```text
Get-LocalAccounts
Get-LocalGroups
Get-SecurityPolicy
Get-AuditPolicy
Get-Certificates
Get-DefenderStatus
Get-BitLockerStatus
Get-LoggedOnUsers
```

---

## Local Accounts

Displays local account information.

---

## Local Groups

Displays local groups and membership information.

---

## Security Policy

Security policy inspection uses Windows security tooling such as:

```text
secedit.exe
```

Information can include:

- password policy
- lockout policy
- password complexity
- administrator state
- guest account state
- account policy settings

---

## Audit Policy

The subsystem inspects configured Windows audit policies.

---

## Certificates

Certificate inspection supports the local computer certificate store.

Typical information includes:

- Subject
- Issuer
- Thumbprint
- validity dates
- private-key presence
- friendly name

---

## Microsoft Defender

Uses Windows Defender management interfaces such as:

```powershell
Get-MpComputerStatus
```

---

## BitLocker

Uses:

```powershell
Get-BitLockerVolume
```

to inspect BitLocker state.

---

## Logged-on Users

Displays currently logged-on users and session information where supported by the target system.

---

# 8. Remote Administration

Menu:

```text
[1] Test Remote Connectivity
[2] Test WinRM
[3] Enter Remote PowerShell
[4] Remove PSSession
[5] Session Information
[6] Invoke Remote Command
[7] Invoke Remote Script
[8] CIM / WMI Remote Query
[9] Remote Computer Management
[10] RDP Session Shadowing
[11] Remote Reboot / Shutdown
```

---

## Target Availability

| Operation | Local | Single Remote | Multiple Remote |
|---|---:|---:|---:|
| Test Remote Connectivity | — | ✓ | ✓ |
| Test WinRM | — | ✓ | ✓ |
| Enter Remote PowerShell | — | ✓ | — |
| Remove PSSession | — | ✓ | — |
| Session Information | — | ✓ | — |
| Invoke Remote Command | — | ✓ | ✓ |
| Invoke Remote Script | — | ✓ | ✓ |
| CIM/WMI Query | — | ✓ | ✓ |
| Remote Computer Management | — | ✓ | — |
| RDP Session Shadowing | — | ✓ | — |
| Remote Restart/Shutdown | — | ✓ | ✓ |

---

## Remote PowerShell

Supports interactive PSSession-based administration against a single remote computer.

---

## Remote Command

`Invoke-PSFieldKitCommand` allows the operator to provide a PowerShell command that is executed against the selected target or targets.

Example:

```powershell
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, LastBootUpTime
```

---

## Remote Script

`Invoke-PSFieldKitScript` validates a local `.ps1` file and executes it remotely.

Example:

```text
C:\Tools\Check-Server.ps1
```

---

## CIM/WMI

The CIM workflow accepts:

```text
Namespace
Class
WQL Filter
```

Default namespace:

```text
root/cimv2
```

Example:

```text
Namespace: root/cimv2
Class: Win32_OperatingSystem
Filter: Version -like "10.*"
```

---

## Remote Computer Management

PSFieldKit can launch native Windows management consoles for a remote system, including:

```text
Computer Management
Event Viewer
Services
Task Scheduler
Disk Management
Device Manager
Shared Folders
```

---

## RDP Session Shadowing

The session-shadowing workflow:

1. enumerates remote sessions
2. displays session IDs
3. asks the operator to select a session
4. supports view-only mode
5. supports control mode

Control mode requires an explicit confirmation before starting a controlled shadowing session.

---

## Remote Restart / Shutdown

The remote power operation supports:

```text
[1] Restart computer
[2] Shutdown computer
```

The operator must explicitly confirm the action.

Multiple remote targets can be processed where the menu allows it.

---

# 9. Software & Updates

Menu:

```text
[1] Installed Software
[2] Software Details
[3] Windows Features
[4] Windows Update Status
[5] Available Updates
[6] Installed Updates
[7] Update History
[8] Check for Updates
[9] Pending Reboot Status
```

Functions include:

```text
Get-InstalledSoftware
Get-SoftwareDetails
Get-WindowsFeatureInformation
Get-WindowsUpdateStatus
Get-AvailableUpdates
Get-InstalledUpdates
Get-UpdateHistory
Find-WindowsUpdates
Get-PendingRebootStatus
```

---

## Installed Software

The implementation reads standard Windows uninstall registry locations.

Typical locations include:

```text
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
```

---

## Windows Features

The subsystem supports Windows Server and Windows optional feature inspection using Windows feature-management cmdlets where available.

---

## Windows Update

The Windows Update subsystem uses the Windows Update COM API.

It provides:

- update service status
- available updates
- installed updates
- update history
- update detection
- pending reboot information

The update search function detects available updates but is not an automatic update-installation engine.

---

# 10. Security Auditing

Security Auditing is dedicated to security-focused investigation rather than basic configuration inspection.

Menu entry:

```text
[10] Security Auditing
```

The subsystem supports local, single-remote and multi-target workflows.

---

## Security Audit Areas

The current Security Auditing functionality covers:

```text
Security Audit Overview
Suspicious Activity Analysis
Authentication Auditing
Privileged Account Activity
Persistence / Autoruns
PowerShell Activity
Audit Policy and Logging
Security Reports
Archived Event Logs
```

---

## Audit Scope

Security Auditing supports:

- local computers
- single remote computers
- multiple remote targets

Where multiple targets are enabled, a common analysis window can be applied across the selected systems.

---

## Analysis Time Range

Security analysis can use a configurable time range.

This allows the administrator to focus the investigation on a specific period instead of processing the complete available event history.

---

## Authentication Auditing

Authentication analysis focuses on Windows security events relevant to:

- successful logons
- failed logons
- account usage
- remote access
- authentication-related anomalies

The purpose is investigation and visibility, not automatic incident-response remediation.

---

## Privileged Activity

The audit subsystem examines activity associated with privileged accounts and security-sensitive operations.

---

## Suspicious Activity

The suspicious-activity workflow aggregates events that can be useful during first-line investigation.

The results should be treated as an investigation aid rather than an automated determination that a security incident has occurred.

---

## Persistence / Autoruns

The persistence audit inspects commonly relevant persistence mechanisms and autorun locations.

---

## PowerShell Activity

The audit subsystem analyzes relevant PowerShell event information where logging is available.

The quality of the analysis depends on the audit configuration of the target system.

---

## Audit Policy and Logging

Security auditing also checks whether the system has appropriate security logging and audit-policy configuration for the events being investigated.

---

## Archived Event Logs

Archived `.evtx` files can be included in security analysis.

This is useful when the relevant events are no longer present in active log channels.

---

## Security Reports

The auditing subsystem can generate security-focused reports intended for:

- investigation
- administrative review
- documentation
- troubleshooting
- incident triage

---

# 11. Exchange

PSFieldKit includes an **Exchange Server** administration area focused on on-premises Exchange environments.

Main menu entry:

```text
[11] Exchange
```

The Exchange subsystem is designed to work with the Exchange Management Shell and appropriate Exchange PowerShell cmdlets.

---

# Exchange Management

The Exchange area provides workflows for:

```text
Exchange Connection / Status
Mailbox Management
Shared Mailboxes
Mailbox Permissions
Email Addresses
Mailbox State
Retention / Hold Information
Disconnected Mailboxes
Exchange Reporting
```

Exchange functionality is intentionally separated from the standard Active Directory menu because Exchange objects combine directory, recipient and messaging-layer data.

---

## Exchange Connection

The Exchange menu manages its own Exchange context.

Operations requiring an Exchange session are prevented from running until the required Exchange environment is available.

This avoids executing Exchange commands in an ordinary PowerShell session where the relevant Exchange cmdlets are not loaded.

---

## Mailbox Overview

The mailbox workflows provide administrative views including:

- users with Exchange mailboxes
- disabled AD users with mailboxes
- inactive users with mailboxes
- users potentially eligible for AD account lifecycle actions while still having mailboxes
- disconnected mailboxes

These views are particularly useful for identifying accounts whose AD and Exchange lifecycle state no longer match.

---

## Disabled Users with Mailboxes

This report is useful for finding:

```text
AD account disabled
        +
Exchange mailbox still present
```

Such accounts can then be reviewed before further lifecycle action.

---

## Inactive Users with Mailboxes

The Exchange area can identify users whose AD/account activity indicates inactivity while a mailbox remains provisioned.

This is intended as an administrative investigation/reporting feature.

---

## Mailboxes Relevant to Account Lifecycle

PSFieldKit can identify users whose directory state may make them candidates for administrative cleanup or review while an Exchange mailbox still exists.

The toolkit does not silently delete such mailboxes.

The purpose is to make potentially conflicting AD/Exchange state visible to the administrator.

---

## Disconnected Mailboxes

Disconnected mailbox information can be inspected as part of Exchange mailbox administration.

This is useful when investigating:

- removed mailboxes
- retention
- mailbox database state
- disconnected recipient objects

---

# Shared Mailboxes

The Exchange subsystem includes shared-mailbox administration.

Typical tasks include:

```text
List shared mailboxes
Inspect shared mailbox properties
Manage mailbox access
Manage Send As
Manage Send on Behalf
Review mailbox addresses
```

Shared mailboxes are treated separately from ordinary user mailboxes.

---

# Mailbox Permissions

PSFieldKit provides mailbox delegation administration around common Exchange permissions.

The workflows cover concepts such as:

```text
Full Access
Send As
Send on Behalf
```

Permission changes are administrative operations and require the appropriate Exchange permissions.

---

## Full Access

Full Access delegation allows the selected user to access the target mailbox according to the Exchange mailbox-permission model.

---

## Send As

Send As delegation allows a delegated user to send messages as the target mailbox.

---

## Send on Behalf

Send on Behalf delegation allows a delegated user to send messages on behalf of the mailbox.

---

# Email Addresses

The Exchange subsystem also supports inspection and management of mailbox/recipient email-address information.

This is useful for:

- reviewing aliases
- checking primary SMTP addresses
- validating recipient addresses
- auditing address configuration

---

# Mailbox Retention

PSFieldKit can inspect Exchange retention-related configuration.

This includes mailbox-level retention and organization-related retention information where exposed by the available Exchange cmdlets.

The menu provides visibility into retention configuration rather than assuming a single retention policy applies to every mailbox.

---

# Mailbox Holds

Mailbox hold and retention information can be inspected to help determine whether a mailbox is subject to preservation or retention-related controls.

This is particularly important before performing administrative mailbox lifecycle actions.

---

# Exchange Reporting

The Exchange subsystem supports report generation for administrative review.

Exchange reports are intended to make mailbox and recipient state easier to review without manually querying every object.

Typical report subjects include:

- users with mailboxes
- disabled users with mailboxes
- inactive mailboxes
- mailbox state
- mailbox retention
- mailbox permissions
- shared mailbox configuration
- recipient email addresses

---

# Exchange and Active Directory

PSFieldKit treats Active Directory and Exchange as related but separate management layers.

A user can therefore exist in AD while also having:

- a mailbox
- mailbox permissions
- recipient addresses
- retention settings
- mailbox holds

This is why the Exchange subsystem contains dedicated reporting and verification workflows.

The toolkit does not assume that disabling or removing an AD object automatically resolves all Exchange-side state.

---

# Remote Operations

Remote functionality is based on Windows administration technologies including:

```text
WinRM
PowerShell Remoting
CIM/WMI
MMC
Windows command-line utilities
Exchange Management Shell
```

Availability depends on:

- network connectivity
- DNS
- authentication
- firewall configuration
- WinRM
- administrative permissions
- Exchange management components where Exchange functionality is used

---

# Destructive and High-Impact Operations

PSFieldKit is not a read-only diagnostic application.

It contains operations capable of changing system state.

Examples include:

```text
Disable-ADUserAccount
Enable-ADUserAccount
Remove-ADUserAccount
Reset-ADUserPassword

New-ADComputerAccount
Disable-ADComputerAccount
Enable-ADComputerAccount
Remove-ADComputerAccount
Reset-ADComputerAccount

New-ADGroupAccount
Remove-ADGroupAccount
Add-ADGroupMemberAccount
Remove-ADGroupMemberAccount

Remove-PSFKADOrganizationalUnit
Rename-PSFKADOrganizationalUnit

Sync-ADReplication

Start-PSFieldKitService
Stop-PSFieldKitService
Restart-PSFieldKitService

Clear-PSFieldKitEventLog

Restart-PSFieldKitComputer

Invoke-PSFieldKitCommand
Invoke-PSFieldKitScript
```

Exchange functionality can also modify mailbox permissions and recipient configuration.

Such operations should be executed only by authorized administrators.

---

# Confirmation Safeguards

High-impact operations use explicit confirmation where applicable.

Examples include confirmation phrases such as:

```text
YES
```

or:

```text
CLEAR
```

or other context-specific confirmation prompts.

These checks are deliberate safeguards against accidental changes.

---

# Security Considerations

## Remote Execution

The following functionality can execute PowerShell code remotely:

```text
Invoke-PSFieldKitCommand
Invoke-PSFieldKitScript
```

These should be considered privileged administrative capabilities.

---

## Event Logs

Exported `.evtx` files may contain:

- usernames
- authentication events
- security events
- system information
- application activity
- operational data

Event Log exports should therefore be treated as sensitive administrative/security data.

---

## Credentials

PSFieldKit does not implement a dedicated credential vault.

Remote operations use the existing Windows/PowerShell authentication mechanisms and the permissions available to the operator.

---

## Exchange Data

Exchange reports may contain:

- mailbox identities
- primary SMTP addresses
- aliases
- delegation information
- recipient configuration
- retention state

Such reports should be handled as potentially sensitive administrative data.

---

# Known Limitations

## Interactive-first design

PSFieldKit is primarily menu-driven and uses interactive input heavily.

It is not currently designed as a traditional collection of fully parameterized cmdlets for automation pipelines.

---

## Selective multi-target support

Multi-target processing is not universally implemented across every subsystem.

The main menu currently enables it for:

- Event Logs
- Remote Administration
- Security Auditing

---

## WinRM dependency

Remote target selection requires successful WinRM validation.

---

## IPv4 target expansion

Range and CIDR expansion currently focuses on IPv4.

---

## Target limits

Multi-target expansion is limited to a maximum of 4096 addresses/entries for supported input methods.

---

## Exchange environment dependency

Exchange functionality depends on the Exchange environment and the availability of the appropriate Exchange Management Shell components/cmdlets.

---

## Active Directory dependency

The AD subsystem requires the Active Directory PowerShell tooling.

---

## Version metadata

The repository should keep the following synchronized for each release:

```text
PSFieldKit.psd1
Main menu version banner
README release/version information
CHANGELOG.md
```

---

# Project Structure

The project is organized around individual administrative domains.

```text
PSFieldKit/
│
├── Private/
│   ├── Get-PSFieldKitTargets.ps1
│   ├── New-PSFieldKitContext.ps1
│   ├── Test-PSFieldKitMenuOption.ps1
│   ├── Test-PSFieldKitTarget.ps1
│   └── Write-PSFieldKitMenuOption.ps1
│
├── Public/
│   ├── ActiveDirectory/
│   │   ├── ComputerManagement/
│   │   ├── Diagnostics/
│   │   ├── DNS/
│   │   ├── DomainControllers/
│   │   ├── DomainForest/
│   │   ├── GroupManagement/
│   │   ├── GroupPolicy/
│   │   ├── OrganizationalUnits/
│   │   ├── Replication/
│   │   ├── Search/
│   │   ├── Trusts/
│   │   └── UserManagement/
│   │
│   ├── ComputerInformation/
│   ├── EventLogs/
│   ├── NetworkDiagnostics/
│   ├── ProcessesServices/
│   ├── RemoteAdministration/
│   ├── Security/
│   ├── SoftwareUpdates/
│   ├── SecurityAuditing/
│   ├── Exchange/
│   └── Show-PSFieldKitMenu.ps1
│
├── PSFieldKit.psd1
├── PSFieldKit.psm1
├── CHANGELOG.md
├── LICENSE
└── README.md
```

The exact subdirectory layout may continue to evolve as the Exchange and Security Auditing areas are expanded.

---

# Development Model

The project deliberately uses small, focused `.ps1` files.

Each function generally has a single administrative responsibility.

This makes it easier to:

- troubleshoot the code
- extend a menu
- test a function independently
- find a feature quickly
- maintain the project without creating a monolithic script

---

# Public and Private Separation

The `Private` layer is responsible for shared infrastructure.

The `Public` layer contains functional areas.

The public source tree does not automatically mean every function is exported as a module command.

The main user entry point remains:

```powershell
Show-PSFieldKitMenu
```

---

# Native Windows Tooling

PSFieldKit intentionally uses the tools that Windows administrators already know.

Examples include:

```text
Get-CimInstance
New-CimSession
Invoke-Command
Get-WinEvent
wevtutil.exe
secedit.exe
qwinsta.exe
mstsc.exe
compmgmt.msc
eventvwr.msc
services.msc
taskschd.msc
diskmgmt.msc
devmgmt.msc
fsmgmt.msc
```

This keeps the toolkit close to the underlying Windows administration model rather than introducing a large custom abstraction layer.

---

# Examples

## Start PSFieldKit

```powershell
Import-Module .\PSFieldKit.psd1 -Force
Show-PSFieldKitMenu
```

---

## Check the installed module

```powershell
Get-Module PSFieldKit -ListAvailable
```

---

## Inspect exported commands

```powershell
Get-Command -Module PSFieldKit
```

---

## Typical Remote Administration Workflow

```text
1. Start PSFieldKit
2. Select Remote Administration
3. Select target mode
4. Enter the target(s)
5. Allow PSFieldKit to validate WinRM
6. Select the required remote operation
```

---

## Typical Security Audit Workflow

```text
1. Start PSFieldKit
2. Select Security Auditing
3. Select local, single-remote or multi-target mode
4. Select the analysis period
5. Select the audit category
6. Review the generated findings/report
```

---

## Typical Exchange Workflow

```text
1. Start PSFieldKit
2. Select Exchange
3. Establish/validate the Exchange context
4. Select the required Exchange management area
5. Review the current recipient/mailbox state
6. Perform the required administrative action
7. Verify the resulting Exchange state
8. Export a report when required
```

---

# Versioning

PSFieldKit follows Semantic Versioning:

```text
MAJOR.MINOR.PATCH
```

### MAJOR

Breaking or major architectural changes.

### MINOR

New backward-compatible functionality.

### PATCH

Backward-compatible bug fixes.

Example:

```text
1.1.0 -> 1.2.0
New functionality

1.2.0 -> 1.2.1
Bug fixes

1.2.0 -> 2.0.0
Breaking changes
```

---

# Contributing

When adding functionality:

- keep shared infrastructure in `Private`
- organize functionality under the appropriate `Public` area
- keep individual functions focused
- reuse the existing target/context model
- validate input
- provide useful error messages
- use confirmation for destructive operations
- document new functionality
- update `CHANGELOG.md`
- keep version information synchronized

New administration areas should ideally include:

```text
Show-*Menu
Operational functions
Target handling
Validation
Error handling
Documentation
Changelog entry
```

---

# License

PSFieldKit is licensed under the MIT License.

Copyright (c) 2026 jacob.

See [`LICENSE`](LICENSE) for the complete license text.

---

# Summary

PSFieldKit is a PowerShell-based Windows administration toolkit centered around a single interactive entry point:

```powershell
Show-PSFieldKitMenu
```

The current project combines:

```text
Computer Information
Network Diagnostics
Active Directory
Processes & Services
Event Logs
Storage & Disks
Security
Remote Administration
Software & Updates
Security Auditing
Exchange
```

The architecture is intentionally PowerShell-native and modular.

It combines:

```text
Target Context
Local / Remote / Multi-Target Workflows
Windows Native Administration
Active Directory Management
Security Investigation
Event Log Collection
Remote Administration
Exchange Server Administration
```

The toolkit is intended to be practical in day-to-day Windows infrastructure administration: diagnostics when something is broken, inspection when something looks suspicious, and administrative actions when a system actually needs changing.

> **With great power there must also come great responsibility.**