# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project aims to adhere to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
### Added
### Removed

## [0.9.11] - 2019-09-23
### Changed
- `Webvalve.register` no longer accepts classes; you must provide class names as strings. Fixes a Rails 6 deprecation warning. (https://github.com/Betterment/webvalve/pull/35)

## [0.9.10] - 2019-09-09
### Changed
- rename `whitelist_url` to `allow_url` (https://github.com/Betterment/webvalve/pull/33)

## [0.9.9] - 2019-05-24
### Changed
- fix integration with `webdrivers` gem so Rails 6 should work out of the box (https://github.com/Betterment/webvalve/pull/32)

## [0.9.8] - 2019-01-22
### Changed
- fix load order of webvalve initializer from @jmileham (https://github.com/Betterment/webvalve/pull/26)
- drop support for rails 4.2 and jruby

## [0.9.7] - 2018-09-30
### Changed
- Improved WEBVALVED_ENABLED behavior from @haffla (https://github.com/Betterment/webvalve/pull/24)

## [0.9.6] - 2018-06-27
### Changed
- fix changelog links

## [0.9.5] - 2018-06-27
### Changed
- WebMock 3+ support from @messanjah (https://github.com/Betterment/webvalve/pull/22)

[Unreleased]: https://github.com/Betterment/webvalve/compare/v0.9.11...HEAD
[0.9.11]: https://github.com/Betterment/webvalve/compare/v0.9.10...v0.9.11
[0.9.10]: https://github.com/Betterment/webvalve/compare/v0.9.9...v0.9.10
[0.9.9]: https://github.com/Betterment/webvalve/compare/v0.9.8...v0.9.9
[0.9.8]: https://github.com/Betterment/webvalve/compare/v0.9.7...v0.9.8
[0.9.7]: https://github.com/Betterment/webvalve/compare/v0.9.6...v0.9.7
[0.9.6]: https://github.com/Betterment/webvalve/compare/v0.9.5...v0.9.6
[0.9.5]: https://github.com/Betterment/webvalve/compare/v0.9.4...v0.9.5
