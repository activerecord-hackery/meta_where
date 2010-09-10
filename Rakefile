require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "meta_where"
    gem.summary = %Q{ActiveRecord 3 query syntax on steroids.}
    gem.description = %Q{
      MetaWhere offers the ability to call any Arel predicate methods
      (with a few convenient aliases) on your Model's attributes instead
      of the ones normally offered by ActiveRecord's hash parameters. It also
      adds convenient syntax for order clauses, smarter mapping of nested hash
      conditions, and a debug_sql method to see the real SQL your code is
      generating without running it against the database. If you like the new
      AR 3.0 query interface, you'll love it with MetaWhere.
    }
    gem.email = "ernie@metautonomo.us"
    gem.homepage = "http://metautonomo.us/projects/metawhere/"
    gem.authors = ["Ernie Miller"]
    gem.add_development_dependency "shoulda"
    gem.add_dependency "activerecord", "~> 3.0.0"
    gem.add_dependency "activesupport", "~> 3.0.0"
    gem.add_dependency "arel", "~> 1.0.1"
    gem.post_install_message = <<END

*** Thanks for installing MetaWhere! ***
Be sure to check out http://metautonomo.us/projects/metawhere/ for a
walkthrough of MetaWhere's features, and click the donate button if
you're feeling especially appreciative. It'd help me justify this
"open source" stuff to my lovely wife. :)

END
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.libs << 'vendor/rails/activerecord/lib'
  test.libs << 'vendor/rails/activesupport/lib'
  test.libs << 'vendor/arel/lib'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

# Don't check dependencies since we're testing with vendored libraries
# task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "meta_where #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
