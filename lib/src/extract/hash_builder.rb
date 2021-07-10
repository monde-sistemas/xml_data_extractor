# frozen_string_literal: true

module Extract
  class HashBuilder < Base
    INTERNAL_FIELDS = %i[array_of keep_if within unescape].freeze

    def value(index = 0)
      path, props = node.to_h.values_at(:path, :props)

      hash = {}
      props.each do |field_name, nested_props|
        next unless valuable_field? field_name, nested_props, index

        value = ValueBuilder.new(Node.new(nested_props, path), extractor).value
        hash[field_name.to_sym] = value if value.present?
      end

      keep_hash?(hash, props) ? hash : nil
    end

    private

    def keep_hash?(hash, props)
      expression = props[:keep_if]
      expression.present? ? Expression.new(expression, hash).evaluate : true
    end

    def valuable_field?(field_name, props, index)
      return false if INTERNAL_FIELDS.include? field_name
      return false if index.positive? && Node.new(props, "").first_only?

      true
    end
  end
end
