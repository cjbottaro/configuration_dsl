require "configuration_dsl/dsl"
require "configuration_dsl/helper"

module ConfigurationDsl
  
  class Error < RuntimeError; end
  
  VERSION = File.read(File.dirname(__FILE__)+"/../VERSION")
  
  def configure_with(configuration_module, &block)
    helper = Helper.new(self)
    settings = helper.initialize_settings
    settings[:module] = configuration_module
    settings[:callback] = block if block_given?
    @configuration = helper.default_configuration
  end
  
  def configure(&block)
    helper = Helper.new(self)
    
    if block_given?
      raise Error, "cannot find configuration module" unless helper.module
      dsl = Dsl.new(configuration)
      dsl.send(:extend, helper.module)
      dsl.instance_eval(&block)
    end
    
    instance_eval(&helper.callback) if helper.callback
  end
  
  def configuration
    @configuration ||= Helper.new(self).inherit_configuration
  end
  
end