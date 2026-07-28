# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc) do |doc|
    doc.options += ["--markup", "markdown"]
    doc.options += ["--markup-provider", "redcarpet"]
    doc.options += ["--protected", "--no-private"]
    doc.options += ["--readme", "README.md"]
    doc.options += ["--output-dir", "doc"]
    doc.options += ["--title", "url_validation Documentation"]
    doc.files = %w[lib/**/*.rb]
  end
rescue LoadError
  # YARD is optional
end

task default: :spec
