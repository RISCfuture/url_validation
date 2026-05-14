# frozen_string_literal: true

require_relative "lib/url_validation/version"

Gem::Specification.new do |spec|
  spec.name        = "url_validation"
  spec.version     = UrlValidation::VERSION
  spec.authors     = ["Tim Morgan"]
  spec.email       = ["git@timothymorgan.info"]

  spec.summary     = "Simple URL validation for ActiveModel."
  spec.description = "A simple, localizable ActiveModel::EachValidator for URL fields. " \
                     "Supports format validation as well as optional network reachability " \
                     "checks via HEAD (or any other HTTP verb) requests."
  spec.homepage    = "https://github.com/riscfuture/url_validation"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri"          => spec.homepage,
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "changelog_uri"         => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    tracked = `git ls-files -z`.split("\x0")
    # Always include these even if not yet committed (helps local builds).
    extra = %w[CHANGELOG.md lib/url_validation/version.rb]
    (tracked + extra).uniq.reject do |f|
      f.match(%r{\A(?:test|spec|features|bin|gemfiles|\.github|\.idea)/}) ||
        f.match(%r{\A\.(?:rspec|rubocop\.yml|standard\.yml|ruby-version|ruby-gemset|gitignore|document|travis\.yml)\z}) ||
        f.match(%r{\AGemfile(?:\.lock)?\z}) ||
        f == "VERSION"
    end.select { |f| File.exist?(File.join(__dir__, f)) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel",   ">= 6.1"
  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "addressable",   "~> 2.8"
  spec.add_dependency "httpi",         "~> 4.0"

  spec.add_development_dependency "rake",     "~> 13.0"
  spec.add_development_dependency "rspec",    "~> 3.13"
  spec.add_development_dependency "standard", "~> 1.0"
  spec.add_development_dependency "webmock",  "~> 3.0"
end
