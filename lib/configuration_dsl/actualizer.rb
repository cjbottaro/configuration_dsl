module ConfigurationDsl
  class Actualizer
    attr_reader :configuration

    def initialize(object, configuration, exemptions = [])
      @object = object
      @configuration = configuration
      @exemptions = exemptions.to_set
    end

  private

    def method_missing(name, *args, &block)
      
      # In 1.8 Struct#members returns an array of strings.
      # In 1.9, it returns an array of symbols.
      members = configuration.members.collect{ |member| member.to_sym }
      
      if members.include?(name)
        value_for(name)
      else
        super
      end
    end

    def value_for(name)
      ivar_name = "@#{name}"
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      elsif @exemptions.include?(name)
        value = configuration.send(name)
        instance_variable_set(ivar_name, value)
      else
        value = actualize(configuration.send(name))
        instance_variable_set(ivar_name, value)
      end
    end

    def actualize(value)
      if value.kind_of?(Proc)
        @object.instance_eval(&value)
      else
        value
      end
    end

  end
end