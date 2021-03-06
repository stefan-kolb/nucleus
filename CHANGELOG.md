# Change Log
All notable changes to the Nucleus project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased - Next

### Added
* Easy startup of Nucleus via Docker

### Fixed
* Fixed Heroku Authentication
* Updated Anynines API endpoint

### Removed
* Drop support for Ruby < 2.3

## [0.3.1] - 2016-03-07

### Removed
* Removed cloudControl adapter due to bankruptcy of the vendor

## [0.3.0] - 2016-03-07
* Yanked due to unnecessary Gem contents increasing the overall file size

## [0.2.0] - 2016-01-22

### Added
* Add basic logging functionality for OpenShift v2
* Add more providers and endpoints to the default configuration

### Fixed
* Correctly URL-encode credentials for Heroku authentication

### Removed
* LMDB is the only packaged data store from now on

## [0.1.0] - 2015-08-04

### Added
* Initial development release of the Platform as a Service abstraction layer - [@croeck](https://github.com/croeck)


[0.1.0]: https://github.com/stefan-kolb/nucleus/releases/tag/v0.1.0
[0.2.0]: https://github.com/stefan-kolb/nucleus/releases/tag/v0.2.0
[0.3.0]: https://github.com/stefan-kolb/nucleus/releases/tag/v0.3.0
[0.3.1]: https://github.com/stefan-kolb/nucleus/releases/tag/v0.3.1
