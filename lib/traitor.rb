require 'traitor/config'
require 'traitor/find_definitions'
require 'traitor/error'

module Traitor
  BLOCK_KEYS = [:after_build, :after_create]

  @trait_library = {}
  @alternate_create_methods = {}
  @block_library = {}
  @class_cache = {}
  @trait_cache = {}

  class << self
    def reset!
      @trait_library = {}
      @alternate_create_methods = {}
      @block_library = {}
      @class_cache = {}
      @trait_cache = {}
    end

    def define(klass, **traits)
      @trait_library[klass] ||= {}

      if alternate_create_method = traits.delete(:create_using)
        @alternate_create_methods[klass] = [alternate_create_method, traits.delete(:create_using_kwargs) || {}]
      end

      (traits.keys & BLOCK_KEYS).each do |block_type|
        raise Traitor::Error.new("Callbacks are forbidden!") if Traitor::Config.no_callbacks
        block = traits.delete block_type
        @block_library[klass] ||= {class: {}, traits: {}}
        @block_library[klass][:class][block_type] = block
      end

      traits.each do |trait, attributes|
        (attributes.keys & BLOCK_KEYS).each do |block_type|
          raise Traitor::Error.new("Callbacks are forbidden!") if Traitor::Config.no_callbacks
          block = attributes.delete block_type
          @block_library[klass] ||= {class: {}, traits: {}}
          @block_library[klass][:traits][trait] ||= {}
          @block_library[klass][:traits][trait][block_type] = block
        end
      end

      @trait_library[klass].merge!(traits)
    end

    ##
    # build an instance of an object using the defined traits and attributes.
    ##
    def build(klass, *traits, **attributes)
      attributes = get_attributes_from_traits(klass, traits).merge(attributes)
      build_kwargs = Traitor::Config.build_kwargs || {}

      record = if Traitor::Config.build_with_list
        convert_to_class(klass).new(**attributes.merge(build_kwargs))
      elsif build_kwargs.any?
        convert_to_class(klass).new(attributes, **build_kwargs)
      else
        convert_to_class(klass).new(attributes)
      end

      call_blocks(klass, :after_build, record, *traits)
      record
    end

    ##
    # build an instance of an object using the defined traits and attributes,
    # and then save it.
    ##
    def create(klass, *traits, **attributes)
      create_method, create_kwargs = @alternate_create_methods[klass] ||
        [Traitor::Config.create_method, Traitor::Config.create_kwargs || {}]

      raise Traitor::Error.new("Cannot call Traitor.create until you have configured Traitor.create_method .") unless create_method

      record = build(klass, *traits, **attributes)

      if create_kwargs.any? # assignment intentional
        record.public_send(create_method, **create_kwargs)
      else
        record.public_send(create_method)
      end

      call_blocks(klass, :after_create, record, *traits)
      record
    end

    def create_using(klass, create_method, *traits, **attributes)
      old_create_method_kwargs = @alternate_create_methods[klass]
      @alternate_create_methods[klass] = [create_method, attributes.delete(:create_kwargs) || {}]
      create(klass, *traits, **attributes)
    ensure
      @alternate_create_methods[klass] = old_create_method_kwargs
    end

    private

    def call_blocks(klass, trigger, record, *traits)
      return unless @block_library[klass]
      [].tap do |blocks|
        blocks << @block_library[klass][:class][trigger]
        traits.each do |trait|
          if @block_library[klass][:traits][trait]
            blocks << @block_library[klass][:traits][trait][trigger]
          end
        end
      end.compact.each { |block| block.call(record) }
    end

    def convert_to_class(klass)
      @class_cache[klass] ||= Object.const_get(camelize(klass))
    rescue NameError
      raise Traitor::Error.new("Tried to create a #{camelize(klass)}, but it does not exist!")
    end

    def get_attributes_from_traits(klass, traits)
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

    def camelize(term)
      string = term.to_s
      string[0] = string[0].upcase
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      string.gsub!('/'.freeze, '::'.freeze)
      string
    end
  end
end
