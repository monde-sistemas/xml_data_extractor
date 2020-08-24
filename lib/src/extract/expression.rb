module Extract
  class Expression
    def initialize(expression, hash)
      @expression = expression
      @hash = hash
    end

    def evaluate
      field_name = expression.split.first.parameterize
      field_value = hash[field_name.to_sym]
      condition = expression.gsub(field_name, field_value.to_s)

      eval(condition)
    end

    private

    attr_reader :expression, :hash
  end
end
