#!/usr/bin/ruby
require 'rubygems'
require 'sinatra'

$count = 0

get '/' do
  "Hello! #{$count += 1}"
end