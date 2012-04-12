require 'bundler/setup'
require 'throttling'
require 'timecop'

class TestStorage
  attr_reader :values

  def fetch(key, options, &block)
    @values ||= {}
    value = @values.fetch(key, &block)
    @values[key] = options.merge(:value => value.to_s)
    value
  end

  def increment(key)
    @values ||= {}
    @values[key] ||= { :value => 0 }
    @values[key][:value] = (@values[key][:value].to_i + 1).to_s
  end
end
