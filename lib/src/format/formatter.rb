require_relative "mapper"
require_relative "modifier"

module Format
  class Formatter
    def initialize(yml, modifiers)
      @mapper = Format::Mapper.new(yml)
      @modifier = Format::Modifier.new(yml, modifiers)
    end

    def format_value(value, props)
      modifier_prop, mapper_prop = props.values_at(:modifier, :mapper)

      value
        .then { |it| modifier.apply(it, modifier_prop) }
        .then { |it| nullify_empty_value(it) }
        .then { |it| mapper.apply(it, mapper_prop) }
    end

    private

    attr_reader :modifier, :mapper

    def nullify_empty_value(value)
      value.blank? || value.try(:zero?) ? nil : value
    end
  end
end
