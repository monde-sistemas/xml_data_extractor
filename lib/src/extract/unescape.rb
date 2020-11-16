module Extract
  class Unescape < Base
    def unescape!
      unescape_tag = node.props[:unescape]

      paths_to_unescape = extractor.paths_of(node.path, unescape_tag)
      return if paths_to_unescape.empty?

      paths_to_unescape.each { |path| extractor.unescape!(path) }
    end
  end
end
