# frozen_string_literal: true

module Extract
  class Within < Base
    def value
      props = node.props
      paths = extractor.paths_of(node.path, props[:within])
      return "" if paths.empty?

      HashBuilder.new(Node.new(props, paths.first), extractor).value
    end
  end
end
