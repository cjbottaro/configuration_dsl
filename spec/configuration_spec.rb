require "spec_helper"

module Foo
  def name(s)
    s.to_s
  end

  def age(n = 0)
    n.to_i
  end

  def jobs(s)
    @jobs ||= []
    @jobs << s
  end
end

class Bar
end

describe ConfigurationDsl::Configuration do
  subject{ ConfigurationDsl::Configuration.new(Foo) }

  context "when #__set is called multiple times for an option" do
    before(:all) do
      subject.__set(:name, ["chris"], nil)
      subject.__set(:name, [], Proc.new{ "coco" })
      subject.__set(:name, ["callie"], nil)
      subject.__set(:jobs, ["developer"], nil)
      subject.__set(:jobs, ["climber"], nil)
    end
    it "the last call should win in #__eval" do
      subject.__eval(:name).should == "callie"
    end
    it "or calls can aggregate with a little trickery" do
      subject.__eval(:jobs).should == %w[developer climber]
    end
  end

  context "when #__set isn't called at all for an option" do
    it "calling #__eval should raise ArgumentError if that option doesn't have a default value" do
      expect{ subject.__eval(:name) }.to raise_error(ArgumentError)
    end
    it "calling #__eval should use the default value if that option has a default value" do
      subject.__eval(:age).should == 0
    end
  end

  context "when #__set is called with a block and #__bind is called on an object" do
    before(:all) do
      subject.__set(:name, [], proc{ self.class.name })
      subject.__bind(Bar.new)
    end
    it "calling #__eval should evaluate the block in the context of that object" do
      subject.__eval(:name).should == "Bar"
    end
  end

  context "calling #dup produces a copy" do
    before(:all) do
      subject.__set(:name, [], proc{ self.class.name })
      subject.__bind(Bar.new)
      subject.__eval(:name)
      @copy = subject.dup
      @copy.__bind(Bar)
    end
    it "that re-evaluates calls" do
      mock(subject).__actualize.never
      mock.proxy(@copy).__actualize(:name, anything).once
      subject.__eval(:name).should == "Bar"
      @copy.__eval(:name).should == "Class"
    end
    it "that does not interfere with the original" do
      @copy.__eval(:name).should == "Class"
      subject.__eval(:name).should == "Bar"
    end
  end

end
