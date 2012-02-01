# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "benchy/version"

Gem::Specification.new do |s|
  s.name        = "benchy"
  s.version     = Benchy::VERSION
  s.authors     = ["Brad Gessler"]
  s.email       = ["brad@bradgessler.com"]
  s.homepage    = ""
  s.summary     = %q{Benchmark HTTP applications}
  s.description = %q{A dirty-simple HTTP benchmarking application}

  s.rubyforge_project = "benchy"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "em-http-request"
  s.add_runtime_dependency "thor"
end