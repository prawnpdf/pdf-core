# Change Log

All notable changes to this project will be documented in this file.

## Unreleased

### Changed

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

[0.7.0]: https://github.com/prawnpdf/pdf-core/compare/0.6.1...0.7.0
[0.6.1]: https://github.com/prawnpdf/pdf-core/compare/0.6.0...0.6.1
[0.6.0]: https://github.com/prawnpdf/pdf-core/compare/0.5.1...0.6.0
