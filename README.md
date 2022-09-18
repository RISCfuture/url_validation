# url_validation

Simple URL validator for Rails 3.

|             |                                 |
|:------------|:--------------------------------|
| **Author**  | Tim Morgan                      |
| **Version** | 1.0 (May 9, 2011)               |
| **License** | Released under the MIT license. |

## About

This gem adds a very simple URL format validator to be used with Active Record
models in Rails 3.0. It supports localized error messages. It can validate many
different kinds of URLs, including HTTP and HTTPS. It supports advanced
validation features like sending `HEAD` requests to URLS to verify that they are
valid endpoints.

## Installation

Add the gem to your project's Gemfile:

``` ruby
gem 'url_validation'
```

## Usage

This gem is an `EachValidator`, and thus is used with the `validates` method:

``` ruby
class User < ActiveRecord::Base
  validates :terms_of_service_link,
            presence: true,
            url: true
end
```

There are other options to fine-tune your validation; see the {UrlValidator}
class for more, and for a list of error message localization keys.
