require "configuration_dsl/configuration"
require "configuration_dsl/dsl"

module ConfigurationDsl
  class Manager

    def initialize(object)
      @object = object
      @map = {}
    end

    def duplicate(new_object)
      new_manager = self.class.new(new_object)

      # Transform @map into something easier to duplicate.
      # We're basically going to do a group by.
      transformation = @map.inject({}) do |memo, (name, array)|
        memo[array] ||= []
        memo[array] << name
        memo
      end

      # Make the new map, taking care to not duplicate any configuration twice.
      new_map = transformation.inject({}) do |memo, (array, names)|
        configuration, callback = array
        method_name, storage_name = names
        array = [configuration.__duplicate, callback]
        memo[method_name] = array
        memo[storage_name] = array
        memo
      end

      new_manager.instance_eval{ @map = new_map }
      new_manager
    end

    def configure_with(mod, options, &callback)
      method_name  = options[:method].to_sym
      storage_name = options[:storage].to_sym

      # Raise an error if the method names are already taken by other calls to #configure_with.
      # In the special case where both :method and :storage are pointing to the same configuration,
      # then allow them to override it.
      configuration1, _ = @map[method_name]  || []
      configuration2, _ = @map[storage_name] || []
      if configuration1 and not configuration2
        raise ArgumentError.new(":%s is already taken" % method_name)
      elsif configuration2 and not configuration1
        raise ArgumentError.new(":%s is already taken" % storage_name)
      elsif configuration1.object_id != configuration2.object_id
        raise ArgumentError.new(":%s and %s have already been taken" % [method_name, storage_name])
      end

      # Store the arguments.  The @map structure is going to have
      # multiple keys pointing to same objects like so:
      #   key1 \
      #         ---> object1
      #   key2 /
      #   key3 \
      #         ---> object2
      #   key4 /
      # This has some implication when trying to duplicate @map.
      @map[method_name] = [Configuration.new(mod), callback]
      @map[storage_name] = @map[method_name]

      # Define the configure method on the object.
      singleton_class(@object).class_eval <<-CODE
        def #{method_name}(options = {}, &block)
          @configuration_dsl.configure(:#{method_name}, options, &block)
        end
      CODE

      # Define the storage method on the object.
      singleton_class(@object).class_eval <<-CODE, __FILE__, __LINE__
        def #{storage_name}
          @configuration_dsl.configuration(:#{storage_name})
        end
      CODE
    end

    def configure(method_name, options = {}, &block)
      configuration, callback = @map[method_name]
      configuration.__clear_calls if options[:clear] || options[:reset]
      Dsl.new(configuration).tap{ |dsl| dsl.instance_eval(&block) } if block
      @object.instance_eval(&callback) if callback
    end

    def configuration(storage_name)
      @map[storage_name].first.__bind(@object)
    end

    def singleton_class(object)
      class << object; self; end
    end

  end
end
