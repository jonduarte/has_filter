require 'active_record'

module HasFilter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_filter(allowed_fields = nil)
      @allowed_fields = *allowed_fields
    end

    def filtering(filtering)
      conditions = filtering
      filters = []

      if @allowed_fields.present?
        conditions = conditions.select { |key| @allowed_fields.include? key }
      end

      if conditions.empty?
        filters << hash_conditions(:id, nil)
      else
        filters << set_filters(conditions)
      end

      filters = filters.flatten
      find(:all, :conditions => filters)
    end

    private

    def hash_conditions(key, value)
      if value.is_a? Array
        ["#{key.to_s} in (:#{key.to_s})"]
      else
        ["#{key.to_s} = :#{key.to_s}"]
      end
    end

    def like_conditions(key, value)
      if value.is_a? Array
        ["#{key.to_s} in (:#{key.to_s})"]
      else
        ["#{key.to_s} like :#{key.to_s}"]
      end
    end

    def set_filters(filtering)
      conditions = filtering
      filters = []

      conditions.reject! { |k, v| v.nil? }

      conditions.each do |key, value|
        next if value.nil?
        if self.columns_hash[key.to_s].type == :string
          filters << like_conditions(key, value)
        else
          filters << hash_conditions(key, value)
        end
      end

      conditions = conditions.inject({}) do |h, (k, v)|
        if !h[k].is_a?(Array) && self.columns_hash[k.to_s].type == :string
          h[k] = "%#{v}%"
        else
          h[k] = v
        end
        h
      end

      [filters.join(" AND "), conditions]
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
