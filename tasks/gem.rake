# require 'rake/packagetask'
require 'rubygems'
require 'rubygems/package_task'
require 'yaml'
require './lib/hijack'

task :clean => :clobber_package

spec = Gem::Specification.new do |s|
  s.name                  = 'hijack'
  s.version               = Hijack.version
  s.platform              = Gem::Platform::RUBY
  s.summary               =
  s.description           = 'Provides an irb session to a running ruby process.'
  s.author                = "Ian Leitch"
  s.email                 = 'port001@gmail.com'
  s.homepage              = 'http://github.com/ileitch/hijack'
  s.has_rdoc              = false
  s.files                 = %w(COPYING TODO README.rdoc Rakefile) + Dir.glob("{lib,test,tasks,bin,examples}/**/*")
  s.bindir                = "bin"
  s.executables           = %w( hijack )
  s.require_path          = "lib"
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

namespace :gem do
  desc "Update the gemspec"
  task :spec do
    File.open("hijack.gemspec", 'w') { |f| f << YAML.dump(spec) }
  end
end

task :install => [:clean, :clobber, :package] do
  sh "sudo gem install pkg/#{spec.full_name}.gem"
end

task :uninstall => :clean do
  sh "sudo gem uninstall -v #{HIJACK_VERSION} -x hijack"
end
