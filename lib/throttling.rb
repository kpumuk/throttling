require 'logger'
require 'yaml'

module Throttling
  class << self
    def storage
      @@storage ||= (defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache) || nil
      raise ArgumentError, 'Throttling.storage is not specified' unless @@storage
      @@storage
    end

    def storage=(storage)
      @@storage = storage
    end

    def logger
      @@logger ||= (defined?(Rails) && Rails.respond_to(:logger) && Rails.logger) || Logger.new(STDOUT)
    end

    def logger=(logger)
      @@logger = logger
    end

    def limits_config
      root = (defined?(Rails) && Rails.respond_to?(:root) && Rails.root) || Dir.pwd
      @@limits_config ||= "#{root}/config/throttling.yml"
    end

    def limits_config=(path)
      @@limits = nil
      @@limits_config = path
    end

    def limits
      @@limits ||= load_config(limits_config)
    end

    def limits=(limits)
      @@limits = limits && limits.with_indifferent_access
    end

    # Get the value indicating whether Metricsd is enabled.
    def enabled?
      !!@@enabled
    end
    alias :enabled :enabled?

    # Sets the value indicating whether Metricsd is enabled.
    def enabled=(enabled)
      @@enabled = !!enabled
    end

    # Enables Metricsd client.
    def enable!
      @@enabled = true
    end

    # Disables Metricsd client.
    def disable!
      @@enabled = false
    end

    def for(action)
      @@instances[action.to_s] ||= Base.new(action.to_s)
    end

    # Resets all values to their default state (mostly for testing purpose).
    def reset_defaults!
      @@enabled       = true
      @@logger        = nil
      @@storage       = nil
      @@limits_config = nil

      # Internal variables
      @@instances     = {}
      @@config        = nil
    end

    private

    def load_config(path)
      return nil unless File.exists?(path)
      YAML.load_file(path).with_indifferent_access
    end
  end

  reset_defaults!
end

require 'throttling/indifferent_access'
require 'throttling/base'
require "throttling/version"
