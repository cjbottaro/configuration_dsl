module ConfigurationDsl

  # Since we allow access to values via object-member notation, we prefix our
  # own methods with __ (double underscore) to avoid potential conflicts.
  class Configuration

    def initialize(_module)
      @module       = _module
      @actualizer   = Object.new.tap{ |o| o.extend(@module) }
      @object       = nil
      __clear_calls
    end

    def __duplicate
      new_calls_map = @calls_map.inject({}) do |memo, (name, array)|
        memo[name] = array.collect{ |hash| hash.dup }
        memo
      end
      Configuration.new(@module).tap do |configuration|
        configuration.instance_eval do
          @calls_map = new_calls_map
          __reset_calls
        end
      end
    end

    def __module
      @module
    end

    # Reset all calls (:evaled => false), so that they are reevaluated
    # the next time a configuration option is requested.
    def __reset_calls
      @calls_map.each{ |name, ar| ar.each{ |call| call[:evaled] = false } }
    end

    # Clear all the calls as if they were never made.
    def __clear_calls
      @calls_map = @module.instance_methods.inject({}) do |memo, name|
        memo[name] = []
        memo
      end
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
