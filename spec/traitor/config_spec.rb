require 'spec_helper'

RSpec.describe Traitor::Config do
  after do
    Traitor::Config.reset!
  end

  describe '.configure_for_rails!' do
    it 'sets all the required variables' do
      Traitor::Config.configure_for_rails!
      expect(Traitor::Config.create_method).to eq :save
      expect(Traitor::Config.create_kwargs).to eq({ validate: false })
      expect(Traitor::Config.build_kwargs).to eq({ without_protection: true })
    end
  end

  describe '.configure_safe_for_rails!' do
    it 'sets all the required variables' do
      Traitor::Config.configure_safe_for_rails!
      expect(Traitor::Config.create_method).to eq :save
      expect(Traitor::Config.create_kwargs).to eq({})
      expect(Traitor::Config.build_kwargs).to eq({})
    end
  end
end
