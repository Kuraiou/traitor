# note that we do not have activerecord as a dependency in this gem!
# do not `require 'traitor/helpers/active_record'` unless you have ActiveRecord
# in your gemfile

require 'active_record'

module Traitor
  module Helpers
    module ActiveRecord
      def create_without_callbacks
        case self.class.connection.class.name
        when 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
          create_without_callbacks_pg
        when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
          create_without_callbacks_sqlite
        else
          create_without_callbacks_default
        end
      end

      private

      def create_without_callbacks_default
        insert_sql = self.class.arel_table.create_insert.tap do |im|
          im.insert(self.send(:arel_attributes_with_values_for_create, self.attribute_names))
        end.to_sql

        pk = self.class.primary_key
        self.class.connection.execute(insert_sql)
        id = self.maximum(pk)
        self.send(:"#{pk}=", id)
        self.clear_changes_information
      end

      def create_without_callbacks_sqlite
        insert_sql = self.class.arel_table.create_insert.tap do |im|
          im.insert(self.send(:arel_attributes_with_values_for_create, self.attribute_names))
        end.to_sql

        conn = self.class.connection
        conn.execute(insert_sql)

        pk = self.class.primary_key
        id = conn.execute("SELECT last_insert_rowid() AS id")[0]['id']
        self.send(:"#{pk}=", id)
        self.clear_changes_information
      end

      def create_without_callbacks_pg
        insert_sql = self.class.arel_table.create_insert.tap do |im|
          im.insert(self.send(:arel_attributes_with_values_for_create, self.attribute_names))
        end.to_sql

        pk = self.class.primary_key
        id = self.class.connection.execute(insert_sql + " RETURNING #{pk}")[0][pk]
        self.send(:"#{pk}=", id)
        self.clear_changes_information
      end
    end
  end
end

ActiveRecord::Base.send :include, Traitor::Helpers::ActiveRecord
