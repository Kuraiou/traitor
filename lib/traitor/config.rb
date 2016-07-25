module Traitor
  class Config
    @save_method  = nil
    @save_kwargs  = {}
    @build_kwargs = {}
    @build_with_list = false # use (**attributes.merge(build_kwargs)) instead of (attributes, **build_kwargs)

    class << self
      attr_accessor :save_method, :save_kwargs, :build_kwargs, :build_with_list

      def configure_for_rails!
        @save_method  = :save
        @save_kwargs  = { validate: false }
        @build_kwargs = { without_protection: true }
        @build_with_list = false
      end

      def configure_safe_for_rails!
        @save_method  = :save
        @save_kwargs  = {}
        @build_kwargs = {}
        @build_with_list = false
      end

      def reset!
        @save_method = nil
        @save_kwargs = {}
        @build_kwargs = {}
        @build_with_list = false
      end
    end
  end
end
