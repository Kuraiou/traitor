require 'traitor/config'
require 'traitor/find_definitions'
require 'traitor/error'

module Traitor
  @trait_library = {}
  @block_library = {}

  @save_method = nil
  @save_kwargs = {}
  @build_kwargs = {}

  @class_cache = {}
  @trait_cache = {}

  class << self
    attr_writer :save_method, :save_kwargs, :build_kwargs
  end

  def self.reset!
    @trait_library = {}
    @class_cache = {}
    @trait_cache = {}
  end

  def self.define(klass, **traits, &block)
    if @trait_library.include? klass
      @trait_library[klass].merge!(traits)
    else
      @trait_library[klass] = traits
    end
    @block_library[klass] = block if block_given?
  end

  ##
  # build an instance of an object using the defined traits and attributes,
  # and then save it.
  ##
  def self.create(klass, *traits, **attributes, &block)
    raise Traitor::Error.new("Cannot call Traitor.create until you have configured Traitor.save_method!") unless @save_method
    record = build(klass, *traits, **attributes, &block)
    record.public_send(@save_method, **@save_kwargs)
    yield(record, at: :create) if block_given?
    run_class_block(klass, record, :build)
    record
  end

  ##
  # build an instance of an object using the defined traits and attributes.
  ##
  def self.build(klass, *traits, **attributes, &block)
    attributes = get_attributes_from_traits(klass, traits).merge(attributes)
    record = convert_to_class(klass).new(attributes, **@build_kwargs)
    yield(record, at: :build) if block_given?
    run_class_block(klass, record, :build)
    record
  end

  # private methods

  def self.run_class_block(klass, record, at)
    class_block = @block_library[klass]
    class_block.call(record, at: at) if class_block
  end
  private_class_method :run_class_block

  def self.convert_to_class(klass)
    @class_cache[klass] ||= Object.const_get(camelize(klass))
  rescue NameError
    raise Traitor::Error.new("Tried to create a #{camelize(klass)}, but it does not exist!")
  end
  private_class_method :convert_to_class

  def self.get_attributes_from_traits(klass, traits)
    # we only call this method when the klass has been converted to a key inside create
    return {} unless library = @trait_library[klass]

    traits = [:default_traits] + traits # always include default_traits as the first thing

    cache_key = klass.to_s + ':' + traits.join(':')
    @trait_cache[cache_key] ||= {}.tap do |attributes|
      traits.each { |trait| attributes.merge!(library[trait] || {}) }
    end

    # use late resolution on lambda values by calling them here as part of constructing a new hash
    Hash[
      @trait_cache[cache_key].map do |attribute, value|
        [attribute, value.is_a?(Proc) ? value.call : value]
      end
    ]
  end
  private_class_method :get_attributes_from_traits

  def self.camelize(term)
    string = term.to_s
    string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
    string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    string.gsub!('/'.freeze, '::'.freeze)
    string
  end
  private_class_method :camelize
end
