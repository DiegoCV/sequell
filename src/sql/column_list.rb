require 'sql/column'

module Sql
  class ColumnList
    def initialize(config, column_list, column_alias_map)
      @config = config
      @column_list = column_list || []
      @columns = @column_list.map { |column_config|
        Sql::Column.new(config, column_config, column_alias_map)
      }
      @foreign_key_columns = @columns.find_all { |c| c.reference? }.map { |rf|
        Sql::Column.new(@config, "#{rf.fk_name}I", nil)
      }

      add_derived_columns
    end

    def columns
      @columns
    end

    def [](column_name)
      column_map[column_name] || fk_column_map[column_name]
    end

    def type(field_name)
      field = self[field_name]
      field && field.type
    end

  private

    def column_map
      @column_map ||= Hash[ @columns.map { |c| [c.name, c] } ]
    end

    def fk_column_map
      @fk_column_map ||= Hash[ @foreign_key_columns.map { |c| [c.name, c] } ]
    end

    def add_derived_columns
      all_lookup_tables.each { |table|
        table.generated_columns.each { |col|
          @columns << col
        }
      }
    end

    def all_lookup_tables
      lookup_tables = []
      @columns.find_all { |c| c.reference? }.each { |c|
        table = c.lookup_table
        lookup_tables << table unless lookup_tables.include?(table)
      }
      lookup_tables
    end
  end
end
