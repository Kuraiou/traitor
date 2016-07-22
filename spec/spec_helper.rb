$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'bundler/setup'
require 'rspec/its'
require 'pry'
require 'timecop'

require 'traitor'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end

# for testing

class TestClass
  attr_accessor :param1, :param2
  def initialize(*args, **kwargs)
    attrs = args[0] || kwargs
    @param1 = attrs[:param1]
    @param2 = attrs[:param2]
  end

  def create(*args, **kwargs)
    # nop; for testing purposes only
  end
end
