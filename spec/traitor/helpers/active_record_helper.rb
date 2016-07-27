require 'spec_helper'

class TestActiveRecordClass < ActiveRecord::Base
end

RSpec.configure do |config|

  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(
      adapter:  'sqlite3',
      database: File.join(File.dirname(__FILE__), 'test.db')
    )

    begin
      ActiveRecord::Base.connection.create_table(TestActiveRecordClass.table_name) do |tbl|
        tbl.column :param, :text
      end
    rescue
      # we probably created it and crashed/exited.
    end

    example.run

    ActiveRecord::Base.connection.drop_table(TestActiveRecordClass.table_name)
  end
end
