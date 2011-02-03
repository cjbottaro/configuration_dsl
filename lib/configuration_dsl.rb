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
    
    # Automatically define setters.
    @configuration_dsl.module.module_eval do
      self::DEFAULTS.keys.each do |name|
        next if method_defined?(name) # Don't override custom setters.
        module_eval <<-code
          def #{name}(value)
            configuration.#{name} = value
          end
        code
      end
    end
  end
  
  def configure(&block)
    @configuration_dsl ||= Impl.new(self)
    
    # Instance eval the block.
    if block_given?
      _module = @configuration_dsl.find_module
      raise Error, "cannot find configuration module" unless _module
      dsl = Dsl.new(Impl.dup_struct(configuration)) # Dup it to unfreeze it.
      dsl.send(:extend, _module)
      dsl.instance_eval(&block)
      @configuration_dsl.configuration = dsl.configuration.freeze
    end
    
    # Run the callback.
    callback = @configuration_dsl.find_callback
    instance_eval(&callback) if callback
  end
  
  def configuration
    @configuration_dsl ||= Impl.new(self)
    @configuration_dsl.find_configuration
  end
  
end