require 'bundler'
require 'rspec/core/rake_task'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
end

task :default => :test