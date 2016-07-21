require 'spec_helper'

RSpec.describe Traitor do
  describe '#define' do
    it 'loads the content into the cache' do
      described_class.define(:some_class, {})
      expect(described_class.instance_variable_get(:@trait_library)).to eq({some_class: {}})
    end
  end
end
