module Extract
  class StringValue < Base
    def value
      path = node[:props][:path]
      return formatted_array_values(path) if path.is_a?(Array)

      extract_value(node)
    end

    private

    def extract_value(node_to_extract)
      extractor.extract(node_to_extract)
    end

    def formatted_array_values(paths)
      extractor.format_value(values_from_array(paths), node[:props])
    end

    def values_from_array(paths)
      node_path = node.path

      paths.map do |inner|
        if inner.is_a?(String)
          extract_value(Node.new({ path: inner, link: node[:props][:link] }, node_path))
        else
          StringValue.new(Node.new(inner, node_path), extractor).value
        end
      end
    end
  end
end
