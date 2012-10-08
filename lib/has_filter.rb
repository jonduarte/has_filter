require 'has_filter/column'
require 'has_filter/conditions'
require 'has_filter/normalize'

module HasFilter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_filter(allowed_fields = nil)
      @_filters = *allowed_fields
    end

    def filter(filtering = nil)
      @column     = Column.new(column_names, self.columns_hash)
      conditions = Conditions.new(filtering, @column, @_filters)
      return [] if conditions.missing?
      conditions = Normalize.new(conditions, @column).normalized

      self.instance_eval <<-SCOPE, __FILE__, __LINE__ + 1
        scope :dynamic_has_filter, :conditions => #{set_filters(conditions)}
      SCOPE

      dynamic_has_filter
    end

    private
    def set_filters(conditions)
      filters = []
      conditions.each { |key, value| filters << hash_conditions(key, value) }
      [filters.join(" AND "), likefy(conditions)]
    end

    def likefy(conditions)
      conditions.each { |key, value| conditions[key] = "%#{value}%" if @column.string?(key) }
    end

    def hash_conditions(key, value = nil)
      type =
        if @column.string? key
          if @column.array? value
            :in
          else
            :like
          end
        elsif @column.array? value
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

      [types[kind] % [key, key]]
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
