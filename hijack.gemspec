Gem::Specification.new do |s|
  s.name = 'hijack'
  s.version = '0.1.5'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.summary = 'Provides an irb session to an existing ruby process.'
  s.description = s.summary
  s.author = 'Ian Leitch'
  s.email = 'ian.leitch@systino.net'
  s.homepage = 'http://github.com/ileitch/hijack'

  s.bindir       = "bin"
  s.executables  = %w( hijack )

  s.require_path = 'lib'
  s.files = ['README.rdoc' , 'Rakefile', 'TODO', 'lib/hijack', 'lib/hijack.rb', 'lib/hijack/console.rb', 'lib/hijack/gdb.rb', 'lib/hijack/helper.rb',
    'lib/hijack/payload.rb', 'lib/hijack/workspace.rb', 'examples/rails_dispatcher.rb', 'bin/hijack']
end