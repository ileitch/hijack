require 'rubygems'
require 'rake/gempackagetask'
require 'lib/hijack/version'

spec = Gem::Specification.new do |s|
  s.name = 'hijack'
  s.version = Hijack.version
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc', 'TODO']
  s.summary = 'Provides an irb session to an existing ruby process.'
  s.description = s.summary
  s.author = 'Ian Leitch'
  s.email = 'ian.leitch@systino.net'
  s.homepage = 'http://github.com/ileitch/hijack'

  s.bindir       = "bin"
  s.executables  = %w( hijack )

  s.require_path = 'lib'
  s.files = %w(README.rdoc Rakefile TODO) + Dir.glob("{lib,bin}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

