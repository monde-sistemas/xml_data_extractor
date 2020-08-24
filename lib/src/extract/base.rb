module Extract
  class Base
    def initialize(node, extractor)
      @node = node
      @extractor = extractor
    end

    private

    attr_reader :node, :extractor
  end
end
