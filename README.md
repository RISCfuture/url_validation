# url_validation

[![CI](https://github.com/RISCfuture/url_validation/actions/workflows/ci.yml/badge.svg)](https://github.com/RISCfuture/url_validation/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/url_validation.svg)](https://rubygems.org/gems/url_validation)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A simple, localizable `ActiveModel::EachValidator` for URL fields.

|             |                                 |
|:------------|:--------------------------------|
| **Author**  | Tim Morgan                      |
| **License** | Released under the MIT license. |

## About

`url_validation` adds a URL validator usable in any `ActiveModel` (or `ActiveRecord`)
class. It supports localized error messages, multiple schemes, and optional
over-the-network reachability checks (`HEAD` by default, configurable).

## Installation

Add to your `Gemfile`:

```ruby
gem "url_validation"
```

Then `bundle install`.

This gem depends on `activemodel >= 6.1`. It does not require `activerecord`.

## Usage

It's an `EachValidator`, so use it with `validates`:

```ruby
class User
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :terms_of_service_link
  validates :terms_of_service_link, presence: true, url: true
end
```

### Examples

```ruby
# Format only (no network)
validates :link, url: true

# Restrict to a specific scheme (or list)
validates :link, url: {scheme: "https"}
validates :link, url: {scheme: %w[http https ftp]}

# If the user types "example.com", treat it as "http://example.com"
validates :link, url: {default_scheme: "http"}

# Verify host is reachable (sends a HEAD request)
validates :link, url: {check_host: true}

# Verify the path resolves to something other than 4xx/5xx
validates :link, url: {check_path: true}
validates :link, url: {check_path: [300..399, 400..499, 500..599]}

# Use GET instead of HEAD (for servers that don't handle HEAD properly)
validates :link, url: {check_host: true, http_method: :get}

# Customize the HTTPI request (timeouts, headers, etc.)
validates :link, url: {
  check_host:       true,
  request_callback: ->(request) { request.open_timeout = 5; request.read_timeout = 5 }
}
```

## Options

### Basic

| Option         | Description                                                              |
|:---------------|:-------------------------------------------------------------------------|
| `:allow_nil`   | If `true`, `nil` values are allowed.                                     |
| `:allow_blank` | If `true` (the default), `nil` or empty values are allowed without running format checks. Set to `false` to flag blank values as `:invalid_url`. |

### Error messages

Override the I18n key the validator uses when adding errors:

| Option                          | Replaces I18n key       |
|:--------------------------------|:------------------------|
| `:invalid_url_message`          | `:invalid_url`          |
| `:url_not_accessible_message`   | `:url_not_accessible`   |
| `:url_invalid_response_message` | `:url_invalid_response` |

### Format checks (no network)

| Option            | Description                                                                                                                          |
|:------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
| `:scheme`         | A string or array of strings indicating acceptable URL schemes. Defaults to `%w[http https]`.                                        |
| `:default_scheme` | If set (e.g., `"http"`), a URL without a scheme will have this scheme prepended before validation, so `"example.com"` parses fine.   |

### Network checks

`url_validation` uses [HTTPI](https://rubygems.org/gems/httpi) to issue requests,
so you can pick your underlying HTTP client.

| Option            | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|:------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `:check_host`     | If `true`, perform a request to the host to verify connectivity. Only runs for HTTP(S) URLs unless overridden.                                                                                                                                                                                                                                                                                                                                                                    |
| `:check_path`     | Treat specific response codes as invalid. Pass an Integer, a Symbol (e.g. `:not_found`), a Range (`400..499`), or an Array of these. `true` means "4xx or 5xx is invalid." Implies `:check_host`.                                                                                                                                                                                                                                                                                 |
| `:httpi_adapter`  | The HTTPI adapter to use (default: HTTPI's default).                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `:http_method`    | The HTTP verb used for the accessibility check, as a Symbol. Defaults to `:head`. Use `:get` for servers that mis-handle `HEAD`.                                                                                                                                                                                                                                                                                                                                                  |
| `:request_callback` | A `Proc`/lambda invoked with the `HTTPI::Request` before it executes. Use for custom timeouts, headers, auth, etc.                                                                                                                                                                                                                                                                                                                                                              |

## Localization

The validator emits the standard ActiveModel error symbols (`:invalid_url`,
`:url_not_accessible`, `:url_invalid_response`). Provide translations under the
usual `activemodel.errors.messages` namespace (or use the `Model.errors.messages`
fallback). Example `config/locales/en.yml`:

```yaml
en:
  errors:
    messages:
      invalid_url:          "is not a valid URL"
      url_not_accessible:   "is not reachable"
      url_invalid_response: "returned a bad response"
```

## Development

```sh
bin/setup
bundle exec rspec
```

The spec suite uses [webmock](https://rubygems.org/gems/webmock) with
`disable_net_connect!`, so tests never touch the network.

## License

MIT. See `LICENSE`.
