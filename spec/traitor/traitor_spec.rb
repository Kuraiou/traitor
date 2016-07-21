require 'spec_helper'

class TestClass
  def initialize(param1)
  end
end

RSpec.describe Traitor do
  before do
    described_class.define(:test_class, {})
  end

  after do
    # reset the Traitor class.
    Traitor.reset!
  end

  describe '#define' do
    it 'loads the content into the cache' do
      expect(described_class.instance_variable_get(:@trait_library)).to eq({test_class: {}})
    end

    it 'allows redifinition traits for a class' do
      described_class.define(:test_class, {t2: {}})
      expect(described_class.instance_variable_get(:@trait_library)).to eq({test_class: {t2: {}}})
    end
  end

  describe '#create' do
    it 'raises an error if we have not configured the save' do
      expect{described_class.create(:test_class)}.to raise_error(Traitor::Error)
    end
  end
end
