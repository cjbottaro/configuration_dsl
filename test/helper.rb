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

class Test::Unit::TestCase
  attr_reader :configuration_module, :auto_module, :object
  
  def setup
    @configuration_module = Module.new do
      const_set(:DEFAULTS, {
        :a => nil,
        :b => :b,
        :c => "c"
      })

      def a(v)
        configuration.a = v
      end

      def b(v)
        configuration.b = v
      end

      def c(v)
        configuration.c = v
      end
    end
    
    @auto_module = Module.new do
      const_set(:DEFAULTS, {
        :a => nil,
        :b => :b,
        :c => "c"
      })
      def c(v)
        configuration.c = "c:#{v}"
      end
    end
  end
  
end
