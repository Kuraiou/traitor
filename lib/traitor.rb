require 'traitor/config'
require 'traitor/find_definitions'
require 'traitor/error'

module Traitor
  @trait_library = {}
  @block_library = {}
  @class_cache = {}
  @trait_cache = {}

  def self.reset!
    @trait_library = {}
    @block_library = {}
    @class_cache = {}
    @trait_cache = {}
  end

  def self.define(klass, **traits, &block)
    @trait_library[klass] ||= {}
    @trait_library[klass].merge!(traits)
    @block_library[klass] = block if block_given?
  end

  ##
  # build an instance of an object using the defined traits and attributes,
  # and then save it.
  ##
  def self.create(klass, *traits, **attributes, &block)
    save_method = Traitor::Config.save_method
    raise Traitor::Error.new("Cannot call Traitor.create until you have configured Traitor.save_method .") unless save_method

    @after_create_block = nil
    record = build(klass, *traits, **attributes) # note we don't pass block here.

    if (save_kwargs = Traitor::Config.save_kwargs).any? # assignment intentional
      record.public_send(save_method, **save_kwargs)
    else
      record.public_send(save_method)
    end

    blocks = [@after_create_block, (block_given? ? block : nil)].compact
    blocks.each { |blk| blk.call(record) }

    record
  end

  ##
  # build an instance of an object using the defined traits and attributes.
  ##
  def self.build(klass, *traits, **attributes, &block)
    attributes = get_attributes_from_traits(klass, traits).merge(attributes)
    after_build_block = attributes.delete :after_build
    @after_create_block = attributes.delete :after_create # we need attr assignment to bubble the block up

    record = if (build_kwargs = Traitor::Config.build_kwargs).any? # assignment intentional
      convert_to_class(klass).new(attributes, **build_kwargs)
    else
      convert_to_class(klass).new(attributes)
    end

    blocks = [@block_library[klass], after_build_block, (block_given? ? block : nil)].compact
    blocks.each { |blk| blk.call(record) }
    record
  end

  # private methods

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
        [attribute, value.is_a?(Proc) && ![:after_build, :after_create].include?(attribute) ? value.call : value]
      end
    ]
  end
  private_class_method :get_attributes_from_traits

  def self.camelize(term)
    string = term.to_s
    string[0] = string[0].upcase
    string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    string.gsub!('/'.freeze, '::'.freeze)
    string
  end
  private_class_method :camelize
end
