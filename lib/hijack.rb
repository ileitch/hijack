$:.unshift(File.dirname(__FILE__))
require 'stringio'
require 'drb'
require 'drb/unix'
require 'rbconfig'
require 'irb'
require 'hijack/console'
require 'hijack/version'
require 'hijack/gdb'
require 'hijack/payload'
require 'hijack/workspace'

module Hijack
  def self.socket_for(pid)
    "drbunix:/#{socket_path_for(pid)}"
  end

  def self.socket_path_for(pid)
    "/tmp/hijack.#{pid}.sock"
  end
end
