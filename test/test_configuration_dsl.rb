require 'helper'

class TestConfigurationDsl < Test::Unit::TestCase
  
  def impl_configure
    object.extend(ConfigurationDsl)
    object.configure_with(configuration_module)
    assert_equal nil, object.configuration.a
    assert_equal :b,  object.configuration.b
    assert_equal "c", object.configuration.c
    
    object.configure{ a("a") }
    assert_equal "a", object.configuration.a
    assert_equal :b,  object.configuration.b
    assert_equal "c", object.configuration.c
  end
  
  def impl_callback
    object.extend(ConfigurationDsl)
    object.configure_with(configuration_module){ @something = "blahtest" }
    object.configure
    assert_equal "blahtest", object.instance_variable_get(:@something)
  end
  
  def test_inheritance
    klass = Class.new
    klass.extend ConfigurationDsl
    klass.configure_with(configuration_module)
    klass.configure do
      b "bee"
    end
    
    derived = Class.new(klass)
    assert_equal nil,   derived.configuration.a
    assert_equal "bee", derived.configuration.b
    assert_equal "c",   derived.configuration.c
    
    derived.configure do
      c :sea
    end
    assert_equal nil,   derived.configuration.a
    assert_equal "bee", derived.configuration.b
    assert_equal :sea,  derived.configuration.c
    
    # Make sure the inherited class's configuration didn't change.
    assert_equal nil,   klass.configuration.a
    assert_equal "bee", klass.configuration.b
    assert_equal "c",   klass.configuration.c
  end
  
  def test_deep_inheritance
    
    # Obscure bug where the base class extends ConfigurationDsl and calls
    # configure_with, but never configure.  Then a class inherits and does
    # call configure.
    
    klass = Class.new
    klass.extend ConfigurationDsl
    klass.configure_with(configuration_module)
    
    derived = Class.new(klass)
    derived.configure do
      c :sea
    end
    
    assert_equal :sea, derived.configuration.c
  end
  
  def test_inherit_does_not_dup_classes
    base = Class.new
    base.extend ConfigurationDsl
    base.configure_with(configuration_module)
    
    require "timeout"
    base.configure do
      a Timeout::Error
    end
    
    derived = Class.new(base)
    assert_equal Timeout::Error, derived.configuration.a
  end
  
  def test_override_inheritance
    klass = Class.new
    klass.extend ConfigurationDsl
    klass.configure_with(configuration_module)
    klass.configure do
      b "bee"
    end
    
    derived = Class.new(klass)
    assert_equal nil,   derived.configuration.a
    assert_equal "bee", derived.configuration.b
    assert_equal "c",   derived.configuration.c
    
    new_module = Module.new do
      const_set(:DEFAULTS, {
        :x => "x",
        :y => "y",
        :z => "z"
      })
      def x(v); configuration.x = v; end
      def y(v); configuration.y = v; end
      def z(v); configuration.z = v; end
    end
    
    derived.configure_with(new_module)
    assert_equal "x", derived.configuration.x
    assert_equal "y", derived.configuration.y
    assert_equal "z", derived.configuration.z
  end
  
  def test_frozen_configuration
    object = Object.new
    object.extend ConfigurationDsl
    object.configure_with(configuration_module)
    assert_equal :b, object.configuration.b
    assert_raises(RuntimeError){ object.configuration.b = "something" }
    object.configure do
      b "bee"
    end
    assert_equal "bee", object.configuration.b
    assert_raises(RuntimeError){ object.configuration.b = "something" }
  end
  
  instance_methods.each do |method_name|
    if method_name.to_s =~ /^impl_/
      base_name = method_name.to_s.sub(/^impl_/, "")
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
