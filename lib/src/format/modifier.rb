# frozen_string_literal: true

module Format
  class Modifier
    def initialize(yml, helper)
      @debug = yml.fetch(:debug, false)
      @helper = helper
    end

    def apply(raw_value, modifiers)
      [modifiers].flatten.compact.reduce(raw_value) do |value, modifier|
        method_name, params = modifier_props(modifier).values_at(:name, :params)

        modify_value(value, method_name, params)
      end
    end

    private

    attr_reader :helper, :debug

    def modifier_props(modifier)
      modifier.is_a?(String) ? { name: modifier } : modifier
    end

    def modify_value(value, method, params)
      args = [value]
      if params.present?
        args = params.is_a?(Array) ? [value, *params] : [value, **params]
      end

      value.try(method, *params) || helper.send(method, *args)
    rescue StandardError => error
      raise error unless debug

      "Error invoking '#{method}' with (#{args.join(',')}): #{error}"
    end
  end
end
