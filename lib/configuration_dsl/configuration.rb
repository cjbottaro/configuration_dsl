module ConfigurationDsl
  class Configuration

    def initialize(_module)
      @module = _module
      @actualizer = Object.new
      @actualizer.extend(@module)
      @specs = @module.instance_methods.inject({}) do |memo, name|
        memo[name] = { :block => nil, :args => [], :evaled => false }
        memo
      end
    end

    def dup
      copy = Configuration.new(@module)
      copy.instance_variable_set("@actualizer", @actualizer)
      copy.instance_variable_set("@specs", @specs.dup)
      copy
    end

    def __set(name, args, block)
      @specs[name.to_sym] = { :block => block, :args => args, :evaled => false }
    end

    def __eval(name)
      spec = @specs[name]
      return spec[:value] if spec[:evaled]

      if (block = spec[:block])
        spec[:value] = @actualizer.send(name, block.call)
      else
        spec[:value] = @actualizer.send(name, *spec[:args])
      end
      spec[:evaled] = true

      spec[:value]
    end

    def method_missing(name, *args, &block)
      if @specs.has_key?(name)
        __eval(name)
      else
        super
      end
    end

    def inspect
      s = "#<ConfigurationDsl::Configuration:0x#{object_id}"
      ar = @specs.keys.collect{ |name| "@#{name}=?" }
      s += " " + ar.join(", ") unless ar.empty?
      s += ">"
    end

  end
end
