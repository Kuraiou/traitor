require 'traitor/helpers/active_record'
require_relative 'active_record_helper' # create TestARClass

describe 'Active Record Extensions' do
  it 'stubs quick create' do
    expect(TestActiveRecordClass.new).to respond_to :create_without_callbacks
  end

  describe '#create_without_callbacks', traitor_create_method: :create_without_callbacks do
    it 'creates via insert' do
      sql = 'INSERT INTO "test_active_record_classes" ("param") VALUES (\'foo\')'
      allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original
      expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_call_original
      object = Traitor.create(:test_active_record_class, param: :foo)
      expect(object.id).to eq 1
    end
  end
end
