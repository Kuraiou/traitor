require 'traitor/helpers/active_record'
require_relative 'active_record_helper' # create TestARClass

describe 'Active Record Extensions' do
  it 'stubs create without callbacks' do
    expect(TestActiveRecordClass.new).to respond_to :create_without_callbacks
  end

  describe '#create_without_callbacks', traitor_create_method: :create_without_callbacks do
    describe 'With SQLite' do
      it 'creates via insert' do
        sql = 'INSERT INTO "test_active_record_classes" ("param") VALUES (\'foo\')'
        allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original
        expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_call_original
        object = Traitor.create(:test_active_record_class, param: :foo)
        expect(object.id).to eq 1
      end
    end

    describe 'With PGSQL' do
      let(:insert_sql) { 'INSERT INTO "test_active_record_classes" ("param") VALUES (\'foo\')' }
      let(:stubbed_connection) {
        double(
          execute: [{'id' => 1}],
          class: double(name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'),
          # from arel
          visitor: double(accept: double(value: insert_sql)),
          schema_cache: ActiveRecord::Base.connection.send(:schema_cache),
        )
      }

      before do
        allow(ActiveRecord::Base).to receive(:connection).and_return(stubbed_connection)
      end

      it 'creates via insert' do
        expect(stubbed_connection).to receive(:execute).with(insert_sql + ' RETURNING *')
        object = Traitor.create(:test_active_record_class, param: :foo)
        expect(object.id).to eq 1
      end
    end
  end
end
