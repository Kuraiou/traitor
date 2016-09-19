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
    # Reset Traitor entirely by clearing its attributes.
    def reset!
      @trait_library = {}
      @alternate_create_methods = {}
      @block_library = {}
      @class_cache = {}
      @trait_cache = {}
    end

    # Hook an object into Traitor. Read GETTING_STARTED.md for assistance.
    #
    # @param [String|Symbol] klass - the class reference.
    # @param [Hash] traits - the hash of traits defined on the Traitor.s
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

    # build an instance of an object using the defined traits and attributes.
    #
    # @param [String|Symbol] klass - the class reference symbol to get the library from
    # @param [Array] traits - the list of traits to refer attributes from
    # @param [Hash] attributes - the list of attributes to apply to the specific object.
    def build(klass, *traits, **attributes)
      attrs, concat_attrs = split_attributes(attributes)
      attributes = get_attributes_from_traits(klass, traits).merge(attrs)
      # but add all the separate concatenated attributes into a list.
      concat_attrs.each do |k, v|
        attributes[k] ||= []
        attributes[k] << v
      end

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

    # build an instance of an object using the defined traits and attributes,
    # and then save it using the appropriate create method.
    #
    # @param [String|Symbol] klass - the class reference symbol to get the library from
    # @param [Array] traits - the list of traits to refer attributes from
    # @param [Hash] attributes - the list of attributes to apply to the specific object.
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

    # build an instance of an object using the defined traits and attributes,
    # and then save it using the explicitly referenced create method.
    #
    # @param [String|Symbol] klass - the class reference symbol to get the library from
    # @param [Array] traits - the list of traits to refer attributes from
    # @param [Hash] attributes - the list of attributes to apply to the specific object.
    def create_using(klass, create_method, *traits, **attributes)
      old_create_method_kwargs = @alternate_create_methods[klass]
      @alternate_create_methods[klass] = [create_method, attributes.delete(:create_kwargs) || {}]
      create(klass, *traits, **attributes)
    ensure
      @alternate_create_methods[klass] = old_create_method_kwargs
    end

    private

    # Helper method to call after blocks that are defined on a Traitor.
    #
    # @param [String|Symbol] klass - the class reference for the library.
    # @param [Symbol] trigger - one of the values in BLOCK_KEYS, to check for in
    #                 the block library.
    # @param [Object] record - the object the trigger will yield.
    # @param [Array] traits - A list of traits that the object was built with,
    #                to find any triggers specific to the referenced traits.
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

    # given a string/symbol, return the class based on that symbol.
    # e.g. :some_class -> SomeClass
    #
    # @param [String|Symbol] klass - the class symbol/reference
    # @return [Object] the class
    def convert_to_class(klass)
      @class_cache[klass] ||= Object.const_get(camelize(klass))
    rescue NameError
      raise Traitor::Error.new("Tried to create a #{camelize(klass)}, but it does not exist!")
    end

    # Given a list of traits, return the compiled hash of attributes with calculated values.
    # Will properly call lambdas/procs to get their value and will concatenate attributes
    # prefixed with a '+'.
    #
    # Will always start from the :default_traits trait, if it exists.
    #
    # @param [String|Symbol] klass - the class reference to get the list of traits from the library.
    # @param [Array[String|Symbol]] traits - a list of traits to refer to in the library.
    # @return [Hash] The calculated attributes hash.
    def get_attributes_from_traits(klass, traits)
      # we only call this method when the klass has been converted to a key inside create
      return {} unless library = @trait_library[klass]

      traits = [:default_traits] + traits # always include default_traits as the first thing

      cache_key = klass.to_s + ':' + traits.join(':')
      @trait_cache[cache_key] ||= {}.tap do |attributes|
        traits.each do |trait|
          # pull out concatenating attributes into their own list
          attrs, concat_attrs = split_attributes(library[trait] || {})

          # raw merge in the standard attributes...
          attributes.merge!(attrs)

          # but add all the separate concatenated attributes into a list.
          concat_attrs.each do |k, v|
            attributes[k] ||= []
            attributes[k] << v
          end
        end
      end

      # use late resolution on lambda values by calling them here as part of constructing a new hash
      Hash[
        @trait_cache[cache_key].map do |attribute, value|
          [attribute, calculate_value(value)]
        end
      ]
    end

    # Split a hash into two hashes, the first being a list of all values that do
    # not begin with '+', the latter being a list of all values that do.
    #
    # @param [Hash] attributes
    # @return [Array[Hash, Hash]] The split hash.
    def split_attributes(attributes)
      attributes.reduce([{}, {}]) do |memo, attr_val|
        attribute, value = attr_val
        if attribute.to_s.start_with?('+')
          memo[1][attribute[1..-1].to_sym] = value
        else
          memo[0][attribute] = value
        end
        memo
      end
    end

    # Given the value reference from an attribute, call it if callable, or map it
    # if appropriate, or return it as-is.
    #
    # @param [Mixed] v - the value from an attribute. can be Proc, Array, or "value"
    # @return the calculated value.
    def calculate_value(v)
      return v.call if v.is_a?(Proc)
      return v.map { |sv| calculate_value(sv) } if v.is_a?(Array)
      v
    end

    # simplifed version of ActiveRecord camelize.
    # used to convert a generic class name (in)
    #
    # @param [String|Symbol] term - the term to symbolize
    # @return [String] the camel-cased version of the term, to be retrieved as a const.
    def camelize(term)
      term.to_s.capitalize
        .gsub(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
        .gsub('/'.freeze, '::'.freeze)
    end
  end
end
