require 'helper'

class TestConfigurationDsl < Test::Unit::TestCase
  
  def both_configure_with
    configuration_module = Module.new do
      def name(value = "chris")
        value.to_s
      end

      def age(value)
        value.to_i
      end
    end
    object.extend(ConfigurationDsl)
    object.configure_with(configuration_module)
    assert_equal "chris", object.configuration.name
    assert_raise(ArgumentError){ object.configuration.age }
  end

  def both_configure
    configuration_module = Module.new do
      def name(value = "chris")
        value.to_s
      end

      def age(value)
        value.to_i
      end
    end
    object.extend(ConfigurationDsl)
    object.configure_with(configuration_module)
    object.configure do
      age "31"
    end
    assert_equal "chris", object.configuration.name
    assert_equal 31, object.configuration.age
  end

  def both_configure_block_value
    object.extend(ConfigurationDsl)
    object.configure_with Module.new {
      def name(string); string; end
    }
    object.configure{ name{ "chris" } }
    assert_equal "chris", object.configuration.name
  end

  def both_configure_reset
    object.extend(ConfigurationDsl)
    object.configure_with Module.new {
      def name(string = nil); string; end
      def age(number = nil); number; end
    }
    assert_equal nil, object.configuration.name
    assert_equal nil, object.configuration.age

    object.configure{ name "chris" }
    assert_equal "chris", object.configuration.name
    assert_equal nil, object.configuration.age

    object.configure{ age 31 }
    assert_equal "chris", object.configuration.name
    assert_equal 31, object.configuration.age

    object.configure(:reset => true){ age 30 }
    assert_equal nil, object.configuration.name
    assert_equal 30, object.configuration.age
  end

  def both_custom_method
    configuration_module = Module.new do
      def name(value = "chris")
        value.to_s
      end

      def age(value)
        value.to_i
      end
    end
    object.extend(ConfigurationDsl)
    object.configure_with(configuration_module, :method => :something)
    object.something do
      age "31"
    end
    assert_equal "chris", object.configuration.name
    assert_equal 31, object.configuration.age
  end

  def both_custom_storage
    configuration_module = Module.new do
      def name(value = "chris")
        value.to_s
      end

      def age(value)
        value.to_i
      end
    end
    object.extend(ConfigurationDsl)
    object.configure_with(configuration_module, :storage => :something)
    object.configure do
      age "31"
    end
    assert_equal "chris", object.something.name
    assert_equal 31, object.something.age
  end
  
  def both_callback
    object.extend(ConfigurationDsl)
    object.configure_with(Module.new){ @something = "blahtest" }
    object.configure
    assert_equal "blahtest", object.instance_variable_get(:@something)
  end
  
  def test_inheritance
    configuration_module = Module.new do
      def name(value = "chris")
        value.to_s
      end

      def age(value)
        value.to_i
      end
    end
    klass = Class.new
    klass.extend(ConfigurationDsl)
    klass.configure_with(configuration_module)
    klass.configure do
      name "christopher"
      age 31
    end
    
    derived = Class.new(klass)
    assert_equal "christopher",   derived.configuration.name
    assert_equal 31,              derived.configuration.age
    
    derived.configure do
      age 30
    end
    assert_equal "christopher",   derived.configuration.name
    assert_equal 30,              derived.configuration.age
    
    # Make sure the inherited class's configuration didn't change.
    assert_equal "christopher",   klass.configuration.name
    assert_equal 31,              klass.configuration.age
  end
  
  def test_inherit_does_not_dup_classes
    base = Class.new
    base.extend ConfigurationDsl
    base.configure_with Module.new {
      def timeout(value)
        value
      end
    }
    
    require "timeout"
    base.configure do
      timeout Timeout::Error
    end
    derived = Class.new(base)

    assert_equal Timeout::Error, base.configuration.timeout
    assert_equal Timeout::Error, derived.configuration.timeout
  end
  
  # Make sure that if we call configure_with in a derived class, that it overrides
  # what was done when the parent called configure_with.
  def test_configure_with_in_derived
    
    klass = Class.new
    klass.extend ConfigurationDsl
    klass.configure_with Module.new {
      def name(value = "chris")
        value.to_s
      end
      def age(value)
        value.to_i
      end
    }
    klass.configure do
      age 31
    end
    
    derived = Class.new(klass)
    assert_equal "chris", derived.configuration.name
    assert_equal 31,      derived.configuration.age
    
    derived.configure_with Module.new {
      def birthday(date)
        date
      end
      def gender(v)
        v
      end
    }
    derived.configure do
      birthday "03/11/1980"
      gender "male"
    end

    assert_raise(NoMethodError){ derived.configuration.name }
    assert_raise(NoMethodError){ derived.configuration.age }
    assert_equal "03/11/1980", derived.configuration.birthday
    assert_equal "male", derived.configuration.gender

    # Make sure nothing happened to our base class.
    assert_equal "chris", klass.configuration.name
    assert_equal 31,      klass.configuration.age
  end
  
  instance_methods.each do |method_name|
    if method_name.to_s =~ /^both_/
      base_name = method_name.to_s.sub(/^both_/, "")
      class_eval <<-code
        def test_object_#{base_name}
          @object = Object.new
          #{method_name}
        end
        def test_class_#{base_name}
          @object = Class.new
          #{method_name}
        end
      code
    end
  end
  
end
