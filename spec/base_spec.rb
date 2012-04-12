require 'spec_helper'

describe Throttling do
  before do
    Throttling.reset_defaults!
    @storage = Throttling.storage = TestStorage.new
  end

  describe 'instance methods' do
    before do
      Throttling.limits = { 'foo' => {'limit' => 5, 'period' => 2} }
      @t = Throttling.for('foo')
    end

    { :check_ip => '127.0.0.1', :check_user_id => 123 }.each do |check_method, valid_value|
      describe check_method do
        it 'should return true for nil check_values' do
          @t.send(check_method, nil).should be_true
        end

        it 'should raise an exception if no limit specified in configs' do
          Throttling.limits['foo']['limit'] = nil
          lambda { @t.send(check_method, valid_value) }.should raise_error(ArgumentError)
        end

        it 'should raise an exception if no period specified in configs' do
          Throttling.limits['foo']['period'] = nil
          lambda { @t.send(check_method, valid_value) }.should raise_error(ArgumentError)
        end

        it 'should raise an exception if invalid period specified in configs' do
          Throttling.limits['foo']['period'] = -1
          lambda { @t.send(check_method, valid_value) }.should raise_error(ArgumentError)

          Throttling.limits['foo']['period'] = 'foo'
          lambda { @t.send(check_method, valid_value) }.should raise_error(ArgumentError)
        end

        it 'should return true if throttling limit is not passed' do
          @storage.should_receive(:fetch).and_return(1)
          @t.send(check_method, valid_value).should be_true
        end

        it 'should return false if throttling limit is passed' do
          @storage.should_receive(:fetch).and_return(Throttling.limits['foo']['limit'] + 1)
          @t.send(check_method, valid_value).should be_false
        end

        context 'around limit' do
          it 'should increase hit counter when values equals to limit - 1' do
            @storage.should_receive(:fetch).and_return(Throttling.limits['foo']['limit'] - 1)
            @storage.should_receive(:increment)
            @t.send(check_method, valid_value)
          end

          it 'should increase hit counter when values equals to limit' do
            @storage.should_receive(:fetch).and_return(Throttling.limits['foo']['limit'])
            @storage.should_receive(:increment)
            @t.send(check_method, valid_value)
          end

          it 'should increase hit counter when values equals to limit + 1' do
            @storage.should_receive(:fetch).and_return(Throttling.limits['foo']['limit'] + 1)
            @storage.should_not_receive(:increment)
            @t.send(check_method, valid_value)
          end
        end
      end
    end
  end

  describe 'with multi-level limits' do
    before do
      Throttling.limits = { 'foo' => { 'two' => { 'limit' => 10, 'period' => 20 }, 'one' => { 'limit' => 5, 'period' => 2 } } }
    end

    it 'should return false if at least one limit is reached' do
      @storage.should_receive(:fetch).and_return(1, 100)
      Throttling.for('foo').check_ip('127.0.0.1').should be_false
    end

    it 'should return true if none limits reached' do
      @storage.should_receive(:fetch).and_return(1, 2)
      Throttling.for('foo').check_ip('127.0.0.1').should be_true
    end

    it 'should sort limits by period' do
      @storage.should_receive(:fetch).ordered.with(/\:one\:/, anything).and_return(0)
      @storage.should_receive(:fetch).ordered.with(/\:two\:/, anything).and_return(0)
      Throttling.for('foo').check_ip('127.0.0.1').should be_true
    end

    it 'should return as soon as limit reached' do
      @storage.should_receive(:fetch).ordered.with(/\:one\:/, anything).and_return(10)
      @storage.should_not_receive(:fetch).with(/\:two\:/)
      Throttling.for('foo').check_ip('127.0.0.1').should be_false
    end
  end

  context do
    before do
      Throttling.limits = { 'foo' => {'limit' => 5, 'period' => 86400} }
      @timestamp = 1334261569
    end

    describe 'key name' do
      it 'should include type, value, name, and period start' do
        Timecop.freeze(Time.at(@timestamp)) do
          Throttling.for('foo').check_ip('127.0.0.1')
        end
        @storage.values.keys.first.should == 'throttle:foo:ip:127.0.0.1:global:15442'
      end
    end

    describe 'key expiration' do
      it 'should calculate expiration time' do
        Timecop.freeze(Time.at(@timestamp)) do
          Throttling.for('foo').check_ip('127.0.0.1')
        end
        @storage.values.values.first[:expires_in].should == 13631
      end
    end
  end
end
