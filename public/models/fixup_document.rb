class FixupDocument < Nokogiri::XML::SAX::Document
  attr_accessor :file
  def initialize(file)
    @file = file
  end

  def start_document
    @file << '<!DOCTYPE html>'
  end

  def start_element(name, attrs=[])
    @file << '<' << name.sub(/\A.*:/, '')
    unless attrs.empty?
      attrs.each do |name, value|
        @file << " " << name.sub(/\A.*:/, '') << '="' << value.sub('"', '\"') << '"'
      end
    end
    @file << '>'
  end

  def characters(chars)
    @file << chars
  end

  def end_element(name)
    @file << "</" << name.sub(/\A.*:/, '') << '>'
  end

end
