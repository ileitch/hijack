require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'hijack'
  s.version = '0.1.0'
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

