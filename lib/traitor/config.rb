module Traitor
  class Config
    def self.configure_for_rails!
      Traitor.instance_variable_set(:@save_method, :save)
      Traitor.instance_variable_set(:@save_kwargs, {validate: false})
      Traitor.instance_variable_set(:@build_kwargs, {without_protection: true})
    end

    def self.configure_safe_for_rails!
      Traitor.instance_variable_set(:@save_method, :save)
      Traitor.instance_variable_set(:@save_kwargs, {})
      Traitor.instance_variable_set(:@build_kwargs, {})
    end
  end
end
