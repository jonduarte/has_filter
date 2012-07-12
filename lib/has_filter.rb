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

      conditions = conditions.select { |k, v| self.column_names.include? k.to_s }

      if @_filters.present?
        conditions = conditions.select { |key| @_filters.include? key }
      end

      if conditions.empty?
        filters << _hash_conditions(:id, nil)
      else
        filters << _set_filters(conditions)
      end

      filters = filters.flatten
      find(:all, :conditions => filters)
    end

    private

    def _hash_conditions(key, value)
      if value.is_a? Array
        ["#{key.to_s} in (:#{key.to_s})"]
      else
        ["#{key.to_s} = :#{key.to_s}"]
      end
    end

    def _like_conditions(key, value)
      if value.is_a? Array
        ["#{key.to_s} in (:#{key.to_s})"]
      else
        ["#{key.to_s} like :#{key.to_s}"]
      end
    end

    def _set_filters(filtering)
      filters = []
      conditions = filtering
      conditions.reject! { |k, v| v.nil? }

      conditions.each do |key, value|
        next if value.nil?
        if self.columns_hash[key.to_s].type == :string
          filters << _like_conditions(key, value)
        else
          filters << _hash_conditions(key, value)
        end
      end

      conditions = conditions.inject({}) do |hash, (key, value)|
        if !value.is_a?(Array) && self.columns_hash[key.to_s].type == :string
          hash[key.to_sym] = "%#{value}%"
        elsif value.is_a?(Array)
          hash[key.to_sym] = value.delete_if { |a| a.to_s.blank? }
        else
          hash[key.to_sym] = value
        end
        hash
      end

      [filters.join(" AND "), conditions]
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
