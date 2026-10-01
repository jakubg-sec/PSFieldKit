# Changelog

All notable changes to PSFieldKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/).

---

## [1.2.0] - 2026-10-01

### Added

#### Exchange Administration

- Added dedicated Exchange administration area to the main PSFieldKit menu.
- Added Exchange context and connection handling.
- Added Exchange environment/status validation before Exchange-specific operations.
- Added Exchange mailbox administration workflows.
- Added mailbox overview and reporting.
- Added reporting for users with Exchange mailboxes.
- Added reporting for disabled Active Directory users with mailboxes.
- Added reporting for inactive users with mailboxes.
- Added reporting for users whose AD lifecycle state may require review while an Exchange mailbox still exists.
- Added disconnected mailbox inspection.
- Added shared mailbox administration.
- Added mailbox permission management workflows.
- Added Full Access management.
- Added Send As management.
- Added Send on Behalf management.
- Added mailbox email-address and alias inspection.
- Added mailbox retention configuration inspection.
- Added mailbox hold and retention information.
- Added Exchange reporting/export functionality.
- Added Exchange-focused workflows for reviewing AD and mailbox state together.
- Added explicit separation between standard AD administration and Exchange administration.

#### Security Auditing Documentation and Integration

- Expanded the project documentation to fully cover the Security Auditing subsystem.
- Documented Security Audit Overview functionality.
- Documented suspicious activity analysis.
- Documented authentication auditing.
- Documented privileged-account activity auditing.
- Documented persistence and autorun auditing.
- Documented PowerShell activity analysis.
- Documented audit-policy and logging checks.
- Documented security report generation.
- Documented archived Event Log analysis.
- Documented local security auditing.
- Documented single-remote security auditing.
- Documented multi-target security auditing.
- Documented configurable security-analysis time ranges.

#### Target Context

- Expanded documentation of the shared target-context architecture.
- Documented local, single-remote and multi-target workflows.
- Documented multi-target acquisition through:
  - computer lists
  - IPv4 ranges
  - IPv4 CIDR
  - text files
- Documented target validation through WinRM.
- Documented the 4096-entry multi-target limit.
- Documented IPv4-specific range and CIDR expansion behavior.

#### Documentation

- Reworked `README.md` into a complete project-level documentation page.
- Added documentation for all main PSFieldKit administration categories.
- Added detailed Active Directory documentation.
- Added detailed Event Log documentation.
- Added detailed Remote Administration documentation.
- Added Storage and Disk documentation.
- Added Security subsystem documentation.
- Added Windows Software and Update documentation.
- Added Security Auditing documentation.
- Added Exchange documentation.
- Added module architecture documentation.
- Added target/context documentation.
- Added security considerations.
- Added destructive-operation warnings.
- Added known limitations.
- Added project structure documentation.
- Added installation and usage examples.
- Added versioning and contribution guidance.

### Changed

- Updated the project documentation to reflect the current main menu.
- Updated the documented main menu from the earlier nine-category layout to the current administration layout.
- Added Security Auditing to the documented main menu.
- Added Exchange to the documented main menu.
- Updated the documented version target to `1.2.0`.
- Expanded documentation from a basic project overview into a full operator reference.
- Clarified the distinction between:
  - source-tree public functions
  - internal functions
  - explicitly exported module commands
  - the interactive `Show-PSFieldKitMenu` entry point.
- Clarified the relationship between Active Directory state and Exchange mailbox state.
- Clarified that Exchange-related operations depend on the available Exchange Management Shell environment.
- Clarified the difference between diagnostic functionality and state-changing administrative operations.
- Expanded documentation of remote execution and administrative requirements.
- Expanded documentation of Event Log handling and security-sensitive data.
- Expanded documentation of multi-target behavior.
- Expanded documentation of PSFieldKit's native Windows tooling approach.

### Security

- Added explicit documentation of Exchange mailbox and recipient data as potentially sensitive administrative information.
- Added explicit documentation of Exchange delegation and permission changes as administrative operations.
- Added explicit documentation of remote PowerShell execution capabilities.
- Added explicit documentation of Event Log exports as potentially sensitive data.
- Added explicit documentation of destructive operations.
- Added explicit documentation that PSFieldKit does not implement a separate credential vault.
- Added security guidance around Security Auditing results and investigation findings.

### Maintenance

- Synchronized release documentation around the planned `1.2.0` version.
- Documented the need to keep the following version indicators synchronized:
  - `PSFieldKit.psd1`
  - main menu version banner
  - `README.md`
  - `CHANGELOG.md`

---

## [1.1.0] - 2026-09-20

### Added

- Security Audit Overview.
- Suspicious activity analysis.
- Authentication auditing.
- Privileged account activity auditing.
- Persistence and autoruns auditing.
- PowerShell activity auditing.
- Audit policy and logging checks.
- Security report generation.
- Archived Event Log analysis.
- Security auditing for local computers.
- Security auditing for single remote computers.
- Security auditing for multiple remote targets.
- Configurable security analysis time ranges.
- Security event analysis and investigation-focused summaries.

---

## [1.0.1] - 2026-09-20

### Added

- Added a dedicated Security Auditing category.
- Added a dedicated Security Auditing menu.
- Added the first structure for security-focused analysis.

### Changed

- Improved menu layout and navigation.
- Made usability improvements throughout the interactive menus.
- Improved organization of administrative menu options.

---

## [1.0.0] - 2026-09-20

### Added

- Initial stable release of PSFieldKit.
- Interactive console-based administration menu.
- Computer and hardware information.
- Network configuration and connectivity diagnostics.
- Active Directory administration and diagnostics.
- Domain Controller information and diagnostics.
- Active Directory replication diagnostics.
- Active Directory trust diagnostics.
- Group Policy inspection and execution.
- DNS administration and diagnostics.
- Process and Windows service management.
- Windows Event Log inspection and management.
- Event Log search functionality.
- Event Log clearing functionality.
- Event Log export functionality.
- Storage, disk, volume and partition information.
- Storage Spaces information.
- Local security configuration and security-state inspection.
- BitLocker status and management information.
- Microsoft Defender status.
- Installed software inspection.
- Windows Update inspection.
- Remote PowerShell administration.
- Remote CIM/WMI administration.
- Remote command execution.
- Remote script execution.
- Remote computer administration using Windows MMC tools.
- RDP session management and shadowing.
- Remote computer restart and shutdown.
- Support for multiple remote targets in selected features.
- Target selection using:
  - single computer name
  - single IP address
  - comma-separated target lists
  - IPv4 ranges
  - IPv4 CIDR networks
  - target files
- Separation of `Public` and `Private` module functions.
- PowerShell module manifest.
- PowerShell script-module implementation.

### Security

- Added administrative operations requiring elevated privileges.
- Added WinRM-based remote target validation.
- Added target-aware handling of remote administration features.
- Added confirmation safeguards around selected high-impact operations.

---

## [Unreleased]

### Added

- Additional administrative and diagnostic functionality.
- Additional Exchange administration capabilities.
- Additional security auditing improvements.

### Changed

- Ongoing improvements to internal function organization.
- Ongoing improvements to menu navigation.
- Ongoing improvements to output formatting.
- Ongoing improvements to validation and error handling.
- Ongoing improvements to the overall operator experience.

### Fixed

- Minor bugs and edge cases identified during development and testing.

---

# Versioning

PSFieldKit follows Semantic Versioning:

```text
MAJOR.MINOR.PATCH
```

- **MAJOR** — incompatible or major architectural changes
- **MINOR** — new backward-compatible functionality
- **PATCH** — backward-compatible bug fixes

Examples:

```text
1.0.0 -> 1.1.0
New functionality

1.1.0 -> 1.2.0
New functionality

1.2.0 -> 1.2.1
Backward-compatible fixes

1.2.0 -> 2.0.0
Major or breaking changes
```