module ConfigurationDsl
  class Helper
    attr_reader :object
    
    def initialize(object)
      @object = object
      yield(self) if block_given?
    end
    
    def initialize_settings
      @object.instance_variable_set(:@configuration_dsl_settings, {})
    end
    
    def has_settings?
      @object.instance_variable_defined?(:@configuration_dsl_settings)
    end
    
    def module
      traverse_ancestors_for do |ancestor|
        settings = ancestor.instance_variable_get(:@configuration_dsl_settings)
        settings and settings[:module]
      end
    end
    
    def callback
      traverse_ancestors_for do |ancestor|
        settings = ancestor.instance_variable_get(:@configuration_dsl_settings)
        settings and settings[:callback]
      end
    end
    
    def configuration
      traverse_ancestors_for do |ancestor|
        ancestor.instance_variable_get(:@configuration)
      end
    end
    
    def inherit_configuration
      struct = configuration
      struct and begin
        members = struct.members.collect{ |member| member.to_sym }
        values  = struct.values.collect{ |value| value.dup rescue value }
        Struct.new(*members).new(*values)
      end
    end
    
    def default_configuration
      hash = defaults
      Struct.new(*hash.keys).new(*hash.values)
    end
    
    def defaults
      self.module.const_get(:DEFAULTS) || {}
    end
    
    def traverse_ancestors_for(&block)
      ancestors = object.respond_to?(:ancestors) ? object.ancestors : [object]
      ancestors.each{ |ancestor| hit = block.call(ancestor) and return hit }
      nil
    end
    
  end
end