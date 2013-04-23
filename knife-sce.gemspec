# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-sce/version"

Gem::Specification.new do |s|
  s.name        = "knife-sce"
  s.version     = Knife::SCE::VERSION
  s.has_rdoc = true
  s.authors     = ["Rad Gruchalski"]
  s.email       = ["radek@gruchalski.com"]
  s.summary = "IBM SCE tools for Chef's knife"
  s.description = s.summary
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "fog", "~> 1.6"
  s.add_dependency "chef", ">= 0.10.10"
#  s.add_dependency "netaddr", ">= 1.5"
#  s.add_dependency "knife-ec2", "~> 0.6.2"
  %w(rspec-core rspec-expectations rspec-mocks  rspec_junit_formatter).each { |gem| s.add_development_dependency gem }
  s.require_paths = ["lib"]
end
