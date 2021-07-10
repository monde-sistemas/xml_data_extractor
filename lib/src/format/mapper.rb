# frozen_string_literal: true

module Format
  class Mapper
    def initialize(yml)
      @mappers = yml.fetch(:mappers, {})
    end

    def apply(raw_value, mapper_name)
      return raw_value unless mapper_name

      mappers.each do |name, fields|
        return mapper_value(fields, raw_value) if mapper_name.to_sym == name
      end

      raise "Mapper not found #{mapper_name}"
    end

    private

    attr_reader :mappers

    def mapper_value(fields, value)
      (fields[:options] || []).each do |option, values|
        return option.to_s if [values].flatten.include?(value.to_s)
      end
      fields[:default] || value
    end
  end
end
