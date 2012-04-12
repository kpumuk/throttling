module Throttling
  # Class implements throttling for a single action.
  class Base
    attr_accessor :action, :limits

    def initialize(action)
      @action = action.to_s

      raise ArgumentError, "No throttling limits specified" unless Throttling.limits
      @limits = Throttling.limits[action]
      raise ArgumentError, "No Throttling.limits[#{action}] section found" unless limits

      # Convert simple limits to a hash
      if @limits[:limit] && @limits[:period]
        @limits = { 'global' => @limits }
      end
    end

    def check_ip(ip)
      check(:ip, ip)
    end

    def check_user_id(user_id)
      check(:user_id, user_id)
    end

    def check(check_type, check_value, auto_increment = true)
      # Disabled?
      return true if !Throttling.enabled? || check_value.nil?

      limits.each do |period_name, params|
        raise ArgumentError, "Invalid or no 'period' parameter in the limits[#{period_name}] config" if params[:period].to_i < 1
        raise ArgumentError, "Invalid or no 'limit' parameter in the limits[#{period_name}] config" if params[:limit].nil? || params[:limit].to_i < 0

        period = params[:period].to_i
        key = hits_store_key(check_type, check_value, period_name, period)

        # Retrieve current value
        hits = Throttling.storage.fetch(key, :expires_in => hits_store_ttl(period), :raw => true) { '0' }

        # Over limit?
        return false if hits.to_i > params[:limit].to_i

        Throttling.storage.increment(key) if auto_increment
      end

      return true
    end

    private

    def hits_store_key(check_type, check_value, period_name, period_value)
      "throttle:#{action}:#{check_type}:#{check_value}:#{period_name}:#{Time.now.to_i / period_value}"
    end

    def hits_store_ttl(check_period)
      check_period - Time.now.to_i % check_period
    end
  end
end
