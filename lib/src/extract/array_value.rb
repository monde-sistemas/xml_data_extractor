# frozen_string_literal: true

module Extract
  class ArrayValue < Base
    def value
      props, path = node.to_h.values_at(:props, :path)
      props.map do |prop|
        ValueBuilder.new(Node.new(prop, path), extractor).value
      end.flatten
    end
  end
end
