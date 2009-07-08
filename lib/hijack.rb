$:.unshift(File.dirname(__FILE__))
require 'readline'
require 'stringio'
require 'drb'
require 'drb/unix'
require 'hijack/provider'
require 'hijack/console'

module Hijack
  def self.socket_for(name)
    "drbunix:/#{socket_path_for(name)}"
  end

  def self.socket_path_for(name)
    "/tmp/hijack.#{name}.sock"
  end
end
