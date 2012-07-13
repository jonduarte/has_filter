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

      conditions.select! { |key, value| self.column_names.include? key.to_s }
      conditions.select! { |key, value| @_filters.include? key              } if @_filters.present?
      conditions.reject! { |key, value| value && value.blank?               }

      if conditions.empty?
        filters << _hash_conditions(:id)
      else
        filters << _set_filters(conditions)
      end

      find(:all, :conditions => filters.flatten)
    end

    private

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

    def _column_type(column)
      self.columns_hash[column.to_s].type
    end

    def _to_bool(value)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end

    def _bind_conditions(conditions)
      conditions.inject({}) do |hash, (key, value)|
        key = key.to_sym

        if !value.is_a?(Array) && _column_type(key) == :string
          hash[key] = "%#{value}%"
        elsif value.is_a?(Array)
          value.reject! { |a| a.to_s.blank? }
          value.collect! do |v|
            if _column_type(key) == :boolean
              v = _to_bool(v)
            else
              v
            end
          end
          hash[key] = value
        else
          if _column_type(key) == :boolean
            value = _to_bool(value)
          end
          hash[key] = value
        end
        hash
      end
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
