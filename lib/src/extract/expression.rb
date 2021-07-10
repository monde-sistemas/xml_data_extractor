# frozen_string_literal: true

module Extract
  class Expression
    def initialize(expression, hash)
      @expression = expression
      @hash = hash
    end

    def evaluate
      keys = Regexp.union(hash.keys.map(&:to_s))
      condition = expression.gsub(keys, hash.stringify_keys)

      eval(condition)
    end

    private

    attr_reader :expression, :hash
  end
end
