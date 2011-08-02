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
      singleton_class(object).send(:define_method, method) do |*args, &block|
        options = args.length == 1 && args.first.kind_of?(Hash) ? args.pop : {}
        @configuration_dsl.configure(object, options, &block)
      end
    end

    def define_storage(object)
      singleton_class(object).send(:define_method, storage) do |&block|
        @configuration_dsl.configuration.__bind(object)
      end
    end

    def singleton_class(object)
      (class << object; self; end)
    end

  end
end
