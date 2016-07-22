module Traitor
  class Config
    @save_method  = nil
    @save_kwargs  = {}
    @build_kwargs = {}

    class << self
      attr_accessor :save_method, :save_kwargs, :build_kwargs

      def configure_for_rails!
        @save_method  = :save
        @save_kwargs  = { validate: false }
        @build_kwargs = { without_validation: true }
      end

      def configure_safe_for_rails!
        @save_method  = :save
        @save_kwargs  = {}
        @build_kwargs = {}
      end

      def reset!
        @save_method = nil
        @save_kwargs = {}
        @build_kwargs = {}
      end
    end
  end
end
