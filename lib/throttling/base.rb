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
      if @limits[:period]
        if @limits[:values]
          @limits[:values] = @limits[:values].sort_by { |name, params| params && params[:limit] }
        end
        @limits = [[ 'global', @limits ]]
      else
        @limits = @limits.sort_by { |name, params| params && params[:period] }
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
        period = params[:period].to_i
        limit  = params[:limit].to_i
        values = params[:values]

        raise ArgumentError, "Invalid or no 'period' parameter in the limits[#{period_name}] config" if period < 1
        raise ArgumentError, "Invalid or no 'limit' parameter in the limits[#{period_name}] config"  if limit < 1 && !values

        key = hits_store_key(check_type, check_value, period_name, period)

        # Retrieve current value
        hits = Throttling.storage.fetch(key, :expires_in => hits_store_ttl(period), :raw => true) { '0' }.to_i

        if values
          value = params[:default_value] || false
          values.each do |value_name, value_params|
            if hits < value_params[:limit].to_i
              value = value_params[:value] || value_params[:default_value] || false
              break
            end
          end
        else
          # Over limit?
          return false if hits > limit
        end

        Throttling.storage.increment(key) if auto_increment
        return value if values
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
