# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "meta_where/version"

Gem::Specification.new do |s|
  s.name        = "meta_where"
  s.version     = MetaWhere::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ernie Miller"]
  s.email       = ["ernie@metautonomo.us"]
  s.homepage    = "http://metautonomo.us/projects/metawhere"
  s.summary     = %q{ActiveRecord 3 query syntax on steroids.}
  s.description = %q{
      MetaWhere offers the ability to call any Arel predicate methods
      (with a few convenient aliases) on your Model's attributes instead
      of the ones normally offered by ActiveRecord's hash parameters. It also
      adds convenient syntax for order clauses, smarter mapping of nested hash
      conditions, and a debug_sql method to see the real SQL your code is
      generating without running it against the database. If you like the new
      AR 3.0 query interface, you'll love it with MetaWhere.
    }
  s.post_install_message = %q{
*** Thanks for installing MetaWhere! ***
Be sure to check out http://metautonomo.us/projects/metawhere/ for a
walkthrough of MetaWhere's features, and click the donate button if
you're feeling especially appreciative. It'd help me justify this
"open source" stuff to my lovely wife. :)

}

  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]

  s.rubyforge_project = "meta_where"

  s.add_dependency 'activerecord', '~> 3.1.0.alpha'
  s.add_dependency 'activesupport', '~> 3.1.0.alpha'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'sqlite3', '~> 1.3.3'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
