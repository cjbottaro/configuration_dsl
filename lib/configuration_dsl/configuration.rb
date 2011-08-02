module ConfigurationDsl

  # Since we allow access to values via object-member notation, we prefix our own methods with __
  # (double underscore) to avoid conflicts.
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
      specs = @specs.inject({}){ |memo, (k, v)| memo[k] = v.dup; memo }
      specs.each{ |name, spec| spec[:evaled] = false } # So derived classes can re-eval blocks.
      copy.instance_variable_set("@specs", specs)
      copy
    end

    def __bind(object)
      @object = object
      self
    end

    def __set(name, args, block)
      @specs[name.to_sym] = { :block => block, :args => args, :evaled => false }
    end

    def __eval(name)
      spec = @specs[name]
      return spec[:value] if spec[:evaled]

      if (block = spec[:block])
        spec[:value] = @actualizer.send(name, @object.instance_eval(&block))
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
