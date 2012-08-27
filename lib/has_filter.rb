module HasFilter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_filter(allowed_fields = nil)
      @_filters = *allowed_fields
    end

    def filter(filtering = nil, limit = 100)
      conditions = _normalize(filtering)
      if @_filters.present?
        conditions = _valid_filters(conditions)
        return [] if conditions.empty?
      end

      conditions = _normalize_conditions(conditions)
      all(:conditions => _set_filters(conditions).flatten, :limit => limit)
    end

    private


    def _normalize(conditions)
      conditions.
        select { |k, v| self.column_names.include? k.to_s }.
        reject { |k, v| invalid?(v)                       }
    end

    def invalid?(value)
      value.blank? || value.nil?
    end

    def _valid_filters(conditions)
      conditions.select { |k, v| @_filters.include? k }
    end

    def _set_filters(conditions)
      filters = []

      conditions.each do |key, value|
        next if value.nil?
        if string?(key)
          filters << _like_conditions(key, value)
        else
          filters << _hash_conditions(key, value)
        end
      end

      [filters.join(" AND "), _bind_conditions(conditions)]
    end

    def _hash_conditions(key, value = nil)
      return _join_condition(key, :in) if array?(value)
      _join_condition(key, :eq)
    end

    def _like_conditions(key, value)
      return  _join_condition(key, :in) if array?(value)
      _join_condition(key, :like)
    end

    def _join_condition(key, kind)
      types = { :in => "%s in (:%s)", :like => "%s like :%s", :eq => "%s = :%s" }
      [types[kind] % [key.to_s, key.to_s]]
    end

    def _bind_conditions(conditions)
      conditions.each do |key, value|
        if !array?(value) && string?(key)
          conditions[key] = "%#{value}%"
        end
      end
    end

    def _normalize_conditions(filtering)
      filtering.inject({})  do |hash, (key, value)|
        key   = key.to_sym
        value = _normalize_column(key, value) unless array?(value)
        value.collect! { |v| _normalize_column(key, v) } if array?(value)
        hash[key] = value
        hash
      end
    end

    def _column_type(column)
      self.columns_hash[column.to_s].type
    end

    def _to_bool(value)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end

    def _normalize_column(key, value)
      boolean?(key) ? _to_bool(value) : value
    end

    def boolean?(key)
      _column_type(key.to_s) == :boolean
    end

    def string?(key)
      _column_type(key) == :string
    end

    def array?(value)
      value.is_a? Array
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
