require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "url_validation"
  gem.summary = %Q{Simple URL validation in Rails 3}
  gem.description = %Q{A simple, localizable EachValidator for URL fields in ActiveRecord 3.0.}
  gem.email = "git@timothymorgan.info"
  gem.homepage = "http://github.com/riscfuture/url_validation"
  gem.authors = [ "Tim Morgan" ]
  gem.required_ruby_version = '>= 1.8.7'
end
Jeweler::RubygemsDotOrgTasks.new

require 'yard'
YARD::Rake::YardocTask.new('doc') do |doc|
  doc.options << "-m" << "textile"
  doc.options << "--protected" << "--no-private"
  doc.options << "-r" << "README.textile"
  doc.options << "-o" << "doc"
  doc.options << "--title" << "url_validation Documentation".inspect
  
  doc.files = [ 'lib/*_validator.rb', 'README.textile' ]
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

task :default => :spec
