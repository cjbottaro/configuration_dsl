require "spec_helper"

describe ConfigurationDsl::Impl do
  subject{ described_class.new(Module.new) }

  context "calling #define_method on an object" do
    it "should define a method on that object named by #method" do
      impl = described_class.new(Module.new)
      o = Object.new
      impl.define_method(o)
      o.should respond_to(impl.method)

      impl = described_class.new(Module.new, :method => :do_configure)
      o = Object.new
      impl.define_method(o)
      o.should respond_to(impl.method)
      o.should_not respond_to(:configure)
    end
  end

  context "calling #define_storage on an object" do
    it "should define a method on that object named by #storage" do
      o = Object.new
      subject.define_storage(o)
      o.should respond_to(subject.storage)

      o = Object.new
      impl = described_class.new(Module.new, :storage => :config)
      impl.define_storage(o)
      o.should respond_to(impl.storage)
      o.should_not respond_to(:configuration)
    end
  end

  context "calling #configure on an object" do
    it "with a block should eval that block using ConfigurationDsl::Dsl" do
      o = Object.new
      name = nil
      subject.configure(o){ name = self.class.name }
      name.should == "ConfigurationDsl::Dsl"
    end
    it "with option :reset => true should create a new configuration" do
      old_id = subject.configuration.object_id
      subject.configure(Object.new, :reset => true)
      subject.configuration.object_id.should_not == old_id
    end
    it "with a callback should eval that callback in the context of that object" do
      o = Object.new
      def o.increment
        @counter += 1
      end
      def o.counter
        @counter ||= 0
      end
      o.counter.should == 0
      impl = described_class.new(Module.new){ self.increment }
      impl.configure(o)
      o.counter.should == 1
    end
  end

end
