require 'spec_helper'

describe Throttling do
  after :each do
    Throttling.reset_defaults!
  end

  context 'with defaults' do
    it 'should create logger' do
      Throttling.logger.should be_a(Logger)
    end

    it 'should be enabled' do
      Throttling.enabled?.should be_true
      Throttling.enabled.should be_true
    end
  end

  context 'setters' do
    it 'should allow to enabled and disable client' do
      Throttling.enabled = false
      Throttling.should_not be_enabled

      Throttling.enable!
      Throttling.should be_enabled

      Throttling.disable!
      Throttling.should_not be_enabled

      Throttling.enabled = true
      Throttling.should be_enabled
    end

    it 'should allow to change logger' do
      mock = Throttling.logger = mock('Logger')
      Throttling.logger.should be(mock)
    end
  end

  describe '.for' do
    it "should return a throttling class instance" do
      stub_throttling_limits('foo' => {'limit' => 5, 'period' => 2})
      Throttling.for('foo').should be_instance_of(Throttling::Base)
    end

    it "should raise an exception if no throttling_limits found in config" do
      stub_throttling_limits(nil)
      lambda { Throttling.for('foo') }.should raise_error(ArgumentError)
    end

    it "should raise an exception if no throttling_limits[action] found in config" do
      stub_throttling_limits('foo' => nil)
      lambda { Throttling.for('foo') }.should raise_error(ArgumentError)
    end
  end

  def stub_throttling_limits(limits)
    Throttling.limits = limits
  end
end
