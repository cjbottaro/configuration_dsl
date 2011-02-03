module ConfigurationDsl
  class Impl
    attr_accessor :module, :callback, :configuration
    
    def self.dup_struct(struct)
      members = struct.members.collect{ |member| member.to_sym } # Normalize between Ruby versions.
      values = struct.values.collect do |value|
        if value.kind_of?(Class)
          value
        else
          value.dup rescue value
        end
      end
      Struct.new(*members).new(*values)
    end
    
    def initialize(object)
      @object = object
    end
    
    def find_module
      ancestors.each do |object|
        next unless (impl = object.instance_variable_get(:@configuration_dsl))
        return impl.module if impl.module
      end
      nil
    end
    
    def find_callback
      ancestors.each do |object|
        next unless (impl = object.instance_variable_get(:@configuration_dsl))
        return impl.callback if impl.callback
      end
      nil
    end
    
    def find_configuration
      ancestors.each do |object|
        next unless (impl = object.instance_variable_get(:@configuration_dsl))
        return impl.configuration if impl.configuration
      end
      nil
    end
    
    def default_configuration
      defaults = find_module.const_get(:DEFAULTS)
      Struct.new(*defaults.keys).new(*defaults.values)
    end
    
    def default_configuration!
      @configuration = default_configuration
      @configuration.freeze
      @configuration
    end
    
    def ancestors
      @object.respond_to?(:ancestors) ? @object.ancestors : [@object]
    end
    
  end
end