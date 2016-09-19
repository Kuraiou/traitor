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
        # make sure we stub timestamps to avoid constraints, as those are typically "not null"
        # handle both rails and ruby
        time_method = Time.respond_to?(:current) ? Time.method(:current) : Time.method(:now)
        self.created_at ||= time_method.call if self.respond_to?(:created_at)
        self.updated_at ||= time_method.call if self.respond_to?(:updated_at)

        insert_sql = self.class.arel_table.create_insert.tap do |im|
          im.insert(self.send(:arel_attributes_with_values_for_create, self.attribute_names))
        end.to_sql

        # return and assign everything to gather values created/modified by db triggers
        result = self.class.connection.execute(insert_sql + " RETURNING *")

        # reassign the write values back to the object, in case there are DB triggers.
        result.to_a.first.each do |column_name, serialized_value|
          column = self.column_for_attribute(column_name)
          deserialized_value = column.type_cast_from_database(serialized_value)
          self["#{column_name}"] = deserialized_value
        end

        # mark the instance as having been saved.
        self.instance_variable_set(:@new_record, false)
        self.clear_changes_information
      end
    end
  end
end

ActiveRecord::Base.send :include, Traitor::Helpers::ActiveRecord
