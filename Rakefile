require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |rspec|
  rspec.rspec_opts = ['--backtrace']
end

task :default => :spec
