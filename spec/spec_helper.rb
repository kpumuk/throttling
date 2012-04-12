require 'bundler/setup'
require 'throttling'

class TestStorage
  attr_reader :values

  def fetch(key, options, &block)
    @values ||= {}
    value = @values.fetch(key, &block)
    @values[key] = options.merge(:value => value)
    value
  end

  def increment(key)
    @values ||= {}
    @values[key] ||= { :value => 0 }
    @values[key][:value] += 1
  end
end
