$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'bundler/setup'
require 'rspec/its'
require 'pry'
require 'timecop'

require 'traitor'
require 'traitor/helpers/rspec' # allow traitor_# config metadata

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.after do
    Traitor.reset!
  end
end

# for testing

class TestClass
  attr_accessor :param1, :param2, :param3, :args, :kwargs
  def initialize(*args, **kwargs)
    attrs = args[0] || kwargs
    @param1 = attrs[:param1]
    @param2 = attrs[:param2]
    @param3 = attrs[:param3] || []
    @args = args
    @kwargs = kwargs
  end

  def create(*args, **kwargs)
    # nop; for testing purposes only
  end

  def create_two(*args, **kwargs)
    # nop
  end
end
