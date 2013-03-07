dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(dir, 'lib')

# Don't want puppet getting the command line arguments for rake or autotest
ARGV.clear

require 'rubygems'
require 'bundler/setup'
require 'rspec-puppet'

Bundler.require :default, :test

require 'pathname'
require 'tmpdir'

Pathname.glob("#{dir}/shared_behaviours/**/*.rb") do |behaviour|
  require behaviour.relative_path_from(Pathname.new(dir))
end

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |config|
  config.mock_with :mocha
  config.module_path = File.join(fixture_path, 'modules')
  config.manifest_dir = File.join(fixture_path, 'manifests')
  config.system_tmp = File.join(File.dirname(__FILE__), 'system', 'tmp')
  config.system_nodesets = {
    'centos-58-x64' => {
      :nodes => {
        'main' => {
          :base => 'centos-58-x64',
        },
      },
    },
    'debian-606-x64' => {
      :nodes => {
        'main' => {
          :prefab => 'debian-606-x64',
        },
      },
    },
  }
end
