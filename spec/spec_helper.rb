require 'bundler/setup'
require 'throttling'
require 'timecop'

class TestStorage
  attr_reader :values

  def fetch(key, options = {}, &block)
    @values ||= {}
    value = @values.fetch(key, &block)
    value = { :value => value.to_s } unless Hash === value
    @values[key] = value.merge(options)
    value[:value]
  end

  def increment(key)
    @values ||= {}
    @values[key] ||= { :value => 0 }
    @values[key][:value] = (@values[key][:value].to_i + 1).to_s
  end
end
