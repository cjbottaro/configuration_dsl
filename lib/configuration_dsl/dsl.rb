module ConfigurationDsl
  class Dsl
    attr_reader :configuration
  
    def initialize(configuration)
      @configuration = configuration
    end
  end
end