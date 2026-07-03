# Changelog

All notable changes to the MoonTera template engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v0.2.0] - 2026-07-03

This release transitions MoonTera from a basic MVP implementation to a production-ready template engine library with rich features and professional devops setup.

### Added
- **Nested Field Property Access**: Support for dot-notation field access (e.g. `{{ user.name }}`) resolving dynamic properties on maps inside the evaluator.
- **Loop Context Helpers**: Automatic injection of a local `loop` helper variable in `for` loops, providing:
  - `loop.index0` (0-indexed current position)
  - `loop.index` (1-indexed current position)
  - `loop.first` (boolean flag for first item)
  - `loop.last` (boolean flag for last item)
  - `loop.length` (total number of items in the array)
- **CI Pipeline**: Added GitHub Actions workflow to run `moon test` automatically on push/PRs.
- **Repository Guidelines**: Created `CONTRIBUTING.md` and `.editorconfig` to align coding standards.

### Changed
- Refactored `for` loop traversal to construct scoped context layers safely.
- Updated `src/main/main.mbt` CLI demo to demonstrate the new property access and loop helper metadata.

---

## [v0.1.0] - 2026-06-30

### Added
- Initial project structure.
- Lexer and Parser with math, boolean, and logical precedence operators.
- Support for template inheritance (`extends` and `block` tags).
- Built-in filters (`upper`, `lower`, `length`, `default`).
- Comprehensive unit tests.
