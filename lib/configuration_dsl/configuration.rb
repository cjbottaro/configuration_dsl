module ConfigurationDsl

  # Since we allow access to values via object-member notation, we prefix our own methods with __
  # (double underscore) to avoid conflicts.
  class Configuration

    def initialize(_module)
      @module       = _module
      @actualizer   = Object.new.tap{ |o| o.extend(@module) }
      @object       = nil
      @calls_map = @module.instance_methods.inject({}) do |memo, name|
        memo[name] = []
        memo
      end
    end

    def dup
      copy = Configuration.new(@module)
      calls_map = @calls_map.inject({}) do |memo, (name, array)|
        memo[name] = array.collect{ |hash| hash.dup }
        memo
      end
      calls_map.each{ |name, ar| ar.each{ |call| call[:evaled] = false } } # So derived classes can re-eval blocks.
      copy.instance_variable_set("@calls_map", calls_map)
      copy
    end

    def __actualize(name, call)
      if call[:block]
        args = @object.instance_eval(&call[:block])
      else
        args = call[:args]
      end
      @actualizer.send(name, *args)
    end

    def __bind(object)
      @object = object
      self
    end

    def __set(name, args, block)
      @calls_map[name.to_sym] << { :block => block, :args => args, :evaled => false }
    end

    def __eval(name)
      calls = @calls_map[name]

      # Maybe it has a default value?
      return @actualizer.send(name) if calls.empty?

      calls.each do |call|
        if not call[:evaled]
          call[:value] = __actualize(name, call)
          call[:evaled] = true
        end
      end

      calls.last[:value]
    end

    def method_missing(name, *args, &block)
      if @calls_map.has_key?(name)
        __eval(name)
      else
        super
      end
    end

    def inspect
      s = "#<ConfigurationDsl::Configuration:0x#{object_id}"
      ar = @calls_map.keys.collect{ |name| "@#{name}=?" }
      s += " " + ar.join(", ") unless ar.empty?
      s += ">"
    end

  end
end
