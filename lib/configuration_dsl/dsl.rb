module ConfigurationDsl
  class Dsl
    attr_reader :configuration

    def initialize(_module, configuration)
      @configuration = configuration
      _module.instance_methods.each do |name|
        (class << self; self; end).class_eval do
          define_method(name) do |*args, &block|
            @configuration.__set(name, args, block)
          end
        end
      end
    end

  end
end
