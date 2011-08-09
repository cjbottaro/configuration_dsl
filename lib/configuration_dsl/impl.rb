require "configuration_dsl/configuration"

module ConfigurationDsl
  class Impl

    attr_reader :configuration

    def initialize(mod, options = {}, &block)
      @module = mod
      @options = { :method => :configure,
                   :storage => :configuration }.merge(options)
      @configuration = Configuration.new(@module)
      @callback = block
    end

    def dup
      copy = Impl.new(@module, @options.dup, &@callback)
      copy.instance_variable_set("@configuration", @configuration.dup)
      copy
    end

    def method
      @options[:method]
    end

    def storage
      @options[:storage]
    end

    def configure(object, options = {}, &block)
      @configuration = Configuration.new(@module) if options[:reset]
      dsl = Dsl.new(@module, @configuration)
      dsl.instance_eval(&block) if block
      object.instance_eval(&@callback) if @callback
    end

    def define_method(object)
      singleton_class(object).class_eval <<-CODE
        def #{method}(options = {}, &block)
          @configuration_dsl.configure(self, options, &block)
        end
      CODE
    end

    def define_storage(object)
      singleton_class(object).class_eval <<-CODE
        def #{storage}
          @configuration_dsl.configuration.__bind(self)
        end
      CODE
    end

    def singleton_class(object)
      (class << object; self; end)
    end

  end
end
