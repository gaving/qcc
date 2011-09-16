# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qcc/version"

Gem::Specification.new do |s|
  s.name        = "qcc"
  s.version     = qcc::VERSION
  s.authors     = ["Gavin"]
  s.email       = ["gavin@brokentrain.net"]
  s.homepage    = "https://github.com/gaving/qcc"
  s.description = %q{QCC Controller}
  s.summary     = %q{Control a quality center instance}

  #s.rubyforge_project = "qcc"
  #s.add_dependency "paint", "~> 0.8.3"
  #s.add_dependency "trollop", "~> 1.16.2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
