require 'spec_helper'

RSpec.describe Traitor::Config do
  describe '.configure_for_rails!' do
    it 'sets all the required variables' do
      expect(Traitor).to receive(:instance_variable_set).with(:@save_method, :save)
      expect(Traitor).to receive(:instance_variable_set).with(:@save_kwargs, {validate: false})
      expect(Traitor).to receive(:instance_variable_set).with(:@build_kwargs, {without_protection: true})
      Traitor::Config.configure_for_rails!
    end
  end

  describe '.configure_safe_for_rails!' do
    it 'sets all the required variables' do
      expect(Traitor).to receive(:instance_variable_set).with(:@save_method, :save)
      expect(Traitor).to receive(:instance_variable_set).with(:@save_kwargs, {})
      expect(Traitor).to receive(:instance_variable_set).with(:@build_kwargs, {})
      Traitor::Config.configure_safe_for_rails!
    end
  end
end
