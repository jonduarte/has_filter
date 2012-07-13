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
        if self.columns_hash[key.to_s].type == :string
          filters << _like_conditions(key, value)
        else
          filters << _hash_conditions(key, value)
        end
      end

      [filters.join(" AND "), _bind_conditions(conditions)]
    end

    def _bind_conditions(conditions)
      conditions.inject({}) do |hash, (key, value)|
        if !value.is_a?(Array) && self.columns_hash[key.to_s].type == :string
          hash[key.to_sym] = "%#{value}%"
        elsif value.is_a?(Array)
          hash[key.to_sym] = value.delete_if { |a| a.to_s.blank? }
        else
          hash[key.to_sym] = value
        end
        hash
      end
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
