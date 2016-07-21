module Traitor
  class Config
    def self.configure_for_rails!
      Traitor.instance_variable_set(:@save_method, :save)
      Traitor.instance_variable_set(:@save_kwargs, {validate: false})
      Traitor.instance_variable_set(:@build_kwargs, {without_protection: true})
    end
  end
end
    
