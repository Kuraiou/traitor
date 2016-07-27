require 'spec_helper'

RSpec.describe Traitor do
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

  describe '#build', traitor_build_kwargs: {foo: 'bar'}  do
    before { Traitor.define(:test_class, {}) }
    let(:obj) { Traitor.build(:test_class, param1: :foo) }

    context 'when build_with_lists is not set' do
      it 'passes attributes as a hash, and build kwargs as kwargs' do
        expect(obj).to have_attributes(
          args: [{param1: :foo}],
          kwargs: {foo: 'bar'}
        )
      end
    end

    context 'when build_with_lists is set', traitor_build_with_list: true do
      it 'combines build kwargs and attributes' do
        expect(obj).to have_attributes(
          args: [],
          kwargs: {param1: :foo, foo: 'bar'}
        )
      end
    end
  end

  describe '#create' do
    before { Traitor.define(:test_class, {}) } # assuming an empty
    it 'raises an error if we have not configured the save' do
      expect{ Traitor.create(:test_class) }.to raise_error(Traitor::Error)
    end

    context 'with a configured save method' do
      before { Traitor::Config.create_method = :create }

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

  describe '#create_using' do
    before { Traitor.define(:test_class, {}) } # assuming an empty
    before { Traitor::Config.create_method = :create }
    it 'will use the specified method, but keep the internal create_method' do
      expect_any_instance_of(TestClass).to receive(:create_two)
      Traitor.create_using(:test_class, :create_two)
    end
  end

  describe 'calling blocks' do
    let(:tracker) { {
      class_build_called_at: nil,
      class_create_called_at: nil,
      trait_build_called_at: nil,
      trait_create_called_at: nil,
    } }

    context 'when callbacks are allowed' do
      before do
        Traitor::Config.create_method = :create
        Traitor.define(:test_class, {
          trait1: {
            after_build: ->(record) do
              tracker[:trait_build_called_at] = DateTime.now
              sleep 0.001
            end,
            after_create: ->(record) do
              tracker[:trait_create_called_at] = DateTime.now
              sleep 0.001
            end
          },
          after_build: ->(record) do
            tracker[:class_build_called_at] = DateTime.now
            sleep 0.001
          end,
          after_create: ->(record) do
            tracker[:class_create_called_at] = DateTime.now
            sleep 0.001
          end
        })
      end

      it 'calls all blocks in least-to-most-specific order' do
        Traitor.create(:test_class, :trait1)

        expect(tracker[:trait_create_called_at]).to be > tracker[:class_create_called_at]
        expect(tracker[:class_create_called_at]).to be > tracker[:trait_build_called_at]
        expect(tracker[:trait_build_called_at]).to be > tracker[:class_build_called_at]
      end
    end

    context 'when Traitor::Config.no_callbacks is set', traitor_no_callbacks: true do
      it 'raises an error if callbacks are configured in the definition' do
        expect{Traitor.define(:test_class, {after_create: nil})}.to raise_error(Traitor::Error)
      end

      it 'raises an error if callbacks are configured in the trait' do
        expect{Traitor.define(:test_class, {trait: {after_create: nil}})}.to raise_error(Traitor::Error)
      end
    end
  end
end
