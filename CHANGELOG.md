# Change Log

All notable changes to this project will be documented in this file.

## Unreleased

### Changed

- Stop requiring IO objects to have `#printf` and `#size`
  Max Chernyak

## [0.9.0][]

## Changed

- Increased precision of real numbers to 5
  Alexander Mankuta
- Dropped 2.3 & 2.4 Ruby support
  Alexander Mankuta
- Updated code style
  Alexander Mankuta

## [0.8.1][] - 2018-04-28

### Fixed

- Make sure stamp streams are writable
  Alexander Mankuta
- Handle text rendering from frozen strings
  Alexander Mankuta

## [0.8.0][] - 2018-04-27

### Changed

- Minimum Ruby version is 2.3
  Alexander Mankuta
- Trailing fraction zeroes are removed from numbers
  Alexander Mankuta

## [0.7.0][] - 2017-03-03

### Changed

- *Breaking change*: `PDF::Core::PdfObject` method has been renamed to
  `PDF::Core::pdf_object`
  Alexander Mankuta

### Added

- Support for horizontal scaling
  Tom Sullivan, [#26](https://github.com/prawnpdf/pdf-core/pull/26)
- Support for character spacing
  Tom Sullivan, [#27](https://github.com/prawnpdf/pdf-core/pull/27)
- Support for crops, bleeds, trims, and art box
  Alexander Mankuta


## [0.6.1][] - 2016-02-21

### Fixed

- Fixed regex "/u over UTF-8 string" warning on Ruby 2
  Takahiro Yoshimura, [#21](https://github.com/prawnpdf/pdf-core/pull/21)


## [0.6.0][] - 2015-07-15

### Added

- A trailer can be assigned to DocumentState
  Robert Bousquet, [#16](https://github.com/prawnpdf/pdf-core/pull/16)

[0.9.0]: https://github.com/prawnpdf/pdf-core/compare/0.8.1..0.9.0
[0.8.1]: https://github.com/prawnpdf/pdf-core/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/prawnpdf/pdf-core/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/prawnpdf/pdf-core/compare/0.6.1...0.7.0
[0.6.1]: https://github.com/prawnpdf/pdf-core/compare/0.6.0...0.6.1
[0.6.0]: https://github.com/prawnpdf/pdf-core/compare/0.5.1...0.6.0
