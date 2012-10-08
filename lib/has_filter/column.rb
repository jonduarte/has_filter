module HasFilter
  class Column
    attr_reader :column_names, :column_types

    def initialize(column_names, column_types)
      @column_names, @column_types = column_names, column_types
    end

    def names
      column_names
    end

    def type(column)
      column_types[column.to_s].type
    end

    def boolean?(key)
      type(key.to_s) == :boolean
    end

    def string?(key)
      type(key) == :string
    end

    def array?(value)
      value.is_a? Array
    end

    def to_boolean(value)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end
  end
end
