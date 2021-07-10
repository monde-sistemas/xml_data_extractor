# frozen_string_literal: true

require_relative "base"
require_relative "array_value"
require_relative "array_of"
require_relative "hash_builder"
require_relative "string_value"
require_relative "value_builder"
require_relative "within"
require_relative "expression"
require_relative "unescape"

module Extract
  class ValueBuilder < Base
    def value
      props = node.props
      case props
      when String then value_for_string
      when Array then value_for_array
      when Hash then value_for_hash
      else
        raise "Invalid kind #{props.class} (#{props})"
      end
    end

    private

    def value_for_hash
      props = node.props

      Unescape.new(node, extractor).unescape! if props[:unescape]

      fixed_value = props[:fixed]
      return fixed_value if fixed_value
      return ArrayOf.new(node, extractor).value if props[:array_of]
      return Within.new(node, extractor).value if props[:within]
      return StringValue.new(node, extractor).value if (props.keys & %i[path attr]).any?

      HashBuilder.new(node, extractor).value
    end

    def value_for_string
      StringValue.new(Node.new({ path: node.props }, node.path), extractor).value
    end

    def value_for_array
      ArrayValue.new(node, extractor).value
    end
  end
end
