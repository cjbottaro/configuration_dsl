require "configuration_dsl/manager"

module ConfigurationDsl
  
  class Error < RuntimeError; end
  
  VERSION = File.read(File.dirname(__FILE__)+"/../VERSION").chomp

  DEFAULT_OPTIONS = {
    :method => :configure,
    :storage => :configuration
  }

  def configure_with(mod, options = {}, &block)
    options = DEFAULT_OPTIONS.merge(options)
    @configuration_dsl.configure_with(mod, options, &block)
  end

  def self.extended(object)
    object.instance_eval do
      @configuration_dsl = Manager.new(self)
    end

    if object.instance_of?(Class)
      (class << object; self; end).class_eval do
        def inherited_with_configuration_dsl(derived)
          configuration_dsl = instance_variable_get("@configuration_dsl")
          derived.instance_variable_set("@configuration_dsl", configuration_dsl.duplicate(derived))
          inherited_without_configuration_dsl(derived)
        end
        alias_method :inherited_without_configuration_dsl, :inherited
        alias_method :inherited, :inherited_with_configuration_dsl
      end
    end
  end
  
end
