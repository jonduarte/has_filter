module HasFilter
  class Conditions
    attr_reader :options, :filters, :columns
    def initialize(options, columns, filters = [])
      @columns = columns
      @options, @filters = options, filters
      update_options
    end

    def update_options
      valid_columns
      options.replace(valid_filters) if filters.present?
    end

    def valid_columns
      options.reject! { |key, value| invalid?(value) || !columns.names.include?(key.to_s) }
    end

    def valid_filters
      options.select { |key, _| filters.include?(key) }
    end

    def invalid?(value)
      value.blank? || value.nil?
    end

    def missing?
      !options.present?
    end
  end
end
