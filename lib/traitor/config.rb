module Traitor
  class Config
    @create_method  = nil
    @create_kwargs  = {}
    @build_kwargs = {}
    @build_with_list = false # use (**attributes.merge(build_kwargs)) instead of (attributes, **build_kwargs)

    class << self
      attr_accessor :create_method, :create_kwargs, :build_kwargs, :build_with_list

      def configure_for_rails!
        @create_method  = :save
        @create_kwargs  = { validate: false }
        @build_kwargs = { without_protection: true }
        @build_with_list = false
      end

      def configure_safe_for_rails!
        @create_method  = :save
        @create_kwargs  = {}
        @build_kwargs = {}
        @build_with_list = false
      end

      def reset!
        @create_method = nil
        @create_kwargs = {}
        @build_kwargs = {}
        @build_with_list = false
      end
    end
  end
end
