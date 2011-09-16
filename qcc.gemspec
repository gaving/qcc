# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qcc/version"

Gem::Specification.new do |s|
  s.name        = "qcc"
  s.version     = QCC::VERSION
  s.authors     = ["Gavin"]
  s.email       = ["gavin@brokentrain.net"]
  s.homepage    = "https://github.com/gaving/qcc"
  s.description = %q{Quality Center Controller}
  s.summary     = %q{Control a Quality Center instance}

  s.add_dependency "htmlentities", "~> 4.3.0"
  s.add_dependency "terminal-table", "~> 1.4.2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
