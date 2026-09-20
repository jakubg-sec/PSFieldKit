# Changelog

All notable changes to PSFieldKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

* New administration and diagnostic features.
* Improvements to interactive menu navigation.
* Additional validation and error handling.

### Changed

* Ongoing improvements to code structure and internal functions.
* Improvements to output formatting and user experience.

### Fixed

* Minor bugs and edge cases discovered during testing.

---

## [1.0.0] - 2026-09-20

### Added

* Initial stable release of PSFieldKit.
* Interactive console-based administration menu.
* Computer and hardware information.
* Network configuration and connectivity diagnostics.
* Active Directory administration and diagnostics.
* Domain Controller information and diagnostics.
* Active Directory replication diagnostics.
* Active Directory trust diagnostics.
* Group Policy inspection and execution.
* DNS administration and diagnostics.
* Process and Windows service management.
* Windows Event Log inspection and management.
* Event Log search, clearing and export functionality.
* Storage, disk, volume and partition information.
* Storage Spaces information.
* Local security configuration and security-state inspection.
* BitLocker status and management information.
* Microsoft Defender status.
* Installed software inspection.
* Windows Update inspection.
* Remote PowerShell administration.
* Remote CIM/WMI administration.
* Remote command and script execution.
* Remote computer administration using Windows MMC tools.
* RDP session management and shadowing.
* Remote computer restart and shutdown.
* Support for multiple remote targets in selected features.
* Target selection using:

  * Single computer name or IP address.
  * Comma-separated target lists.
  * IPv4 ranges.
  * IPv4 CIDR networks.
  * Text files containing targets.
* Separation of `Public` and `Private` module functions.
* PowerShell module manifest (`PSFieldKit.psd1`).
* PowerShell module implementation (`PSFieldKit.psm1`).

### Security

* Added administrative operations requiring elevated privileges.
* Added connectivity validation before accepting remote targets.
* Added environment-aware handling for remote administration features.

## [1.0.1] - 2026-09-20

### Added

* Added a new **Security Auditing** category and dedicated menu.

### Changed

* Improved menu layout and navigation.
* Made small usability improvements throughout the menus.


---

## Versioning

PSFieldKit follows Semantic Versioning:

* **MAJOR** — incompatible or major architectural changes.
* **MINOR** — new functionality that remains backward-compatible.
* **PATCH** — backward-compatible bug fixes.

Example:

`1.0.0` → `1.1.0` — new features

`1.1.0` → `1.1.1` — bug fixes

`1.1.1` → `2.0.0` — major breaking changes
