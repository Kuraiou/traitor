class Traitor
  @trait_library = {}
  @class_cache = {}
  @trait_cache = {}

  def self.define(klass, **traits)
    @trait_library[klass] ||= traits
  end

  ##
  # build an instance of an object using the defined traits and attributes,
  # and then save it.
  ##
  def self.create(klass, *traits, **attributes, &block)
    record = build(klass, *traits, **attributes, &block)
    record.save(validate: false)
    record
  end

  ##
  # build an instance of an object using the defined traits and attributes.
  ##
  def self.build(klass, *traits, **attributes, &block)
    attributes = get_attributes_from_traits(klass, traits).merge(attributes)
    record = convert_to_class(klass).new(attributes, without_protection: true)
    yield record if block_given?
    record
  end

  # private methods

  def self.convert_to_class(klass)
    @class_cache[klass] ||= Object.const_get(camelize(klass))
  end
  private_class_method :convert_to_class

  def self.get_attributes_from_traits(klass, *traits)
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

