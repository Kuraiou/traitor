require 'rspec'

module Traitor
  module Helpers
    class RSpec
      # define the metadata keys to override traitor configs on a per-example basis.
      def self.configure!
        ::RSpec.configure do |config|
          config.around(:example) do |example|
            traitor_configs = example.metadata && example.metadata.select { |key, conf| key.to_s.start_with? 'traitor_' }
            if traitor_configs && traitor_configs.any?
              Traitor::Config.stash!
              traitor_configs.each do |key, conf|
                Traitor::Config.send(:"#{key.to_s.sub('traitor_', '')}=", conf)
              end

              example.run

              Traitor::Config.restore!
            else
              example.run
            end
          end
        end
      end
    end
  end
end

Traitor::Helpers::RSpec.configure!
