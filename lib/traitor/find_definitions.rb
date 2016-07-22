# pulled from https://github.com/thoughtbot/factory_girl/blob/e84bfeba9b9859ebf0884c0c47f84dd7ded381e1/lib/factory_girl/find_definitions.rb
# as of 2016-07-21
# all credit reserved
module Traitor
  class << self
    # An Array of strings specifying locations that should be searched for
    # factory definitions. By default, traitor will attempt to require
    # "traitors", "test/traitors" and "spec/traitors". Only the first
    # existing file will be loaded.
    attr_accessor :definition_file_paths
  end

  self.definition_file_paths = %w(traitors test/traitors spec/traitors)

  def self.find_definitions
    absolute_definition_file_paths = definition_file_paths.map { |path| File.expand_path(path) }

    absolute_definition_file_paths.uniq.each do |path|
      load("#{path}.rb") if File.exist?("#{path}.rb")

      if File.directory? path
        Dir[File.join(path, '**', '*.rb')].sort.each do |file|
          load file
        end
      end
    end
  end
end
