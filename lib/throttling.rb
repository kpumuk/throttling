require 'logger'
require 'yaml'

# Simple throttling library to limit number of actions in time.
module Throttling
  class << self
    # Gets current Throttling storage. By default returns Rails.cache
    # (if it is a Rails application).
    def storage
      @@storage ||= (defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache) || nil
      raise ArgumentError, 'Throttling.storage is not specified' unless @@storage
      @@storage
    end

    # Sets a storage instance to store Throttling information in. Should implement to
    # to methods:
    #
    #     def fetch(key, options = {}, &block)
    #     def increment(key)
    #
    # Rails.cache is one of the storages conforming this interface.
    def storage=(storage)
      @@storage = storage
    end

    # Gets the logger used to output errors or warnings.
    def logger
      @@logger ||= (defined?(Rails) && Rails.respond_to(:logger) && Rails.logger) || Logger.new(STDOUT)
    end

    # Sets the logger used to output errors or warnings.
    def logger=(logger)
      @@logger = logger
    end

    # Gets a throttling limits config file path.
    def limits_config
      root = (defined?(Rails) && Rails.respond_to?(:root) && Rails.root) || Dir.pwd
      @@limits_config ||= "#{root}/config/throttling.yml"
    end

    # Sets the configuration file path containing throttling limits.
    def limits_config=(path)
      @@limits = nil
      @@limits_config = path
    end

    # Gets a Hash with current throttling limits.
    def limits
      @@limits ||= load_config(limits_config)
    end

    # Sets current throttling limits.
    def limits=(limits)
      @@limits = limits && limits.with_indifferent_access
    end

    # Get the value indicating whether throttling is enabled.
    def enabled?
      !!@@enabled
    end
    alias :enabled :enabled?

    # Sets the value indicating whether throttling is enabled.
    def enabled=(enabled)
      @@enabled = !!enabled
    end

    # Enables throttling.
    def enable!
      @@enabled = true
    end

    # Disables throttling.
    def disable!
      @@enabled = false
    end

    # Returns a Throttling::Base instance for a given action.
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
