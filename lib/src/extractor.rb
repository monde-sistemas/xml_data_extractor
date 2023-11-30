# frozen_string_literal: true

require "cgi"
require "active_support"
require "active_support/core_ext"
require_relative "format/formatter"

class PathBuilder < Struct.new(:base, :parent, :tag, keyword_init: true)
  def build
    paths = relative_path.split("/").then do |paths|
      if parent.present?
        navigate_to_parent(parent, paths)
      else
        paths
      end
    end

    paths << tag unless tag.is_a? Array
    full_path = paths.flatten.compact.join("/")
    "//#{full_path}"
  end

  private

  def relative_path
    base.start_with?("//") ? base[2..-1] : base
  end

  def navigate_to_parent(parent_tag, paths)
    index = path_index(parent_tag, paths)

    paths[0, index + 1]
  end

  def path_index(tag, paths)
    paths.each_with_index do |path, index|
      return index if matching_tags?(path, tag)
    end
    0
  end

  def matching_tags?(item, tag)
    item.gsub(/\[\d+\]/, "") == tag
  end
end

class NodeParamsExtractor < Struct.new(:node)
  def extract
    [node.path, *node.props.values_at(:in_parent, :path, :link, :attr)]
  end
end

class NodeExtractor
  def initialize(xml)
    @xml = Nokogiri::XML(xml)
    @xml.remove_namespaces!
  end

  def extract(path)
    xml.xpath(path)
  rescue StandardError
    nil
  end

  def unescape!(path)
    node = extract(path)
    return if node.blank?

    first_node = node.first
    return if first_node.elements.present?

    first_node.children = Nokogiri::XML.fragment(first_node.content).children
  end

  private

  attr_reader :xml
end

class NodeValueExtractor
  def initialize(node_extractor)
    @node_extractor = node_extractor
  end

  def attr_values(path, attributes)
    return attributes.map { |atr| attr_value(path, atr) } if attributes.is_a? Array
    return tag_count(path) if attributes == :tag_count

    attr_value(path, attributes)
  end

  def tag_count(path)
    node_extractor.extract(path).size
  end

  def tag_values(base_path, paths)
    return tag_value(base_path) unless paths.is_a? Array

    paths.map { |path| tag_value([base_path, path].flatten.compact.join("/")) }
  end

  private

  attr_reader :node_extractor

  def tag_value(path)
    node_raw_value node_extractor.extract(path)
  end

  def attr_value(path, att)
    node_raw_value node_extractor.extract(path).attribute(att)
  end

  def node_raw_value(node)
    NodeValue.new(node).raw_value
  end
end

class NodeValue
  def initialize(node)
    @node = node
  end

  def raw_value
    return "" unless node

    node_size = node.try(:size).to_i
    return node.map(&:text) if node_size > 1
    return node.first if node_size == 1 && contains_children?

    node.text
  end

  private

  attr_reader :node

  def contains_children?
    node.first.try(:children).any? { |child| child.is_a? Nokogiri::XML::Element }
  end
end

class PathManipulator
  def initialize(node_value_extractor)
    @node_value_extractor = node_value_extractor
  end

  def replace_link(original_path, link_path)
    return original_path if link_path.blank?

    link_value = node_value_extractor.tag_values(link_path, nil)

    original_path.gsub "<link>", link_value
  end

  def uniq_paths(paths, uniq_by_path)
    paths
      .map { |path| { path: path, value: tag_value(path, uniq_by_path) } }
      .then { |paths_values| remove_duplicated_paths(paths_values) }
      .map { |path_value| path_value[:path] }
  end

  private

  attr_reader :node_value_extractor

  def tag_value(path, uniq_by_path)
    node_value_extractor.tag_values([path, uniq_by_path].join("/"), "")
  end

  def remove_duplicated_paths(paths_values)
    paths_values.delete_if.with_index do |path_value, index|
      index != first_path_value_index(paths_values, path_value)
    end
  end

  def first_path_value_index(paths_values, current_path)
    paths_values.find_index { |path_value| path_value[:value] == current_path[:value] }
  end
end

class Extractor
  def initialize(xml, yml, modifiers)
    @node_extractor = NodeExtractor.new(xml)
    @node_value_extractor = NodeValueExtractor.new(node_extractor)
    @path_manipulator = PathManipulator.new(node_value_extractor)
    @formatter = Format::Formatter.new(yml, modifiers)
  end

  def extract(node)
    base, parent, tag, link, attribute = NodeParamsExtractor.new(node).extract
    path = PathBuilder.new(base: base, parent: parent, tag: tag).build

    if link.present?
      link_path = PathBuilder.new(base: base, parent: parent, tag: link).build

      if tag.is_a? Array
        tag = tag.map { |tag_path| replace_link(tag_path, link_path) }
      else
        path = replace_link(path, link_path)
      end
    end

    value = path_value(path, tag, attribute)
    format_value(value, node.props)
  end

  def unescape!(path)
    node_extractor.unescape!(path)
  end

  def format_value(value, props)
    formatter.format_value(value, props)
  end

  def replace_link(original_path, link_path)
    path_manipulator.replace_link(original_path, link_path)
  end

  def paths_of(base_path, tag_path, link_path = nil)
    path = PathBuilder.new(base: base_path, tag: tag_path).build

    if link_path.present?
      link_path = PathBuilder.new(base: base_path, tag: link_path).build
      path = replace_link(path, link_path)
    end

    node = node_extractor.extract(path)
    (node || []).size.times.map do |index|
      "#{path}[#{index + 1}]"
    end
  end

  def uniq_paths(paths, uniq_by_path)
    return paths if uniq_by_path.blank?

    path_manipulator.uniq_paths(paths, uniq_by_path)
  end

  private

  attr_reader :node_extractor, :node_value_extractor, :path_manipulator, :formatter

  def path_value(path, tag, attribute)
    return node_value_extractor.attr_values(path, attribute) if attribute.present?

    node_value_extractor.tag_values(path, tag)
  end
end
