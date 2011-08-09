require "helper"

class User
  extend(ConfigurationDsl)
  configure_with Module.new {
    def attribute(name, type, options = {})
      @attributes ||= []
      @attributes << options.merge(:name => name.to_sym, :type => type.to_sym)
    end
  }, :method => :typed_attributes,
     :storage => :ta_configuration

  typed_attributes do
    attribute :name, :string
    attribute :is_admin, :boolean, :default => false
  end

end


class TestTypedAttributes < Test::Unit::TestCase

  def test_stuff
    name_spec = User.ta_configuration.attribute.detect{ |spec| spec[:name] == :name }
    assert_equal :string, name_spec[:type]

    is_admin_spec = User.ta_configuration.attribute.detect{ |spec| spec[:name] == :is_admin }
    assert_equal :boolean, is_admin_spec[:type]
    assert_equal false, is_admin_spec[:default]
  end

end
