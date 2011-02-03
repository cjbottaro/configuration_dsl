require "configuration_dsl/dsl"
require "configuration_dsl/impl"

module ConfigurationDsl
  
  class Error < RuntimeError; end
  
  VERSION = File.read(File.dirname(__FILE__)+"/../VERSION")
  
  def configure_with(configuration_module, &block)
    @configuration_dsl ||= Impl.new(self)
    @configuration_dsl.module = configuration_module
    @configuration_dsl.callback = block if block_given?
    @configuration_dsl.default_configuration!
  end
  
  def configure(&block)
    @configuration_dsl ||= Impl.new(self)
    
    # Instance eval the block.
    if block_given?
      _module = @configuration_dsl.find_module
      raise Error, "cannot find configuration module" unless _module
      dsl = Dsl.new(configuration)
      dsl.send(:extend, _module)
      dsl.instance_eval(&block)
    end
    
    # Run the callback.
    callback = @configuration_dsl.find_callback
    instance_eval(&callback) if callback
  end
  
  def configuration
    @configuration_dsl ||= Impl.new(self)
    @configuration_dsl.configuration ||= @configuration_dsl.inherit_configuration
  end
  
end