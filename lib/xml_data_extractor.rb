require "nokogiri"
require_relative "src/extractor"
require_relative "src/node"
require_relative "src/extract/value_builder"

class XmlDataExtractor   
  def initialize(config, modifiers = nil)
    @config = config      
    @modifiers = modifiers
  end

  def parse(xml)
    extractor = Extractor.new(xml, config, modifiers)
    schemas = config.fetch(:schemas, {})

    {}.tap do |hash|
      schemas.map do |key, val|
        value = Extract::ValueBuilder.new(Node.new(val), extractor).value
        hash[key] = value if value.present?
      end
    end      
  end

  private

  attr_reader :config, :modifiers
end
