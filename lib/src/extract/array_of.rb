# frozen_string_literal: true

module Extract
  class ArrayOf < Base
    def initialize(node, extractor, index = 0)
      super(node, extractor)
      @index = index
    end

    def value
      process_paths.flatten.compact
    end

    private

    attr_reader :index

    def array_items
      arr_path, link_path, uniq_by = node.array_of_paths

      paths = extractor.paths_of(node.path, arr_path, link_path)
      paths = uniq_paths(paths, uniq_by) if uniq_by

      paths.each_with_index.map do |path, idx|
        HashBuilder.new(Node.new(node.props, path), extractor).value(index + idx)
      end.compact
    end

    def process_paths
      paths = paths_from_props

      if paths.size > 1
        process_path(paths.shift, paths)
      else
        node.props[:array_of] = paths.first
        array_items
      end
    end

    def process_path(path, inner_paths)
      path = build_path(path) if path.is_a?(Hash)

      extractor.paths_of(node.path, path).each_with_index.map do |some, idx|
        ArrayOf.new(Node.new(node.props.merge(array_of: inner_paths), some), extractor, index + idx).value
      end
    end

    def uniq_paths(paths, uniq_by)
      extractor.uniq_paths(paths, uniq_by)
    end

    def build_path(hash)
      extractor.replace_link(hash[:path], [node.path, hash[:link]].join("/"))
    end

    def paths_from_props
      [node.props[:array_of]].flatten
    end
  end
end
