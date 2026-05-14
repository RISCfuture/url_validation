# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Allow CI to pin a specific ActiveModel/ActiveSupport major.minor to test
# against the matrix without maintaining separate gemfiles.
if (version = ENV["ACTIVEMODEL_VERSION"])
  gem "activemodel",   "~> #{version}.0"
  gem "activesupport", "~> #{version}.0"
end
