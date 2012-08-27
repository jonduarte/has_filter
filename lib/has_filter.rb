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
      all(:conditions => set_filters(conditions), :limit => limit)
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

    def set_filters(conditions)
      filters = []
      conditions.each { |key, value| filters << _hash_conditions(key, value) }
      [filters.join(" AND "), likefy(conditions)].flatten
    end

    def likefy(conditions)
      conditions.each { |key, value| conditions[key] = "%#{value}%" if !array?(value) && string?(key) }
    end

    def _hash_conditions(key, value = nil)
      if string? key
        if array? value
          _join_conditions(key, :in)
        else
          _join_conditions(key, :like)
        end
      elsif array? value
        _join_conditions(key, :in)
      else
        _join_conditions(key, :eq)
      end
    end

    def _join_conditions(key, kind)
      types = { :in => "%s in (:%s)", :like => "%s like :%s", :eq => "%s = :%s" }
      [types[kind] % [key.to_s, key.to_s]]
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
