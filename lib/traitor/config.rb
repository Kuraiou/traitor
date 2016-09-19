module Traitor
  class Config
    @create_method  = nil
    @create_kwargs  = {}
    @build_kwargs = {}
    @build_with_list = false # use (**attributes.merge(build_kwargs)) instead of (attributes, **build_kwargs)
    @no_callbacks = false

    class << self
      attr_accessor :create_method, :create_kwargs, :build_kwargs, :build_with_list, :no_callbacks

      def configure_for_rails!
        @create_method  = :save
        @create_kwargs  = { validate: false }
        @build_kwargs   = { without_protection: true }
      end

      def configure_safe_for_rails!
        @create_method  = :save
        @create_kwargs  = {}
        @build_kwargs   = {}
      end

      # Undefine all configuration values.
      def reset!
        @create_method   = nil
        @create_kwargs   = {}
        @build_kwargs    = {}
        @build_with_list = false
        @no_callbacks    = false
      end

      # Temporarily store the old configuration, so the config can be modified and
      # then later restored.
      def stash!
        @old_config = Hash[
          self.instance_variables.map { |att| [att, self.instance_variable_get(att)] }
        ]
      end

      # After calling #stash!, call this to restore the stashed config.
      def restore!
        return unless @old_config
        @old_config.each { |att, val| self.instance_variable_set(att, val) }
        @old_config = nil
      end
    end
  end
end
