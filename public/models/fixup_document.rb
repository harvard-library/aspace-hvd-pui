class FixupDocument < Nokogiri::XML::SAX::Document
  attr_accessor :file
  def initialize(file)
    @file = file
  end

  def start_element_namespace(name, attrs=[], prefix=nil, uri=nil, ns=[])
    @file << '<#{name}'
    unless attrs.empty?
      attrs.each do |attr|
        @file << " #{attr.localname}=\"#{attr.value.sub('"', '\"')}\""
      end
    end
    @file << '>'
  end

  def characters(chars)
    chars.gsub!(/&(?=\s+|[A-Za-z]+[^;])/, '&amp;')
    @file << chars
  end

  def end_element_namespace(name, prefix= nil, uri=nil)
    @file << "</" << name << '>'
  end

end
