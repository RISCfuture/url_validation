# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-05-14

### Breaking

- Drops the runtime dependency on `activerecord`. The gem only ever needed
  `ActiveModel::EachValidator`, so it now depends on `activemodel` (and
  `activesupport`) directly. Apps that pulled `activerecord` in transitively
  through this gem will need to declare it themselves if required.
- Bumps `required_ruby_version` to `>= 3.1`.
- Bumps `activemodel` / `activesupport` minimum to `>= 6.1`.

### Added

- New `:http_method` option (default `:head`) lets callers choose the HTTP
  verb used for accessibility checks. Useful for servers that do not handle
  `HEAD` correctly.
- `webmock` is wired into the spec suite and `WebMock.disable_net_connect!`
  is enabled, so the test suite no longer makes live network calls.
- GitHub Actions workflow tests Ruby 3.1-3.4 against ActiveModel 7.0-8.0.
- `bin/console`, `bin/setup`, modern `Rakefile`, hand-written gemspec.
- `CHANGELOG.md`.

### Fixed

- **Accessibility check now uses `HEAD` requests, as documented.** Previously
  the code called `HTTPI.get`, contradicting the README. It now calls
  `HTTPI.request(:head, ...)` by default.
- **`allow_blank: false` is now honored.** Previously the validator's
  `return if value.blank?` short-circuit overrode an explicit
  `allow_blank: false` option. Blank values now flow through to
  format validation when `allow_blank` is false.
- **Rescue branch no longer references a re-parsed URI.** When the
  `default_scheme` re-parse raised, the rescue branch could call
  `url_format_valid?` against a previously-set URI in an inconsistent
  state. The rescue branch now adds `:invalid_url` unconditionally and
  returns, which matches the documented behavior.

### Removed

- `.travis.yml`, juwelier-generated gemspec, `VERSION` text file.
- Runtime `activerecord` dependency.

## [1.2.0]

- Last juwelier-managed release.
