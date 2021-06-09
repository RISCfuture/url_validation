require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'juwelier'
Juwelier::Tasks.new do |gem|
  gem.name = 'url_validation'
  gem.summary = %(Simple URL validation in Rails 3+)
  gem.description = %(A simple, localizable EachValidator for URL fields in ActiveRecord 3.0.)
  gem.email = 'git@timothymorgan.info'
  gem.homepage = 'http://github.com/riscfuture/url_validation'
  gem.authors = ['Tim Morgan']
  gem.required_ruby_version = '>= 2.0.0'
end
Juwelier::RubygemsDotOrgTasks.new

require 'yard'
YARD::Rake::YardocTask.new('doc') do |doc|
  doc.options << '-m' << 'markdown' << '-M' << 'redcarpet'
  doc.options << '--protected' << '--no-private'
  doc.options << '-r' << 'README.md'
  doc.options << '-o' << 'doc'
  doc.options << '--title' << 'url_validation Documentation'.inspect

  doc.files = %w[lib/**/*.rb README.md]
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

task default: :spec
