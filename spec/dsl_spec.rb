require "spec_helper"

_module = Module.new do
  def foo(*args); nil; end
  def bar; nil; end
end

describe ConfigurationDsl::Dsl do
  context "initialized with a module and configuration" do
    subject do
      ConfigurationDsl::Dsl.new(_module, ConfigurationDsl::Configuration.new(_module))
    end
    it "should respond to all the methods defined in that module" do
      subject.should respond_to(:foo)
      subject.should respond_to(:bar)
    end
    it "record calls to each method in the configuration" do
      mock(subject.configuration).__set(:foo, ["test", "blah"], nil)
      mock(subject.configuration).__set(:bar, [], nil)
      mock(subject.configuration).__set(:bar, [], is_a(Proc))
      subject.foo("test", "blah")
      subject.bar
      subject.bar{ "blah" }
    end
  end
end
