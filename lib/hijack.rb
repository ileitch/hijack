$:.unshift(File.dirname(__FILE__))
require 'stringio'
require 'drb'
require 'drb/unix'
require 'hijack/provider'
require 'hijack/console'
require 'hijack/version'

module Hijack
  def self.socket_for(name)
    "drbunix:/#{socket_path_for(name)}"
  end

  def self.socket_path_for(name)
    "/tmp/hijack.#{name}.sock"
  end

  def version
    '0.1.0'
  end
end
