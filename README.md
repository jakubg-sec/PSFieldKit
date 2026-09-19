# PSFieldKit

**PSFieldKit** is a PowerShell-based system administration toolkit for Windows administrators. The project provides an interactive console menu for system information, network diagnostics, Active Directory administration and diagnostics, processes and services, event logs, storage, security, remote administration, and Windows software/update inspection.

The project is implemented as a PowerShell script module (`PSFieldKit.psm1`) with a module manifest (`PSFieldKit.psd1`). Its code is divided into `Private` helper functions and a larger `Public` functional area organized by administrative domain.

> **Documentation scope:** this README describes the source tree and code dump supplied with the project. It intentionally does not document functionality that could not be confirmed from the supplied source.

---

## Status

The project is currently organized as an interactive administration toolkit rather than a conventional parameter-driven PowerShell command module.

The module manifest reports version **0.1.0**. The interactive main menu displays **PSFieldKit v1.0**.

---

## Main goals

PSFieldKit is designed to put common Windows administration and troubleshooting tasks behind a single console interface.

The codebase currently contains functionality for:

- Windows computer and hardware information
- Network configuration and connectivity diagnostics
- Active Directory administration and diagnostics
- Domain controller inspection
- AD replication and trust diagnostics
- Group Policy inspection and execution
- DNS administration inside Active Directory tooling
- Processes and Windows services
- Windows Event Log inspection, search, clearing, and export
- Storage, disks, volumes, partitions, and Storage Spaces
- Local security configuration and security-state inspection
- BitLocker and Microsoft Defender status
- Installed software and Windows update information
- Remote PowerShell, CIM/WMI, command and script execution
- Remote computer administration through MMC tools
- RDP session shadowing
- Remote restart and shutdown
- Multi-target operation for selected features

---

## Highlights

### Interactive target selection

Most non-AD areas operate against a target context selected before entering the relevant menu:

- Local computer
- One remote computer
- Multiple remote computers for features that explicitly enable multi-target mode

Remote targets are tested with `Test-WSMan` before they are accepted by the target-selection workflow.

### Multi-target input methods

Where multi-target mode is enabled, targets can be provided as:

1. A comma-separated list
2. An IPv4 range
3. An IPv4 CIDR network
4. A text file

The target collector limits range/CIDR/file input to **4096 addresses/entries**.

### Windows-native tooling

The project makes extensive use of native Windows PowerShell cmdlets and Windows executables such as:

- `Get-CimInstance`
- `New-CimSession`
- `Invoke-Command`
- `Get-WinEvent`
- `wevtutil.exe`
- `secedit.exe`
- `qwinsta.exe`
- `mstsc.exe`
- `compmgmt.msc`
- `eventvwr.msc`
- `services.msc`
- `taskschd.msc`
- `diskmgmt.msc`
- `devmgmt.msc`
- `fsmgmt.msc`

---

# Requirements

## Operating system

PSFieldKit is a **Windows-only** toolkit in its current form.

This follows directly from the source code: it depends on Windows-specific PowerShell modules, Windows registry paths, certificate stores, Windows Update COM objects, Windows management namespaces, MMC snap-ins, Windows executables, and Active Directory tooling.

The repository does **not** declare a formal minimum Windows client or Windows Server version in the module manifest. Exact supported OS releases should therefore be treated as an environment-specific compatibility question rather than as a promise of the current source tree.

## PowerShell

The module manifest does not specify a `PowerShellVersion` value.

The source code does contain explicit compatibility logic for PowerShell versions below and above major version 6. In particular, remote connectivity testing uses the Windows PowerShell-style `Test-Connection -ComputerName` parameter on older PowerShell versions and the newer `-TargetName` form on PowerShell 6+.

Therefore:

- PowerShell compatibility is partially accounted for in the code.
- The project does **not** formally declare a tested minimum/maximum PowerShell version.
- The most Windows-specific functionality is expected to depend on the Windows PowerShell ecosystem and installed Windows management modules.

## Required Windows management components

The module manifest has an empty `RequiredModules` list, so dependencies are not automatically installed or enforced by PowerShell module metadata.

Depending on the feature being used, the source expects Windows functionality such as:

| Area | Examples of commands/components used |
|---|---|
| Active Directory | `Get-ADUser`, `Get-ADComputer`, `Get-ADGroup`, `Get-ADDomain`, `Get-ADForest`, `Get-ADDomainController` |
| Group Policy | `Get-GPO`, `Get-GPOReport`, `Get-GPInheritance`, `Get-GPResultantSetOfPolicy`, `Invoke-GPUpdate` |
| DNS Server | `Get-DnsServerZone`, `Get-DnsServerResourceRecord`, `Get-DnsServerForwarder`, `Get-DnsServerStatistics` |
| Server features | `Get-WindowsFeature` |
| Windows optional features | `Get-WindowsOptionalFeature` |
| Storage | `Get-Disk`, `Get-Partition`, `Get-Volume`, `Get-PhysicalDisk`, `Get-StoragePool`, `Get-VirtualDisk` |
| Networking | `Get-NetRoute`, `Get-NetNeighbor`, `Get-NetTCPConnection`, `Get-NetFirewallProfile`, `Test-NetConnection` |
| Defender | `Get-MpComputerStatus` |
| BitLocker | `Get-BitLockerVolume` |
| CIM/WMI | `Get-CimInstance`, `New-CimSession`, `Invoke-CimMethod` |
| Event Logs | `Get-WinEvent`, `wevtutil.exe` |
| Windows Update | `Microsoft.Update.Session`, `Microsoft.Update.AutoUpdate` |

For Active Directory, the menu explicitly attempts to import the **ActiveDirectory** PowerShell module and reports an error when it is not available.

On systems without the corresponding RSAT/server-management components, only the unrelated parts of PSFieldKit can be expected to function.

---

# Installation

## Repository-local installation

The simplest way to use the project while developing or testing it is to keep the module directory intact and import the manifest directly.

```powershell
Set-Location .\PSFieldKit
Import-Module .\PSFieldKit.psd1 -Force
```

Then start the main interface:

```powershell
Show-PSFieldKitMenu
```

## Installation into a PowerShell module path

If the `PSFieldKit` directory is placed under a directory listed in `$env:PSModulePath`, it can be imported by module name:

```powershell
Import-Module PSFieldKit
```

The project itself does not contain an installer, package script, PowerShell Gallery publishing configuration, or dependency bootstrapper in the supplied source.

## Recommended import method

Import the **module manifest**:

```powershell
Import-Module .\PSFieldKit.psd1 -Force
```

The manifest identifies `PSFieldKit.psm1` as the root module and controls the explicit export surface.

---

# Starting PSFieldKit

After importing the module:

```powershell
Show-PSFieldKitMenu
```

The main menu contains:

```text
+----------------------------------------------+
|              PSFieldKit v1.0                 |
|        PowerShell SysAdmin Toolkit           |
+----------------------------------------------+
|                                              |
|  [1] Computer Information                    |
|  [2] Network Diagnostics                     |
|  [3] Active Directory                        |
|  [4] Processes & Services                    |
|  [5] Event Logs                              |
|  [6] Storage & Disks                         |
|  [7] Security                                |
|  [8] Remote Administration                   |
|  [9] Software & Updates                      |
|                                              |
|  [0] Exit                                    |
|                                              |
+----------------------------------------------+
```

The main menu creates a target context for most areas. Active Directory is different: the AD menu operates directly through the installed AD-related cmdlets and does not use the common `New-PSFieldKitContext` workflow.

---

# Target model: Local / Remote / Multiple Targets

## Target context

`New-PSFieldKitContext` returns an internal `PSCustomObject` containing the following fields:

| Property | Meaning |
|---|---|
| `ComputerName` | Selected single computer name, or `$null` in multi-target mode |
| `IsRemote` | Indicates whether the context is remote |
| `Session` | PSSession slot; initialized as `$null` |
| `Targets` | Array of target objects with `ComputerName` and `IsRemote` |
| `IsMultiTarget` | Indicates multi-target context |

The common context is passed to the functional menus and then to the individual functions.

## Local Computer

Select:

```text
[1] Local Computer
```

The local host is represented by `$env:COMPUTERNAME` and `IsRemote = $false`.

## Remote Computer

Select:

```text
[2] Remote Computer
```

The user enters a computer name or IP address. The target must pass `Test-WSMan` before the context is accepted.

This means that **WinRM availability is part of target selection**, not merely an optional diagnostic later.

## Multiple Computers

Multiple-target mode is enabled only for the main menu areas that explicitly call:

```powershell
New-PSFieldKitContext -AllowMultipleTargets
```

In the current code this is used by:

- Event Logs
- Remote Administration

The multi-target menu provides:

```text
[1] Computer List
[2] IPv4 Range
[3] IPv4 CIDR
[4] Text File
```

### Computer list

Example:

```text
server01,server02,192.168.10.20
```

Blank entries are ignored and duplicate entries are removed.

### IPv4 range

Example:

```text
192.168.10.10-192.168.10.50
```

The range must contain valid IPv4 addresses, the start must not be greater than the end, and ranges larger than 4096 addresses are rejected.

### IPv4 CIDR

Example:

```text
192.168.10.0/24
```

Only IPv4 CIDR notation is accepted. Prefix lengths from `/1` through `/32` are supported, but networks producing more than 4096 addresses are rejected.

The implementation expands the complete address block from the calculated network address. It does not explicitly remove network/broadcast addresses.

### Text file

Example file:

```text
server01
server02
192.168.10.20
# comments are allowed
```

The loader:

- trims each line,
- ignores empty lines,
- ignores lines beginning with `#`,
- removes duplicates,
- limits the file to 4096 entries.

The entries are then tested for reachability with `Test-WSMan` by the normal target-selection flow.

---

# Main functional areas

## 1. Computer Information

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

The functions use CIM/WMI data and can work against the selected local or single remote context.

### Functions

- `Get-SystemInformation`
- `Get-OperatingSystemInformation`
- `Get-HardwareInformation`
- `Get-CPUInformation`
- `Get-MemoryInformation`
- `Get-DiskInformation`
- `Get-NetworkAdapterInformation`
- `Get-Uptime`
- `Show-ComputerMenu`

### Typical information collected

The implementation includes data such as:

- operating system properties,
- computer/system information,
- processor information and processor counts,
- memory data,
- physical/logical disk information,
- network adapters,
- uptime calculations.

---

## 2. Network Diagnostics

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

### Confirmed functions present in the supplied dump

- `Get-NetworkAdapters`
- `Get-NetworkNeighborTable`
- `Get-RoutingTable`
- `Test-NetworkConnectivity`
- `Get-NetworkStatistics`
- `Get-PortsAndConnections`
- `Get-FirewallInformation`
- `Show-NetworkMenu`

### Additional functions

- `Get-NetworkIPConfiguration`
- `Test-DNSDiagnostics`

### Connectivity tests

`Test-NetworkConnectivity` provides an interactive submenu for a single selected target:

```text
[1] Ping
[2] Test TCP Port
[3] Traceroute
```

The TCP test accepts ports `1..65535` and uses `Test-NetConnection`.

---

## 3. Active Directory

The Active Directory area is the largest subsystem in the project.

The main menu attempts to load:

```powershell
Import-Module ActiveDirectory -ErrorAction Stop
```

If that fails, the menu reports that the Active Directory PowerShell module is not installed and tells the operator to install RSAT / Active Directory tools.

### AD main menu

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

### 3.1 Domain & Forest Information

Menu:

```text
[1] Domain Information
[2] Forest Information
[3] FSMO Roles
[4] Domain Functional Level
[5] Forest Functional Level
[6] Sites & Subnets
```

Functions:

- `Get-ADDomainInformation`
- `Get-ADForestInformation`
- `Get-ADFSMORoles`
- `Get-ADDomainFunctionalLevel`
- `Get-ADForestFunctionalLevel`
- `Get-ADSiteInformation`
- `Show-ADDomainForestMenu`

### 3.2 User Management

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

Functions:

- `Get-ADUserInformation`
- `Search-ADUsers`
- `New-ADUserAccount`
- `Disable-ADUserAccount`
- `Enable-ADUserAccount`
- `Unlock-ADUserAccount`
- `Reset-ADUserPassword`
- `Remove-ADUserAccount`
- `Show-ADUserGroupMembership`
- `Show-ADUserMenu`

Account-changing operations are interactive and include confirmation prompts. User creation and password reset also prompt for temporary password data.

### 3.3 Computer Management

Menu:

```text
[1] Computer Information
[2] Search Computers
[3] Create Computer Account
[4] Enable Computer
[5] Disable Computer
[6] Reset Computer Account
[7] Remove Computer
[8] Last Logon Information
```

Functions:

- `Get-ADComputerInformation`
- `Search-ADComputers`
- `New-ADComputerAccount`
- `Enable-ADComputerAccount`
- `Disable-ADComputerAccount`
- `Reset-ADComputerAccount`
- `Remove-ADComputerAccount`
- `Get-ADComputerLastLogon`
- `Show-ADComputerMenu`

Create/enable/disable/reset actions use confirmation prompts; removal requires explicit `DELETE` confirmation.

### 3.4 Group Management

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

Functions:

- `Get-ADGroupInformation`
- `Search-ADGroups`
- `New-ADGroupAccount`
- `Remove-ADGroupAccount`
- `Add-ADGroupMemberAccount`
- `Remove-ADGroupMemberAccount`
- `Get-ADGroupMembers`
- `Get-ADUserGroupMembership`
- `Get-ADNestedGroupMembership`
- `Show-ADGroupMenu`

Group creation supports Global, DomainLocal, and Universal scope plus Security/Distribution type selection.

### 3.5 Organizational Units

Menu:

```text
[1] OU Tree
[2] OU Information
[3] Search OUs
[4] Create OU
[5] Rename OU
[6] Remove OU
```

Functions:

- `Get-ADOUTree`
- `Get-ADOUInformation`
- `Search-ADOUs`
- `New-PSFKADOrganizationalUnit`
- `Rename-PSFKADOrganizationalUnit`
- `Remove-PSFKADOrganizationalUnit`
- `Show-ADOrganizationalUnitMenu`

OU deletion requires explicit `DELETE` confirmation.

### 3.6 Domain Controllers

Menu:

```text
[1] Domain Controller Information
[2] List Domain Controllers
[3] Services
[4] SYSVOL / NETLOGON
[5] Connectivity
[6] Event Logs
[7] DC Diagnostics
```

Functions:

- `Get-ADDomainControllerInformation`
- `Get-ADDomainControllers`
- `Get-ADDomainControllerServices`
- `Test-ADDomainControllerSYSVOL`
- `Test-ADDomainControllerConnectivity`
- `Get-ADDomainControllerEventLogs`
- `Test-ADDomainControllerDiagnostics`
- `Show-ADDomainControllerMenu`

The DC connectivity test checks:

- DNS resolution
- ICMP reachability
- TCP 53 (DNS)
- TCP 88 (Kerberos)
- TCP 135 (RPC)
- TCP 389 (LDAP)
- TCP 445 (SMB)
- TCP 3268 (Global Catalog)
- TCP 5985 (WinRM)

### 3.7 Group Policy

Menu:

```text
[1] GPO Information
[2] Search GPOs
[3] GPO Links
[4] GPO Permissions
[5] Generate GPReport
[6] Force GPUpdate
[7] Group Policy Results
[8] Group Policy Modeling
[9] GPO Diagnostics
```

Functions:

- `Get-ADGPOInformation`
- `Search-ADGPOs`
- `Get-ADGPOLinks`
- `Get-ADGPOPermissions`
- `Get-ADGPReport`
- `Invoke-ADGPUpdate`
- `Get-ADGroupPolicyResults`
- `Get-ADGroupPolicyModeling`
- `Test-ADGPODiagnostics`
- `Show-ADGPOMenu`

Report generation supports HTML and XML output choices in the interactive workflow.

### 3.8 Replication

Menu:

```text
[1] Replication Status
[2] Replication Partners
[3] Replication Failures
[4] Replication Metadata
[5] Synchronize Replication
[6] Replication Summary
[7] Repadmin Diagnostics
```

Functions:

- `Get-ADReplicationStatus`
- `Get-ADReplicationPartners`
- `Get-ADReplicationFailures`
- `Get-ADReplicationMetadata`
- `Sync-ADReplication`
- `Get-ADReplicationSummary`
- `Test-ADReplicationDiagnostics`
- `Show-ADReplicationMenu`

The replication functions use Active Directory replication metadata/failure/partner cmdlets and `Sync-ADObject` where object-specific synchronization is requested.

### 3.9 Trusts

Menu:

```text
[1] Trust Information
[2] List Domain Trusts
[3] Test Trust
[4] Forest Trust Information
[5] Trust Diagnostics
```

Functions:

- `Get-ADTrustInformation`
- `Get-ADDomainTrusts`
- `Test-ADTrust`
- `Get-ADForestTrustInformation`
- `Test-ADTrustDiagnostics`
- `Show-ADTrustMenu`

### 3.10 AD Diagnostics

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

Functions:

- `Get-ADHealthSummary`
- `Test-ADDCDIAG`
- `Test-ADDNSDiagnostics`
- `Test-ADLDAPConnectivity`
- `Test-ADKerberos`
- `Test-ADTimeSynchronization`
- `Test-ADSYSVOLNetlogon`
- `Show-ADDiagnosticsMenu`

### 3.11 AD Search

Menu:

```text
[1] Search All Objects
[2] Search by LDAP Filter
```

Functions:

- `Search-ADObjects`
- `Search-ADLDAPFilter`
- `Show-ADSearchMenu`

### 3.12 AD DNS

Menu:

```text
[1] DNS Server Information
[2] DNS Zones
[3] Zone Information
[4] DNS Records
[5] DNS Forwarders
[6] DNS Scavenging
[7] DNS Server Statistics
```

Functions:

- `Get-ADDnsServerInformation`
- `Get-ADDnsZones`
- `Get-ADDnsZoneInformation`
- `Get-ADDnsRecords`
- `Get-ADDnsForwarders`
- `Get-ADDnsScavenging`
- `Get-ADDnsServerStatistics`
- `Show-ADDnsMenu`

The implementation uses DNS Server PowerShell cmdlets such as `Get-DnsServerZone`, `Get-DnsServerResourceRecord`, `Get-DnsServerForwarder`, `Get-DnsServerScavenging`, and `Get-DnsServerStatistics`.

---

## 4. Processes & Services

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

Functions:

- `Get-ProcessInformation`
- `Get-RunningProcesses`
- `Get-ProcessDetails`
- `Get-ServiceInformation`
- `Get-RunningServices`
- `Start-PSFieldKitService`
- `Stop-PSFieldKitService`
- `Restart-PSFieldKitService`
- `Get-ServiceDependencies`
- `Show-ProcessServiceMenu`

The process/service implementation uses CIM sessions and CIM methods, allowing the same menu to operate on the selected local or single remote target.

Service-changing actions call CIM methods and therefore require appropriate rights on the target system.

---

## 5. Event Logs

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

This is one of the areas that enables multi-target mode.

### Functions

- `Get-SystemEventLog`
- `Get-ApplicationEventLog`
- `Get-SecurityEventLog`
- `Get-PowerShellEventLog`
- `Get-WindowsEventChannels`
- `Search-PSFieldKitEventLog`
- `Get-EventLogInformation`
- `Clear-PSFieldKitEventLog`
- `Export-EventLogs`
- `Show-EventLogMenu`

### Event search

`Search-PSFieldKitEventLog` supports filters for:

- event log name,
- Event ID,
- level (`Critical`, `Error`, `Warning`, `Information`, `Verbose`, or `All`),
- provider name,
- message text,
- start time,
- end time,
- maximum events per target.

The default maximum is **100 events per target**.

### Clear Event Log

`Clear-PSFieldKitEventLog`:

- defaults to the `System` log,
- supports local and multiple remote targets,
- uses `wevtutil.exe`,
- requires the operator to type `CLEAR` before proceeding.

This is a destructive operation and permanently removes the selected event log contents.

### Event log export

`Export-EventLogs` is significantly more extensive than the simple event viewers.

Defaults:

| Setting | Default |
|---|---|
| Logs | `System,Application,Security` |
| Time range | 30 days |
| Timeout per log | 600 seconds |
| Overwrite | No |
| Create ZIP | No |
| Destination | `C:\PSFieldKit\EventLogs` |

The export workflow creates a timestamped run directory and records metadata including:

- run ID,
- operator,
- export host,
- UTC timestamps,
- requested logs,
- time range,
- target count,
- result status,
- exported event count when available,
- file size,
- SHA-256 hash,
- destination path,
- errors.

It also writes:

- `ExportReport.csv`
- `ExportManifest.json`

Optional ZIP creation is supported. The export directory can optionally be deleted after the ZIP is successfully created.

For remote exports the implementation uses a path under the remote administrative share:

```text
\\<computer>\c$\Windows\Temp\...
```

and invokes `wevtutil.exe` remotely through the export workflow. Administrative access to the remote system is therefore required for that workflow.

---

## 6. Storage & Disks

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

Functions:

- `Get-DiskInformation`
- `Get-PartitionInformation`
- `Get-VolumeInformation`
- `Get-FreeSpace`
- `Get-DiskHealth`
- `Get-MountedDrives`
- `Get-DiskUsage`
- `Get-StorageSpaces`
- `Update-PSFieldKitDisk`
- `Show-StorageMenu`

The code uses storage cmdlets such as:

- `Get-Disk`
- `Get-Partition`
- `Get-Volume`
- `Get-PhysicalDisk`
- `Get-StoragePool`
- `Get-VirtualDisk`
- `Update-Disk`

`Update-PSFieldKitDisk` performs a disk rescan operation and is therefore not purely informational.

---

## 7. Security

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

Functions:

- `Get-LocalAccounts`
- `Get-LocalGroups`
- `Get-SecurityPolicy`
- `Get-AuditPolicy`
- `Get-Certificates`
- `Get-DefenderStatus`
- `Get-BitLockerStatus`
- `Get-LoggedOnUsers`
- `Show-SecurityMenu`

### Security Policy

`Get-SecurityPolicy` exports the local security policy with `secedit.exe`, parses the resulting configuration, and presents selected settings such as:

- minimum password length,
- maximum password age,
- minimum password age,
- password history size,
- password complexity,
- lockout threshold,
- lockout duration,
- lockout reset counter,
- administrator account state,
- guest account state.

### Certificates

`Get-Certificates` reads from:

```text
Cert:\LocalMachine\<store>
```

The default store input is `My`. Optional subject filtering is supported.

Reported fields include:

- Subject
- Issuer
- Thumbprint
- validity dates
- private-key presence
- friendly name

### Defender

`Get-DefenderStatus` uses `Get-MpComputerStatus`.

### BitLocker

`Get-BitLockerStatus` uses `Get-BitLockerVolume`.

---

## 8. Remote Administration

Remote Administration is the most operationally sensitive part of the toolkit and explicitly supports multi-target mode.

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

The menu enables actions according to the selected target mode.

### Availability by target mode

| Function | Local | Single Remote | Multiple Remote |
|---|:---:|:---:|:---:|
| Test Remote Connectivity | No | Yes | Yes |
| Test WinRM | No | Yes | Yes |
| Enter Remote PowerShell | No | Yes | No |
| Remove PSSession | No | Yes | No |
| Session Information | No | Yes | No |
| Invoke Remote Command | No | Yes | Yes |
| Invoke Remote Script | No | Yes | Yes |
| CIM / WMI Remote Query | No | Yes | Yes |
| Remote Computer Management | No | Yes | No |
| RDP Session Shadowing | No | Yes | No |
| Remote Reboot / Shutdown | No | Yes | Yes |

### Remote connectivity

`Test-PSFieldKitConnection` performs two ICMP requests and calculates the average response time.

### WinRM test

`Test-PSFieldKitWinRM` uses `Test-WSMan` and reports:

- protocol version,
- product vendor,
- product version,
- availability/errors.

### Remote command execution

`Invoke-PSFieldKitCommand` prompts for a PowerShell command, converts it to a script block, and invokes it on every target in the context.

Example input:

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime
```

### Remote script execution

`Invoke-PSFieldKitScript`:

- validates that the local file exists,
- requires the `.ps1` extension,
- resolves the path,
- invokes the script with `Invoke-Command -FilePath` against each target.

Example:

```text
C:\Tools\Check-Server.ps1
```

### CIM / WMI remote query

`Invoke-PSFieldKitCimQuery` prompts for:

- CIM namespace (default: `root/cimv2`),
- class name,
- optional WQL filter.

It creates a CIM session per target and executes `Get-CimInstance`.

Example inputs:

```text
Namespace: root/cimv2
Class: Win32_OperatingSystem
Filter: Version -like "10.*"
```

### Remote Computer Management

`Show-RemoteComputerManagement` launches Windows management consoles against the selected remote host:

- Computer Management
- Event Viewer
- Services
- Task Scheduler
- Disk Management
- Device Manager
- Shared Folders

It uses local MMC executables with the remote computer name.

### RDP Session Shadowing

`Invoke-PSFieldKitSessionShadowing`:

1. runs `qwinsta.exe /server:<host>`,
2. identifies active user sessions,
3. prompts for a session ID,
4. supports either:
   - view-only mode,
   - control mode.

Control mode explicitly requires typing `YES` before starting `mstsc.exe /shadow` with `/control`.

### Remote reboot and shutdown

`Restart-PSFieldKitComputer` supports:

```text
[1] Restart computer
[2] Shutdown computer
```

Before the action is executed the operator must type `YES`.

The function can iterate over multiple remote targets.

---

## 9. Software & Updates

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

Functions:

- `Get-InstalledSoftware`
- `Get-SoftwareDetails`
- `Get-WindowsFeatureInformation`
- `Get-WindowsUpdateStatus`
- `Get-AvailableUpdates`
- `Get-InstalledUpdates`
- `Get-UpdateHistory`
- `Find-WindowsUpdates`
- `Get-PendingRebootStatus`
- `Show-SoftwareMenu`

### Installed software

`Get-InstalledSoftware` reads Windows uninstall registry locations including:

```text
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
```

### Windows features

`Get-WindowsFeatureInformation` checks whether `Get-WindowsFeature` is available and also uses `Get-WindowsOptionalFeature` where applicable.

### Windows Update

The update subsystem uses the Windows Update COM API through:

```text
Microsoft.Update.Session
Microsoft.Update.AutoUpdate
```

It provides:

- Windows Update service status
- available updates
- installed updates
- update history
- pending reboot status
- initiating Windows Update detection

`Find-WindowsUpdates` starts an update detection cycle rather than installing updates.

---

# Module architecture

The project uses a script-module architecture.

## `PSFieldKit.psm1`

The root module script loads every `.ps1` under `Private` and every `.ps1` under `Public` recursively.

The loading order is:

```powershell
Private -> alphabetical sort -> dot-source
Public  -> alphabetical sort -> dot-source
```

The files are therefore loaded into the module scope rather than being separately imported as nested modules.

## `PSFieldKit.psd1`

The manifest:

- identifies `PSFieldKit.psm1` as `RootModule`,
- reports module version `0.1.0`,
- sets author to `jacob`,
- describes the module as a PowerShell toolkit for system administrators,
- declares no `RequiredModules`,
- declares only `Show-PSFieldKitMenu` under `FunctionsToExport`.

Private metadata also contains tags such as:

```text
PowerShell
SysAdmin
Windows
Administration
Networking
```

The manifest does not define a license URI, project URI, icon URI, release notes URL, or explicit PowerShell version requirement.

---

# Exported command surface

The manifest explicitly exports only:

```powershell
Show-PSFieldKitMenu
```

This is important: the `Public` directory contains many functions, but directory placement alone does not make them exported module commands.

For the intended user workflow, PSFieldKit is therefore primarily a **menu-driven tool** with `Show-PSFieldKitMenu` as its public entry point.

Verify the export surface with:

```powershell
Get-Command -Module PSFieldKit
```

---

# Examples

## Start the toolkit

```powershell
Import-Module .\PSFieldKit.psd1 -Force
Show-PSFieldKitMenu
```

## Check the exported command

```powershell
Get-Command -Module PSFieldKit
```

## Remote administration workflow

1. Run `Show-PSFieldKitMenu`.
2. Select `8` for **Remote Administration**.
3. Select `2` for **Remote Computer** or `3` for **Multiple Computers**.
4. Enter the target.
5. The toolkit tests WinRM with `Test-WSMan`.
6. Use the appropriate remote administration operation.

## Multiple target event-log workflow

1. Start `Show-PSFieldKitMenu`.
2. Select `5` for **Event Logs**.
3. Select `3` for **Multiple Computers**.
4. Choose one of:
   - Computer List
   - IPv4 Range
   - IPv4 CIDR
   - Text File
5. Allow PSFieldKit to test the targets.
6. Select Event Log Search, Clear, or Export as required.

## Multi-target command execution

1. Open **Remote Administration**.
2. Select **Multiple Computers**.
3. Choose **Invoke Remote Command**.
4. Enter a PowerShell command.
5. The command is sent to each reachable target.

Example command:

```powershell
Get-Service WinRM | Select-Object Name, Status, StartType
```

---

# Permissions and administrative rights

PSFieldKit does not implement privilege escalation. Operations execute under the current PowerShell security context and therefore depend on the operator's existing permissions.

Expect elevated or delegated rights to be required for operations such as:

- creating/removing/enabling/disabling/resetting AD accounts,
- changing AD group membership,
- creating/removing/renaming OUs,
- Group Policy operations,
- replication synchronization,
- manipulating Windows services,
- restarting or shutting down remote computers,
- clearing event logs,
- remote event-log export through administrative shares,
- remote RDP session shadowing,
- accessing protected security/certificate information.

The exact required permissions depend on the target OS, domain configuration, delegated AD rights, WinRM configuration, firewall policy, Remote Desktop policy, and the particular operation being performed.

---

# Security considerations

PSFieldKit performs real administrative actions. Treat it as an administration tool, not as a read-only diagnostic viewer.

## High-impact operations

The following code paths can change or destroy system/domain state:

- `New-ADUserAccount`
- `Remove-ADUserAccount`
- `Disable-ADUserAccount`
- `Enable-ADUserAccount`
- `Unlock-ADUserAccount`
- `Reset-ADUserPassword`
- `New-ADComputerAccount`
- `Remove-ADComputerAccount`
- `Disable-ADComputerAccount`
- `Enable-ADComputerAccount`
- `Reset-ADComputerAccount`
- `New-ADGroupAccount`
- `Remove-ADGroupAccount`
- `Add-ADGroupMemberAccount`
- `Remove-ADGroupMemberAccount`
- `New-PSFKADOrganizationalUnit`
- `Rename-PSFKADOrganizationalUnit`
- `Remove-PSFKADOrganizationalUnit`
- `Sync-ADReplication`
- `Start-PSFieldKitService`
- `Stop-PSFieldKitService`
- `Restart-PSFieldKitService`
- `Clear-PSFieldKitEventLog`
- `Update-PSFieldKitDisk`
- `Invoke-PSFieldKitCommand`
- `Invoke-PSFieldKitScript`
- `Restart-PSFieldKitComputer`

Particularly sensitive are the generic remote execution functions because the operator supplies arbitrary PowerShell code or a PowerShell script path.

## Remote execution

`Invoke-PSFieldKitCommand` and `Invoke-PSFieldKitScript` intentionally provide a mechanism to execute code on remote targets. Anyone with sufficient access to the module's runtime environment should be treated as an operator with significant administrative capability.

## Event logs

`Clear-PSFieldKitEventLog` permanently clears the selected event log after explicit confirmation.

`Export-EventLogs` writes `.evtx` files and supporting metadata to disk. These files may contain sensitive security, authentication, user, system, and application information.

## Credentials and secrets

The source does not contain a built-in credential vault or credential-management system. Remote operations rely on the current PowerShell/Windows security context and the underlying Windows remoting mechanisms.

---

# Known limitations

The following limitations are directly visible in the supplied implementation:

1. **Interactive console workflow** — the project is primarily operated through `Read-Host`-driven menus rather than a conventional set of parameter-rich exported PowerShell commands.
2. **Remote target selection requires WinRM** — `New-PSFieldKitContext` uses `Test-WSMan` to validate remote targets before the context is accepted.
3. **Multi-target mode is selective** — only Event Logs and Remote Administration enable `-AllowMultipleTargets` from the main menu.
4. **Multi-target address/input limit** — range/CIDR/file target input is capped at 4096 addresses/entries.
5. **IPv4-only expansion** — range and CIDR target generation supports IPv4 only.
6. **CIDR expansion includes the full block** — network/broadcast addresses are not explicitly excluded.
7. **No automatic session object creation in the common context** — `Context.Session` starts as `$null`.
8. **The project does not declare formal PowerShell/Windows version requirements in the manifest.**
9. **Dependencies are not declared through `RequiredModules`.**
10. **Only `Show-PSFieldKitMenu` is exported by the manifest.**

---


# Project structure

The supplied project tree is organized as follows:

```text
PSFieldKit/
├── Private/
│   ├── Get-PSFieldKitTargets.ps1
│   ├── New-PSFieldKitContext.ps1
│   ├── Test-PSFieldKitMenuOption.ps1
│   ├── Test-PSFieldKitTarget.ps1
│   └── Write-PSFieldKitMenuOption.ps1
├── PSFieldKit.psd1
├── PSFieldKit.psm1
└── Public/
    ├── ActiveDirectory/
    │   ├── ComputerManagement/
    │   ├── Diagnostics/
    │   ├── DNS/
    │   ├── DomainControllers/
    │   ├── DomainForest/
    │   ├── GroupManagement/
    │   ├── GroupPolicy/
    │   ├── OrganizationalUnits/
    │   ├── Replication/
    │   ├── Search/
    │   ├── Trusts/
    │   └── UserManagement/
    ├── ComputerInformation/
    ├── EventLogs/
    ├── NetworkDiagnostics/
    ├── ProcessesServices/
    ├── RemoteAdministration/
    ├── Security/
    ├── SoftwareUpdates/
    ├── StorageDisks/
    └── Show-PSFieldKitMenu.ps1
```

The supplied project tree reports **24 directories and 183 files**.

---

# Function inventory

The following inventory preserves the function names present in the supplied source.

## Private functions

- `Get-PSFieldKitTargets`
- `New-PSFieldKitContext`
- `Test-PSFieldKitMenuOption`
- `Test-PSFieldKitTarget`
- `Write-PSFieldKitMenuOption`

## Public: ComputerInformation

- `Show-ComputerMenu`
- `Get-SystemInformation`
- `Get-OperatingSystemInformation`
- `Get-HardwareInformation`
- `Get-CPUInformation`
- `Get-MemoryInformation`
- `Get-DiskInformation`
- `Get-NetworkAdapterInformation`
- `Get-Uptime`

## Public: NetworkDiagnostics

- `Show-NetworkMenu`
- `Get-NetworkAdapters`
- `Get-NetworkIPConfiguration`
- `Get-RoutingTable`
- `Get-NetworkNeighborTable`
- `Test-DNSDiagnostics`
- `Test-NetworkConnectivity`
- `Get-PortsAndConnections`
- `Get-NetworkStatistics`
- `Get-FirewallInformation`

## Public: ActiveDirectory / ComputerManagement

- `Show-ADComputerMenu`
- `Get-ADComputerInformation`
- `Search-ADComputers`
- `New-ADComputerAccount`
- `Enable-ADComputerAccount`
- `Disable-ADComputerAccount`
- `Reset-ADComputerAccount`
- `Remove-ADComputerAccount`
- `Get-ADComputerLastLogon`

## Public: ActiveDirectory / Diagnostics

- `Show-ADDiagnosticsMenu`
- `Get-ADHealthSummary`
- `Test-ADDCDIAG`
- `Test-ADDNSDiagnostics`
- `Test-ADLDAPConnectivity`
- `Test-ADKerberos`
- `Test-ADTimeSynchronization`
- `Test-ADSYSVOLNetlogon`

## Public: ActiveDirectory / DNS

- `Show-ADDnsMenu`
- `Get-ADDnsServerInformation`
- `Get-ADDnsZones`
- `Get-ADDnsZoneInformation`
- `Get-ADDnsRecords`
- `Get-ADDnsForwarders`
- `Get-ADDnsScavenging`
- `Get-ADDnsServerStatistics`

## Public: ActiveDirectory / DomainControllers

- `Show-ADDomainControllerMenu`
- `Get-ADDomainControllerInformation`
- `Get-ADDomainControllers`
- `Get-ADDomainControllerServices`
- `Test-ADDomainControllerSYSVOL`
- `Test-ADDomainControllerConnectivity`
- `Get-ADDomainControllerEventLogs`
- `Test-ADDomainControllerDiagnostics`

## Public: ActiveDirectory / DomainForest

- `Show-ADDomainForestMenu`
- `Get-ADDomainInformation`
- `Get-ADForestInformation`
- `Get-ADFSMORoles`
- `Get-ADDomainFunctionalLevel`
- `Get-ADForestFunctionalLevel`
- `Get-ADSiteInformation`

## Public: ActiveDirectory / GroupManagement

- `Show-ADGroupMenu`
- `Get-ADGroupInformation`
- `Search-ADGroups`
- `New-ADGroupAccount`
- `Remove-ADGroupAccount`
- `Add-ADGroupMemberAccount`
- `Remove-ADGroupMemberAccount`
- `Get-ADGroupMembers`
- `Get-ADUserGroupMembership`
- `Get-ADNestedGroupMembership`

## Public: ActiveDirectory / GroupPolicy

- `Show-ADGPOMenu`
- `Get-ADGPOInformation`
- `Search-ADGPOs`
- `Get-ADGPOLinks`
- `Get-ADGPOPermissions`
- `Get-ADGPReport`
- `Invoke-ADGPUpdate`
- `Get-ADGroupPolicyResults`
- `Get-ADGroupPolicyModeling`
- `Test-ADGPODiagnostics`

## Public: ActiveDirectory / OrganizationalUnits

- `Show-ADOrganizationalUnitMenu`
- `Get-ADOUTree`
- `Get-ADOUInformation`
- `Search-ADOUs`
- `New-PSFKADOrganizationalUnit`
- `Rename-PSFKADOrganizationalUnit`
- `Remove-PSFKADOrganizationalUnit`

## Public: ActiveDirectory / Replication

- `Show-ADReplicationMenu`
- `Get-ADReplicationStatus`
- `Get-ADReplicationPartners`
- `Get-ADReplicationFailures`
- `Get-ADReplicationMetadata`
- `Sync-ADReplication`
- `Get-ADReplicationSummary`
- `Test-ADReplicationDiagnostics`

## Public: ActiveDirectory / Search

- `Show-ADSearchMenu`
- `Search-ADObjects`
- `Search-ADLDAPFilter`

## Public: ActiveDirectory / Trusts

- `Show-ADTrustMenu`
- `Get-ADTrustInformation`
- `Get-ADDomainTrusts`
- `Test-ADTrust`
- `Get-ADForestTrustInformation`
- `Test-ADTrustDiagnostics`

## Public: ActiveDirectory / UserManagement

- `Show-ADUserMenu`
- `Get-ADUserInformation`
- `Search-ADUsers`
- `New-ADUserAccount`
- `Disable-ADUserAccount`
- `Enable-ADUserAccount`
- `Unlock-ADUserAccount`
- `Reset-ADUserPassword`
- `Remove-ADUserAccount`
- `Show-ADUserGroupMembership`

## Public: EventLogs

- `Show-EventLogMenu`
- `Get-SystemEventLog`
- `Get-ApplicationEventLog`
- `Get-SecurityEventLog`
- `Get-PowerShellEventLog`
- `Get-WindowsEventChannels`
- `Search-PSFieldKitEventLog`
- `Get-EventLogInformation`
- `Clear-PSFieldKitEventLog`
- `Export-EventLogs`

## Public: ProcessesServices

- `Show-ProcessServiceMenu`
- `Get-ProcessInformation`
- `Get-RunningProcesses`
- `Get-ProcessDetails`
- `Get-ServiceInformation`
- `Get-RunningServices`
- `Start-PSFieldKitService`
- `Stop-PSFieldKitService`
- `Restart-PSFieldKitService`
- `Get-ServiceDependencies`

## Public: RemoteAdministration

- `Show-RemoteAdministrationMenu`
- `Test-PSFieldKitConnection`
- `Test-PSFieldKitWinRM`
- `Enter-PSFieldKitRemotePowerShell`
- `Remove-PSFieldKitSession`
- `Get-PSFieldKitSession`
- `Invoke-PSFieldKitCommand`
- `Invoke-PSFieldKitScript`
- `Invoke-PSFieldKitCimQuery`
- `Show-RemoteComputerManagement`
- `Invoke-PSFieldKitSessionShadowing`
- `Restart-PSFieldKitComputer`

## Public: Security

- `Show-SecurityMenu`
- `Get-LocalAccounts`
- `Get-LocalGroups`
- `Get-SecurityPolicy`
- `Get-AuditPolicy`
- `Get-Certificates`
- `Get-DefenderStatus`
- `Get-BitLockerStatus`
- `Get-LoggedOnUsers`

## Public: SoftwareUpdates

- `Show-SoftwareMenu`
- `Get-InstalledSoftware`
- `Get-SoftwareDetails`
- `Get-WindowsFeatureInformation`
- `Get-WindowsUpdateStatus`
- `Get-AvailableUpdates`
- `Get-InstalledUpdates`
- `Get-UpdateHistory`
- `Find-WindowsUpdates`
- `Get-PendingRebootStatus`

## Public: StorageDisks

- `Show-StorageMenu`
- `Get-DiskInformation`
- `Get-PartitionInformation`
- `Get-VolumeInformation`
- `Get-FreeSpace`
- `Get-DiskHealth`
- `Get-MountedDrives`
- `Get-DiskUsage`
- `Get-StorageSpaces`
- `Update-PSFieldKitDisk`

---

# Development notes

The current source tree is intentionally organized around small, single-purpose `.ps1` files. Functions are loaded centrally by `PSFieldKit.psm1` rather than through separate submodules.

The private helper layer centralizes:

- target/context creation,
- multi-target parsing,
- WinRM target validation,
- target-mode menu availability checks,
- menu rendering.

The public layer is arranged by administrative domain and each domain generally contains both:

- a `Show-*Menu` function,
- one or more operational functions.

This makes the source tree relatively easy to navigate by task area even though only the main menu is exported to consumers of the manifest.

---

# License

No `LICENSE` file or `LicenseUri` value was present in the supplied project metadata.

The module manifest contains the copyright statement:

```text
(c) 2026 jacob. All rights reserved.
```

However, a copyright statement is **not** a substitute for an explicit open-source license.

> **License placeholder:** choose and add an explicit license file (for example `LICENSE`) before publishing the repository as an open-source project. Update `PSFieldKit.psd1` metadata accordingly if required.

---

# Summary

PSFieldKit is a console-oriented Windows administration toolkit built as a PowerShell script module. Its architecture is centered around a common target context for local and remote system operations, with dedicated functional areas for Active Directory, networking, processes/services, event logs, storage, security, software/updates, and remote administration.

The strongest architectural characteristics visible in the current code are:

- one main interactive entry point: `Show-PSFieldKitMenu`,
- recursive dot-sourcing through `PSFieldKit.psm1`,
- target-aware functions built around `PSCustomObject` context objects,
- selective multi-target support,
- extensive use of Windows-native administration interfaces,
- a large Active Directory subsystem,
- destructive operations guarded by explicit interactive confirmations in many places.

