require 'spec_helper'

RSpec.describe Traitor do
  after do
    # reset the Traitor class.
    Traitor.reset!
  end

  describe '#define' do
    it 'loads the content into the cache' do
      Traitor.define(:test_class, {})
      expect(Traitor.instance_variable_get(:@trait_library)).to eq({test_class: {}})
    end

    it 'allows redefinition traits for a class' do
      Traitor.define(:test_class, {})
      Traitor.define(:test_class, {t1: {}})
      expect(Traitor.instance_variable_get(:@trait_library)).to eq({test_class: {t1: {}}})
    end

    it 'overwrites on redefinition but does not lose old values' do
      Traitor.define(:test_class, {t1: {}, t2: {}})
      Traitor.define(:test_class, {t2: {foo: :bar}})
      expect(Traitor.instance_variable_get(:@trait_library)).to eq({test_class: {t1: {}, t2: {foo: :bar}}})
    end

    it 'does not raise an error if the class does not exist' do
      expect{ Traitor.define(:foo_bar, {}) }.to_not raise_error
    end
  end

  describe '#create' do
    before { Traitor.define(:test_class, {}) } # assuming an empty
    it 'raises an error if we have not configured the save' do
      expect{ Traitor.create(:test_class) }.to raise_error(Traitor::Error)
    end

    context 'with a configured save method' do
      before { Traitor.save_method = :create }

      it 'will call the save method after building the object' do
        expect_any_instance_of(TestClass).to receive(:create)
        Traitor.create(:test_class)
      end

      it 'raises an error if the class does not exist' do
        expect{ Traitor.create(:foo_bar) }.to raise_error(Traitor::Error)
      end

      it 'will create the class even without a definition' do
        expect(Traitor.create(:test_class)).to be_an_instance_of TestClass
      end

      it 'ignores traits' do
        expect(Traitor.create(:test_class, :nonsense)).to be_an_instance_of TestClass
      end

      context 'with a definition' do
        before do
          Traitor.define :test_class,
            trait1: {
              param1: :foo,
              param2: :bar
            }
        end

        it 'uses static values' do
          expect(Traitor.create(:test_class, :trait1)).to have_attributes(
            param1: :foo,
            param2: :bar
          )
        end

        it 'allows overriding of values' do
          expect(Traitor.create(:test_class, :trait1, param1: :baz)).to have_attributes(
            param1: :baz,
            param2: :bar
          )
        end

        it 'executes lambda values at creation, not definition' do
          Timecop.freeze(DateTime.new(2016, 1, 1)) do
            Traitor.define :test_class,
              trait2: {
                param1: ->{ DateTime.now }
              }

          end

          created_at = DateTime.new(2016, 5, 1)
          Timecop.freeze(created_at) do
            expect(Traitor.create(:test_class, :trait2).param1).to eq created_at
          end
        end
      end
    end
  end
end
