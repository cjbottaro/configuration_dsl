require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'configuration_dsl'

class LazyEvalTester
  extend(ConfigurationDsl)
  configure_with Module.new {
    def name(s)
      s
    end
  }
  configure do
    name{ self.name }
  end
end

class Test::Unit::TestCase
  attr_reader :object
end
