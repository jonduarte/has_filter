require 'active_record'

module HasFilter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_filter(allowed_fields = nil)
      @allowed_fields = *allowed_fields
    end

    def filtering(conditions)
      filters = []
      if @allowed_fields.present?
        conditions = conditions.select { |key| @allowed_fields.include? key }
        if conditions.empty?
          filters << hash_conditions(:id, nil)
        end
        conditions.each do |key, value|
          next if value.nil?
          if self.columns_hash[key.to_s].type == :string
            filters << like_conditions(key, value)
          else
            filters << hash_conditions(key, value)
          end
        end
      else
        conditions.each do |key, value|
          next if value.nil?
          if self.columns_hash[key.to_s].type == :string
            filters << like_conditions(key, value)
          else
            filters << hash_conditions(key, value)
          end
        end
      end
      find(:all, *filters)
    end

    private

    def hash_conditions(key, value)
      { :conditions => { key => value } }
    end

    def like_conditions(key, value)
      { :conditions => ["#{key.to_s} like ?", "%#{value}%"] }
    end
  end
end

ActiveRecord::Base.send(:include, HasFilter)
