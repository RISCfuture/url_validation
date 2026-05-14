# frozen_string_literal: true

# UrlValidator's version. Lives in its own module so the gemspec can
# `require_relative "lib/url_validation/version"` without forcing ActiveModel
# to load at gem-spec-evaluation time. The UrlValidator class picks the
# constant up and assigns it as `UrlValidator::VERSION`.
module UrlValidation
  VERSION = "2.0.0"
end
