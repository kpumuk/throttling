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

    it 'should set config file path' do
      Throttling.limits_config.should == "#{Dir.pwd}/config/throttling.yml"
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

    it 'should allow to set limits' do
      limits = { 'foo' => {'limit' => 5, 'period' => 2} }
      Throttling.limits = limits
      Throttling.limits.should == limits
    end

    it 'should allow to change config file path' do
      path = File.expand_path('../fixtures/throttling.yml', __FILE__)
      Throttling.limits_config = path
      Throttling.limits_config.should == path
    end
  end

  describe '.for' do
    it "should return a throttling class instance" do
      Throttling.limits = { 'foo' => {'limit' => 5, 'period' => 2} }
      Throttling.for('foo').should be_instance_of(Throttling::Base)
    end

    it "should raise an exception if no throttling_limits found in config" do
      Throttling.limits = nil
      lambda { Throttling.for('foo') }.should raise_error(ArgumentError)
    end

    it "should raise an exception if no throttling_limits[action] found in config" do
      Throttling.limits = { 'foo' => nil }
      lambda { Throttling.for('foo') }.should raise_error(ArgumentError)
    end
  end

  describe 'limits' do
    context 'when set using .limits' do
      it 'should convert Hash to HashWithIndifferentAccess' do
        Throttling.limits = { 'foo' => {'limit' => 5, 'period' => 2} }
        Throttling.limits.should have_key(:foo)
        Throttling.limits.should have_key('foo')
        Throttling.limits[:foo].should have_key(:limit)
        Throttling.limits[:foo].should have_key('limit')
      end
    end

    context 'when set using .limits_config' do
      before do
        Throttling.limits_config = File.expand_path('../fixtures/throttling.yml', __FILE__)
      end

      it 'should load limits from configuration file' do
        Throttling.limits.should be_kind_of(Hash)
        Throttling.limits.should have_key('search_requests')
        Throttling.limits.should have_key('user_signup')
      end

      it 'should convert Hash to HashWithIndifferentAccess' do
        Throttling.limits.should have_key(:search_requests)
        Throttling.limits.should have_key('search_requests')
        Throttling.limits[:search_requests].should have_key(:daily)
        Throttling.limits[:search_requests].should have_key('daily')
      end
    end
  end
end
