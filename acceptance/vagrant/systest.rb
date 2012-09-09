#!/usr/bin/env ruby

require 'rubygems' unless defined?(Gem)
require 'net/ssh'
require 'net/scp'
require 'net/http'
require 'socket'
require 'optparse'
require 'systemu'
require 'test/unit'
require 'yaml'

Test::Unit.run = true

require "bundler/setup"
require 'puppet_acceptance'

dir = $LOAD_PATH.grep /puppet-acceptance/
Dir.chdir(File.join(dir[0], '..')) do
  puts Dir.getwd
  PuppetAcceptance::CLI.new.execute!
end

puts "systest completed successfully, thanks."
exit 0
