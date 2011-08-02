require "configuration_dsl/dsl"
require "configuration_dsl/impl"

module ConfigurationDsl
  
  class Error < RuntimeError; end
  
  VERSION = File.read(File.dirname(__FILE__)+"/../VERSION")

  def configure_with(mod, options = {}, &block)
    @configuration_dsl = Impl.new(mod, options, &block)
    @configuration_dsl.define_method(self)    
    @configuration_dsl.define_storage(self)
  end

  def self.extended(object)
    if object.instance_of?(Class)
      (class << object; self; end).class_eval do
        def inherited_with_configuration_dsl(derived)
          if (configuration_dsl = instance_variable_get("@configuration_dsl"))
            derived.instance_variable_set("@configuration_dsl", configuration_dsl.dup)
          end
          inherited_without_configuration_dsl(derived)
        end
        alias_method :inherited_without_configuration_dsl, :inherited
        alias_method :inherited, :inherited_with_configuration_dsl
      end
    end
  end
  
end
