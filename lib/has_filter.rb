module HasFilter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_filter(allowed_fields = nil)
      @_filters = *allowed_fields
    end

    def filter(filtering = nil)
      conditions = valid_columns(filtering)
      if @_filters.present?
        conditions = valid_filters(conditions)
        return [] if conditions.empty?
      end
      conditions = normalize_conditions(conditions)

      self.instance_eval <<-SCOPE, __FILE__, __LINE__ + 1
        scope :dynamic_has_filter, :conditions => #{set_filters(conditions)}
      SCOPE

      dynamic_has_filter
    end

    private

    def valid_columns(conditions)
      conditions.reject { |k, v| invalid?(v) || !column_names.include?(k.to_s) }
    end

    def invalid?(value)
      value.blank? || value.nil?
    end

    def valid_filters(conditions)
      conditions.select { |k, v| @_filters.include? k }
    end

    def set_filters(conditions)
      filters = []
      conditions.each { |key, value| filters << hash_conditions(key, value) }
      [filters.join(" AND "), likefy(conditions)]
    end

    def likefy(conditions)
      conditions.each { |key, value| conditions[key] = "%#{value}%" if string?(key) }
    end

    def hash_conditions(key, value = nil)
      type =
        if string? key
          if array? value
            :in
          else
            :like
          end
        elsif array? value
          :in
        else
          :eq
        end

      join_conditions(key, type)
    end

    def join_conditions(key, kind)
      types = {
        :in   => "%s in (:%s)",
        :like => "%s like :%s",
        :eq   => "%s = :%s"
      }

      [types[kind] % [key.to_s, key.to_s]]
    end


    def normalize_conditions(filtering)
      filtering.inject({})  do |hash, (key, value)|
        key       = key.to_sym
        hash[key] = normalize_value(key, value)
        hash
      end
    end

    def normalize_value(key, value)
      if array? value
        value.collect { |v| normalize_if_boolean(key, v) }
      else
        normalize_if_boolean(key, value)
      end
    end

    def column_type(column)
      self.columns_hash[column.to_s].type
    end

    def to_boolean(value)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end

    def normalize_if_boolean(key, value)
      boolean?(key) ? to_boolean(value) : value
    end

    def boolean?(key)
      column_type(key.to_s) == :boolean
    end

    def string?(key)
      column_type(key) == :string
    end

    def array?(value)
      value.is_a? Array
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
