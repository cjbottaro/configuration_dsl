require "spec_helper"

personal_config = Module.new do
  def name(name)
    name.to_s
  end
  def age(n = 30)
    n.to_i
  end
end

accounts_config = Module.new do
  def twitter(name)
    name.to_s
  end
  def facebook(email)
    email.to_s
  end
end

describe ConfigurationDsl::Manager do

  context "when initialized with an object" do

    context "calling #configure_with" do
      before(:each) do
        @object = Object.new
        @manager = described_class.new(@object)
      end
      it "should define methods on that object named by the :method and :storage arguments" do
        @manager.configure_with(Module.new, :method => :ren, :storage => :stimpy)
        @object.should respond_to(:ren)
        @object.should respond_to(:stimpy)
      end
    end

    context "calling #configure_with mulitple times" do
      before(:each) do
        @object = Object.new
        @manager = described_class.new(@object)
      end
      it "should not raise an error when both the :method and :storage arguments have not been used before" do
        @manager.configure_with(Module.new, :method => :configure, :storage => :configuration)
        @manager.configure_with(Module.new, :method => :do_configure, :storage => :get_configuration)
      end
      it "should raise an error when :method argument has been used before" do
        @manager.configure_with(Module.new, :method => :configure, :storage => :configuration)
        expect{ @manager.configure_with(Module.new, :method => :configure, :storage => :get_configuration) }.to raise_error(ArgumentError)
      end
      it "should raise an error when :storage argument has been used before" do
        @manager.configure_with(Module.new, :method => :configure, :storage => :configuration)
        expect{ @manager.configure_with(Module.new, :method => :do_configure, :storage => :configuration) }.to raise_error(ArgumentError)
      end
      it "should not raise an error when overriding a previous call to #configure_with" do
        @manager.configure_with(Module.new, :method => :configure, :storage => :configuration)
        @manager.configure_with(Module.new, :method => :do_configure, :storage => :get_configuration)
      end
    end

    context "calling #configure" do
      before(:all) do
        @object = Object.new
        @manager = ConfigurationDsl::Manager.new(@object)
        @manager.configure_with(personal_config, :method => :configure_personal, :storage => :personal_configuration) do
          @personal_config_callback = true
        end
        @manager.configure_with(accounts_config, :method => :configure_accounts, :storage => :accounts_configuration) do
          @accounts_config_callback = true
        end
      end
      it "should call any callbacks" do
        @object.instance_variable_get(:@personal_config_callback).should be_nil
        @object.instance_variable_get(:@accounts_config_callback).should be_nil
        @manager.configure(:configure_personal)
        @object.instance_variable_get(:@personal_config_callback).should be_true
        @object.instance_variable_get(:@accounts_config_callback).should be_nil
        @manager.configure(:configure_accounts)
        @object.instance_variable_get(:@personal_config_callback).should be_true
        @object.instance_variable_get(:@accounts_config_callback).should be_true
      end
      it "should eval the given block using a DSL" do
        @manager.configure(:configure_personal) do
          name "chris"
          age 31
        end
        @manager.configure(:configure_accounts) do
          twitter "cjbottaro"
          facebook "cjbottaro@alumni.utexas.net"
        end
      end
      it "should not use the wrong configuration/DSL" do
        expect do
          @manager.configure(:configure_personal) do
            twitter "cjbottaro"
          end
        end.to raise_error(NoMethodError)
        expect do
          @manager.configure(:configure_accounts) do
            name "chris"
          end
        end.to raise_error(NoMethodError)
      end
    end

    context "calling #configuration" do
      before(:all) do
        @object = Object.new
        @manager = ConfigurationDsl::Manager.new(@object)
        @manager.configure_with(personal_config, :method => :configure_personal, :storage => :personal_configuration)
        @manager.configure_with(accounts_config, :method => :configure_accounts, :storage => :accounts_configuration)
      end
      it "should return the asked for configuration" do
        personal_configuration = @manager.configuration(:personal_configuration)
        accounts_configuration = @manager.configuration(:accounts_configuration)
        personal_configuration.object_id.should_not == accounts_configuration.object_id
      end
      it "should bind the object to the configuration" do
        personal_configuration = @manager.configuration(:personal_configuration)
        mock.proxy(personal_configuration).__bind(@object)
        @manager.configuration(:personal_configuration)
      end
    end

    context "calling #duplicate" do
      before(:all) do
        @object = Object.new
        @manager = ConfigurationDsl::Manager.new(@object)
        @manager.configure_with(personal_config, :method => :configure_personal, :storage => :personal_configuration)
        @manager.configure_with(accounts_config, :method => :configure_accounts, :storage => :accounts_configuration)
      end
      it "should return a new manager" do
        new_object  = Object.new
        new_manager = @manager.duplicate(new_object)
        new_manager.object_id.should_not == @manager.object_id
      end
    end

  end

end
