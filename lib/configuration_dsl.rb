require "configuration_dsl/dsl"
require "configuration_dsl/helper"

module ConfigurationDsl
  
  class Error < RuntimeError; end
  
  def configure_with(configuration_module, &block)
    helper = Helper.new(self)
    settings = helper.initialize_settings
    settings[:module] = configuration_module
    settings[:callback] = block if block_given?
    @configuration = nil
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
    @configuration ||= begin
      helper = Helper.new(self)
      if helper.has_settings?
        helper.default_configuration
      else
        helper.inherit_configuration
      end
    end
  end
  
end