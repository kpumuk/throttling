require "spec_helper"

RSpec.describe Throttling do
  before do
    Throttling.reset_defaults!
    @storage = Throttling.storage = TestStorage.new
  end

  describe "instance methods" do
    before do
      Throttling.limits = {"foo" => {"limit" => 5, "period" => 2}}
      @t = Throttling.for("foo")
    end

    {check_ip: "127.0.0.1", check_user_id: 123}.each do |check_method, valid_value|
      describe check_method do
        it "should return true for nil check_values" do
          expect(@t.send(check_method, nil)).to be_truthy
        end

        it "should return true if no limit specified in configs" do
          Throttling.limits["foo"]["limit"] = nil
          allow(@storage).to receive(:fetch) { 1000 }
          expect(@t.send(check_method, valid_value)).to be_truthy
        end

        it "should return false if limit is 0" do
          Throttling.limits["foo"]["limit"] = 0
          allow(@storage).to receive(:fetch) { 0 }
          expect(@t.send(check_method, valid_value)).to be_falsey
        end

        it "should raise an exception if no period specified in configs" do
          Throttling.limits["foo"]["period"] = nil
          expect { @t.send(check_method, valid_value) }.to raise_error(ArgumentError)
        end

        it "should raise an exception if invalid period specified in configs" do
          Throttling.limits["foo"]["period"] = -1
          expect { @t.send(check_method, valid_value) }.to raise_error(ArgumentError)

          Throttling.limits["foo"]["period"] = "foo"
          expect { @t.send(check_method, valid_value) }.to raise_error(ArgumentError)
        end

        it "should return true if throttling limit is not passed" do
          allow(@storage).to receive(:fetch) { 1 }
          expect(@t.send(check_method, valid_value)).to be_truthy
        end

        it "should return false if throttling limit is passed" do
          allow(@storage).to receive(:fetch) { Throttling.limits["foo"]["limit"] + 1 }
          expect(@t.send(check_method, valid_value)).to be_falsey
        end

        context "around limit" do
          it "should increase hit counter when values equals to limit - 1" do
            allow(@storage).to receive(:fetch) { Throttling.limits["foo"]["limit"] - 1 }
            allow(@storage).to receive(:increment)
            @t.send(check_method, valid_value)
            expect(@storage).to have_received(:increment)
          end

          it "should not increase hit counter when values equals to limit" do
            allow(@storage).to receive(:fetch) { Throttling.limits["foo"]["limit"] }
            allow(@storage).to receive(:increment)
            @t.send(check_method, valid_value)
            expect(@storage).to_not have_received(:increment)
          end

          it "should not increase hit counter when values equals to limit + 1" do
            allow(@storage).to receive(:fetch) { Throttling.limits["foo"]["limit"] + 1 }
            allow(@storage).to receive(:increment)
            @t.send(check_method, valid_value)
            expect(@storage).to_not have_received(:increment)
          end

          it "should allow exactly limit actions" do
            5.times do
              expect(@t.send(check_method, valid_value)).to be_truthy
            end
            allow(@storage).to receive(:increment)
            expect(@t.send(check_method, valid_value)).to be_falsey
            expect(@storage).to_not have_received(:increment)
          end
        end
      end
    end
  end

  describe "with multi-level limits" do
    before do
      Throttling.limits = {"foo" => {"two" => {"limit" => 10, "period" => 20}, "one" => {"limit" => 5, "period" => 2}}}
    end

    it "should return false if at least one limit is reached" do
      allow(@storage).to receive(:fetch).and_return(1, 100)
      expect(Throttling.for("foo").check_ip("127.0.0.1")).to be_falsey
    end

    it "should return true if none limits reached" do
      allow(@storage).to receive(:fetch).and_return(1, 2)
      expect(Throttling.for("foo").check_ip("127.0.0.1")).to be_truthy
    end

    it "should sort limits by period" do
      allow(@storage).to receive(:fetch).with(/:one:/, anything) { 0 }
      allow(@storage).to receive(:fetch).with(/:two:/, anything) { 0 }
      expect(Throttling.for("foo").check_ip("127.0.0.1")).to be_truthy
    end

    it "should return as soon as limit reached" do
      allow(@storage).to receive(:fetch).with(/:one:/, anything).and_return(10)
      expect(Throttling.for("foo").check_ip("127.0.0.1")).to be_falsey
    end
  end

  context "with values specified" do
    before do
      Throttling.limits_config = File.expand_path("../fixtures/throttling.yml", __FILE__)
    end

    it "should return value when limit is not reached" do
      allow(@storage).to receive(:fetch).and_return(0)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(10)
      allow(@storage).to receive(:fetch).and_return(4)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(10)

      allow(@storage).to receive(:fetch).and_return(5)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(15)
      allow(@storage).to receive(:fetch).and_return(14)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(15)

      allow(@storage).to receive(:fetch).and_return(15)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(20)
      allow(@storage).to receive(:fetch).and_return(99)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(20)

      allow(@storage).to receive(:fetch).and_return(100)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(25)
      allow(@storage).to receive(:fetch).and_return(1000)
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to eq(25)
    end

    it "should increase hit counter when hitting low limit" do
      allow(@storage).to receive(:fetch) { 4 }
      allow(@storage).to receive(:increment)
      Throttling.for("request_priority").check_ip("127.0.0.1")
      expect(@storage).to have_received(:increment)
    end

    it "should increase hit counter when hitting high limit" do
      allow(@storage).to receive(:fetch) { 1000 }
      allow(@storage).to receive(:increment)
      Throttling.for("request_priority").check_ip("127.0.0.1")
      expect(@storage).to have_received(:increment)
    end

    it "should return false when highest limit reached" do
      Throttling.limits["request_priority"].delete("default_value")
      allow(@storage).to receive(:fetch) { 1000 }
      expect(Throttling.for("request_priority").check_ip("127.0.0.1")).to be_falsey
    end
  end

  context do
    before do
      Throttling.limits = {"foo" => {"limit" => 5, "period" => 86400}}
      @timestamp = 1334261569
    end

    describe "key name" do
      it "should include type, value, name, and period start" do
        Timecop.freeze(Time.at(@timestamp)) do
          Throttling.for("foo").check_ip("127.0.0.1")
        end
        expect(@storage.values.keys.first).to eq("throttle:foo:ip:127.0.0.1:global:15442")
      end
    end

    describe "key expiration" do
      it "should calculate expiration time" do
        Timecop.freeze(Time.at(@timestamp)) do
          Throttling.for("foo").check_ip("127.0.0.1")
        end
        expect(@storage.values.values.first[:expires_in]).to eq(13631)
      end
    end
  end
end
