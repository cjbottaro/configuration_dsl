require "spec_helper"

shared_examples "ConfigurationDsl" do
  before(:all){ subject.extend(ConfigurationDsl) }
  it "should define #configure_with" do
    subject.should respond_to(:configure_with)
  end
end

describe Object do
  extended_with "ConfigurationDsl"
end

describe Class do
  extended_with "ConfigurationDsl" do
    it "should define #inherited_with_configuration_dsl" do
      subject.should respond_to(:inherited_with_configuration_dsl)
    end
    it "should define #inherited_without_configuration_dsl" do
      subject.private_methods.include?(:inherited_without_configuration_dsl)
    end
  end
end
