require 'active_record'

module HasFilter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_filter(allowed_fields = nil)
      @_filters = *allowed_fields
    end

    def filter(filtering = nil)
      return [] unless filtering
      conditions = filtering
      filters = []

      conditions = _normalize_conditions(conditions)

      if conditions.empty?
        filters << _hash_conditions(:id)
      else
        filters << _set_filters(conditions)
      end

      find(:all, :conditions => filters.flatten)
    end

    private


    def _set_filters(conditions)
      filters = []

      conditions.each do |key, value|
        next if value.nil?
        if _column_type(key) == :string
          filters << _like_conditions(key, value)
        else
          filters << _hash_conditions(key, value)
        end
      end

      [filters.join(" AND "), _bind_conditions(conditions)]
    end

    def _hash_conditions(key, value = nil)
      return _join_condition(key, :in) if value.is_a? Array
      _join_condition(key, :eq)
    end

    def _like_conditions(key, value)
      return  _join_condition(key, :in) if value.is_a? Array
      _join_condition(key, :like)
    end

    def _join_condition(key, kind)
      types = { :in => "%s in (:%s)", :like => "%s like :%s", :eq => "%s = :%s" }
      [types[kind] % [key.to_s, key.to_s]]
    end

    def _column_type(column)
      self.columns_hash[column.to_s].type
    end

    def _to_bool(value)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end

    def _normalize_column(key, value)
      return _to_bool(value) if _column_type(key.to_s) == :boolean
      value
    end

    def _normalize_conditions(filtering)
      conditions = filtering
      conditions.select! { |k, v| self.column_names.include? k.to_s }
      conditions.select! { |k, v| @_filters.include? k              } if @_filters.present?
      conditions.reject! { |k, v| v && v.blank? || v.nil?           }

      conditions.inject({})  do |hash, (key, value)|
        key = key.to_sym

        if value.is_a? Array
          value.reject!  { |a| a.to_s.blank?             }
          value.collect! { |v| _normalize_column(key, v) }
          hash[key] = value
        else
          hash[key] = _normalize_column(key, value)
        end

        hash
      end
    end

    def _bind_conditions(conditions)
      conditions.each do |key, value|
        if !value.is_a?(Array) && _column_type(key) == :string
          conditions[key] = "%#{value}%"
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
