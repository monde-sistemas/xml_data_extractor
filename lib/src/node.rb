class Node < Struct.new(:props, :path)
  def initialize(*)
    super
    self.path ||= ""
  end

  def first_only?
    return unless props.is_a? Hash

    props[:array_presence] == "first_only"
  end

  def array_of_paths
    array_paths(props[:array_of])
  end

  private

  def array_paths(array_props)
    if array_props.is_a?(Hash)
      array_props.values_at(:path, :link, :uniq_by)
    else
      [array_props].flatten
    end
  end
end
