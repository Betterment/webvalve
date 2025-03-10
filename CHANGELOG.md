# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project aims to adhere to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

### Added

### Removed

## 2.0.4 - 2025-03-05

### Changed

- fix broken LogSubscriber bolding (<https//github.com/Betterment/webvalve/pull/85>) (thanks @aburgel)

## [2.0.3] - 2024-11-26

### Changed

- fix support for sinatra 4.1 (<https://github.com/Betterment/webvalve/pull/82>) (thanks @aburgel)

## [2.0.2] - 2024-06-10

### Changed

- Fix file permissions in bundled gem

## [2.0.1] - 2024-05-21

### Changed

- Remove constraint on sinatra < 3 to allow for newer rack and sinatra
  usages (<https://github.com/Betterment/webvalve/pull/65>) (thanks @co-vladimir-ya)

## [2.0.0] - 2023-07-20

### Added

- Dynamic URL support via wildcards, Regexps, and Addressable::Templates

## [1.3.1] - 2023-07-20

### Changed

- Replace usage of deprecated `File.exists?` in generator
  (<https://github.com/Betterment/webvalve/pull/57>) (thanks @tmnsun)

## [1.3.0] - 2023-07-18

### Added

- Official support for Ruby 3.1 and 3.2

### Removed

- Drops support for Rails < 6.1
- Drops support for Ruby < 3.0

## [1.2.0] - 2021-12-16

### Added

- Official support for Ruby 2.7 and 3.0
- Official support for Rails 6.1 and 7.0

### Removed

- Drops support for Rails < 5.2
- Drops support for Ruby < 2.6

## [1.1.0] - 2020-04-27

### Changed

- Allow the same URL for services as long as basic auth is different
  (<https://github.com/Betterment/webvalve/pull/46>)
- Introduce `reset!` and `clear!` to replace `reset`
  <https://github.com/Betterment/webvalve/pull/45>)

## [1.0.2] - 2020-04-27

### Changed

- Fix an issue with setup / reset
  (<https://github.com/Betterment/webvalve/pull/44>)

## [1.0.1] - 2020-04-24

### Changed

- Fix an issue in rspec setup / usage of `WebValve.reset`
  (<https://github.com/Betterment/webvalve/pull/43>)

## [1.0.0] - 2020-04-22

### Changed

- Support API_URLs that include path
  (<https://github.com/Betterment/webvalve/pull/41>)

## [0.12.0] - 2020-02-22

### Changed

- raise an error on setup when multiple services are registered to the
  same url. (<https://github.com/Betterment/webvalve/pull/40>)

## [0.11.0] - 2019-11-04

### Changed

- rework configuration so that WebValve has 3 operating modes: off,
  on+allowing, and on+intercepting. support toggling the latter two
  modes with
  `WEBVALVED_ENABLED=1`+`WEBVALVE_SERVICE_ENABLED_DEFAULT=1` and
  `WEBVALVED_ENABLED=1`+`WEBVALVE_SERVICE_ENABLED_DEFAULT=0`.
  (<https://github.com/Betterment/webvalve/pull/34>)

## [0.10.0] - 2019-09-23

### Changed

- `Webvalve.register` no longer accepts classes; you must provide class names as strings. Fixes a Rails 6 deprecation warning. (<https://github.com/Betterment/webvalve/pull/35>)

## [0.9.10] - 2019-09-09

### Changed

- rename `whitelist_url` to `allow_url` (<https://github.com/Betterment/webvalve/pull/33>)

## [0.9.9] - 2019-05-24

### Changed

- fix integration with `webdrivers` gem so Rails 6 should work out of the box (<https://github.com/Betterment/webvalve/pull/32>)

## [0.9.8] - 2019-01-22

### Changed

- fix load order of webvalve initializer from @jmileham (<https://github.com/Betterment/webvalve/pull/26>)
- drop support for rails 4.2 and jruby

## [0.9.7] - 2018-09-30

### Changed

- Improved WEBVALVED_ENABLED behavior from @haffla (<https://github.com/Betterment/webvalve/pull/24>)

## [0.9.6] - 2018-06-27

### Changed

- fix changelog links

## [0.9.5] - 2018-06-27

### Changed

- WebMock 3+ support from @messanjah (<https://github.com/Betterment/webvalve/pull/22>)

[Unreleased]: https://github.com/Betterment/webvalve/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/Betterment/webvalve/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Betterment/webvalve/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/Betterment/webvalve/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/Betterment/webvalve/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Betterment/webvalve/compare/v0.12.0...v1.0.0
[0.12.0]: https://github.com/Betterment/webvalve/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/Betterment/webvalve/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/Betterment/webvalve/compare/v0.9.10...v0.10.0
[0.9.10]: https://github.com/Betterment/webvalve/compare/v0.9.9...v0.9.10
[0.9.9]: https://github.com/Betterment/webvalve/compare/v0.9.8...v0.9.9
[0.9.8]: https://github.com/Betterment/webvalve/compare/v0.9.7...v0.9.8
[0.9.7]: https://github.com/Betterment/webvalve/compare/v0.9.6...v0.9.7
[0.9.6]: https://github.com/Betterment/webvalve/compare/v0.9.5...v0.9.6
[0.9.5]: https://github.com/Betterment/webvalve/compare/v0.9.4...v0.9.5
