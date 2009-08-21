require 'rubygems'
require 'rake/gempackagetask'

spec = eval(File.read('hijack.gemspec'))

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

