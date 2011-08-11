# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rrobots/version"

Gem::Specification.new do |s|
  s.name        = "rrobots"
  s.version     = Rrobots::VERSION
  s.authors     = ["Jason Jones"]
  s.email       = ["jasonedwardjones@gmail.com"]
  s.homepage    = "http://github.com/ralreegorganon/rrobots"
  s.summary     = "gemified version of rrobots"
  s.description = "gemified version of rrobots"

  s.rubyforge_project = "rrobots"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency "gosu"
end
