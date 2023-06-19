require "spec_helper"

RSpec.describe Throttling do
  after :each do
    Throttling.reset_defaults!
  end

  context "with defaults" do
    it "should create logger" do
      expect(Throttling.logger).to be_a(Logger)
    end

    it "should be enabled" do
      expect(Throttling.enabled?).to be_truthy
      expect(Throttling.enabled).to be_truthy
    end

    it "should set config file path" do
      expect(Throttling.limits_config).to eq("#{Dir.pwd}/config/throttling.yml")
    end
  end

  context "setters" do
    it "should allow to enabled and disable client" do
      Throttling.enabled = false
      expect(Throttling).to_not be_enabled

      Throttling.enable!
      expect(Throttling).to be_enabled

      Throttling.disable!
      expect(Throttling).to_not be_enabled

      Throttling.enabled = true
      expect(Throttling).to be_enabled
    end

    it "should allow to change logger" do
      mock = Throttling.logger = double("Logger")
      expect(Throttling.logger).to be(mock)
    end

    it "should allow to set limits" do
      limits = {"foo" => {"limit" => 5, "period" => 2}}
      Throttling.limits = limits
      expect(Throttling.limits).to eq(limits)
    end

    it "should allow to change config file path" do
      path = File.expand_path("../fixtures/throttling.yml", __FILE__)
      Throttling.limits_config = path
      expect(Throttling.limits_config).to eq(path)
    end
  end

  describe ".for" do
    it "should return a throttling class instance" do
      Throttling.limits = {"foo" => {"limit" => 5, "period" => 2}}
      expect(Throttling.for("foo")).to be_instance_of(Throttling::Base)
    end

    it "should raise an exception if no throttling_limits found in config" do
      Throttling.limits = nil
      expect { Throttling.for("foo") }.to raise_error(ArgumentError)
    end

    it "should raise an exception if no throttling_limits[action] found in config" do
      Throttling.limits = {"foo" => nil}
      expect { Throttling.for("foo") }.to raise_error(ArgumentError)
    end
  end

  describe "limits" do
    context "when set using .limits" do
      it "should convert Hash to HashWithIndifferentAccess" do
        Throttling.limits = {"foo" => {"limit" => 5, "period" => 2}}
        expect(Throttling.limits).to have_key(:foo)
        expect(Throttling.limits).to have_key("foo")
        expect(Throttling.limits[:foo]).to have_key(:limit)
        expect(Throttling.limits[:foo]).to have_key("limit")
      end
    end

    context "when set using .limits_config" do
      before do
        Throttling.limits_config = File.expand_path("../fixtures/throttling.yml", __FILE__)
      end

      it "should load limits from configuration file" do
        expect(Throttling.limits).to be_kind_of(Hash)
        expect(Throttling.limits).to have_key("search_requests")
        expect(Throttling.limits).to have_key("user_signup")
      end

      it "should convert Hash to HashWithIndifferentAccess" do
        expect(Throttling.limits).to have_key(:search_requests)
        expect(Throttling.limits).to have_key("search_requests")
        expect(Throttling.limits[:search_requests]).to have_key(:daily)
        expect(Throttling.limits[:search_requests]).to have_key("daily")
      end
    end
  end
end
