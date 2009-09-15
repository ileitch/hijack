require 'rake/gempackagetask'
require 'yaml'

HIJACK_VERSION = '0.1.7'

task :clean => :clobber_package

spec = Gem::Specification.new do |s|  
  s.name                  = 'hijack'
  s.version               = HIJACK_VERSION
  s.platform              = Gem::Platform::RUBY
  s.summary               = 
  s.description           = 'Provides an irb session to an existing ruby process.'
  s.author                = "Ian Leitch"
  s.email                 = 'ian.leitch@systino.net'
  s.homepage              = 'http://github.com/ileitch/hijack'
  s.has_rdoc              = false
  s.files                 = %w(COPYING TODO README.rdoc Rakefile) + Dir.glob("{lib,test,tasks,bin,examples}/**/*")
  s.bindir                = "bin"
  s.executables           = %w( hijack )
  s.require_path          = "lib"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
end

namespace :gem do
  desc "Update the gemspec for GitHub's gem server"
  task :github do
    File.open("hijack.gemspec", 'w') { |f| f << YAML.dump(spec) }
  end  
end

task :install => [:clean, :clobber, :package] do
  sh "sudo gem install pkg/#{spec.full_name}.gem"
end

task :uninstall => :clean do
  sh "sudo gem uninstall -v #{HIJACK_VERSION} -x hijack"
end