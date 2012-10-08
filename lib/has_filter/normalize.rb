module HasFilter
  class Normalize
    attr_reader :column, :condition

    def initialize(condition, column)
      @condition, @column = condition, column
    end

    def normalized
      conditions(condition.options)
    end

    def conditions(filtering)
      filtering.inject({})  do |hash, (key, value)|
        key       = key.to_sym
        hash[key] = value(key, value)
        hash
      end
    end

    def value(key, value)
      if column.array? value
        value.collect { |v| normalize_if_boolean(key, v) }
      else
        normalize_if_boolean(key, value)
      end
    end

    def normalize_if_boolean(key, value)
      column.boolean?(key) ? column.to_boolean(value) : value
    end
  end
end
