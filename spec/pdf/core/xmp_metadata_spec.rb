require 'spec_helper'

RSpec.describe PDF::Core::XmpMetadata do
  let(:metadata) { described_class.new }

  describe 'XMP metadata' do
    it 'document information dictionary to XMP conversion' do
      options = {
        Creator: 'Prawn Creator',
        CreationDate: Time.new(2017, 4, 13, 9, 31, 54),
        ModDate: Time.new(2016, 3, 12, 8, 30, 53),
        Producer: 'Prawn Producer',
        Keywords: 'Archived',
        Author: 'John Doe'
      }
      metadata = described_class.new(options)
      expect(metadata.xmp_creator_tool).to eq 'Prawn Creator'
      expect(metadata.xmp_create_date).to eq Time.new(2017, 4, 13, 9, 31, 54)
      expect(metadata.xmp_modify_date).to eq Time.new(2016, 3, 12, 8, 30, 53)
      expect(metadata.pdf_producer).to eq 'Prawn Producer'
      expect(metadata.pdf_keywords).to eq 'Archived'
      expect(metadata.dc_creator).to eq 'John Doe'
    end

    it 'empty metadata' do
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'PDF/A-1b set' do
      metadata.enable_pdfa_1b = true
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:pdfaid=\"http://www.aiim.org/pdfa/ns/id/\" rdf:about=\"\">\n" \
        "    <pdfaid:part>1</pdfaid:part>\n" \
        "    <pdfaid:conformance>B</pdfaid:conformance>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'title set' do
      metadata.dc_title = 'Some title'
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:dc=\"http://purl.org/dc/elements/1.1/\" rdf:about=\"\">\n" \
        "    <dc:title>\n" \
        "      <rdf:Alt>\n" \
        "        <rdf:li xml:lang=\"x-default\">Some title</rdf:li>\n" \
        "      </rdf:Alt>\n" \
        "    </dc:title>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'title set with special characters' do
      metadata.dc_title = 'This is & some< title with speci&al <characters'
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:dc=\"http://purl.org/dc/elements/1.1/\" rdf:about=\"\">\n" \
        "    <dc:title>\n" \
        "      <rdf:Alt>\n" \
        "        <rdf:li xml:lang=\"x-default\">This is &amp; some&lt; title with speci&amp;al &lt;characters</rdf:li>\n" \
        "      </rdf:Alt>\n" \
        "    </dc:title>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'creator set' do
      metadata.dc_creator = 'John Doe'
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:dc=\"http://purl.org/dc/elements/1.1/\" rdf:about=\"\">\n" \
        "    <dc:creator>\n" \
        "      <rdf:Seq>\n" \
        "        <rdf:li>John Doe</rdf:li>\n" \
        "      </rdf:Seq>\n" \
        "    </dc:creator>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'description set' do
      metadata.dc_description = 'Some description'
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:dc=\"http://purl.org/dc/elements/1.1/\" rdf:about=\"\">\n" \
        "    <dc:description>\n" \
        "      <rdf:Alt>\n" \
        "        <rdf:li xml:lang=\"x-default\">Some description</rdf:li>\n" \
        "      </rdf:Alt>\n" \
        "    </dc:description>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'keywords set' do
      metadata.pdf_keywords = 'Testing, PDF/A'
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:pdf=\"http://ns.adobe.com/pdf/1.3/\" rdf:about=\"\">\n" \
        "    <pdf:Keywords>Testing, PDF/A</pdf:Keywords>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'creator tool set' do
      metadata.xmp_creator_tool = 'Prawn'
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\" rdf:about=\"\">\n" \
        "    <xmp:CreatorTool>Prawn</xmp:CreatorTool>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'producer set' do
      metadata.pdf_producer = 'Prawn'
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:pdf=\"http://ns.adobe.com/pdf/1.3/\" rdf:about=\"\">\n" \
        "    <pdf:Producer>Prawn</pdf:Producer>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'create date set' do
      metadata.xmp_create_date = Time.new(2017, 4, 13, 9, 31, 54)
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\" rdf:about=\"\">\n" \
        "    <xmp:CreateDate>2017-04-13T09:31:54</xmp:CreateDate>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'modify date set' do
      metadata.xmp_modify_date = Time.new(2017, 4, 13, 9, 31, 54)
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\" rdf:about=\"\">\n" \
        "    <xmp:ModifyDate>2017-04-13T09:31:54</xmp:ModifyDate>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end

    it 'all information set' do
      metadata.enable_pdfa_1b = true
      metadata.dc_title = 'Some title'
      metadata.dc_creator = 'John Doe'
      metadata.dc_description = 'Some description'
      metadata.pdf_keywords = 'Testing, PDF/A'
      metadata.xmp_creator_tool = 'Prawn'
      metadata.pdf_producer = 'Prawn'
      metadata.xmp_create_date = Time.new(2017, 4, 13, 9, 31, 54)
      metadata.xmp_modify_date = Time.new(2017, 4, 13, 9, 31, 54)
      expect(metadata.render).to eq(
        "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n" \
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n" \
        "  <rdf:Description xmlns:pdfaid=\"http://www.aiim.org/pdfa/ns/id/\" rdf:about=\"\">\n" \
        "    <pdfaid:part>1</pdfaid:part>\n" \
        "    <pdfaid:conformance>B</pdfaid:conformance>\n" \
        "  </rdf:Description>\n" \
        "  <rdf:Description xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\" rdf:about=\"\">\n" \
        "    <xmp:CreatorTool>Prawn</xmp:CreatorTool>\n" \
        "    <xmp:CreateDate>2017-04-13T09:31:54</xmp:CreateDate>\n" \
        "    <xmp:ModifyDate>2017-04-13T09:31:54</xmp:ModifyDate>\n" \
        "  </rdf:Description>\n" \
        "  <rdf:Description xmlns:pdf=\"http://ns.adobe.com/pdf/1.3/\" rdf:about=\"\">\n" \
        "    <pdf:Keywords>Testing, PDF/A</pdf:Keywords>\n" \
        "    <pdf:Producer>Prawn</pdf:Producer>\n" \
        "  </rdf:Description>\n" \
        "  <rdf:Description xmlns:dc=\"http://purl.org/dc/elements/1.1/\" rdf:about=\"\">\n" \
        "    <dc:title>\n" \
        "      <rdf:Alt>\n" \
        "        <rdf:li xml:lang=\"x-default\">Some title</rdf:li>\n" \
        "      </rdf:Alt>\n" \
        "    </dc:title>\n" \
        "    <dc:creator>\n" \
        "      <rdf:Seq>\n" \
        "        <rdf:li>John Doe</rdf:li>\n" \
        "      </rdf:Seq>\n" \
        "    </dc:creator>\n" \
        "    <dc:description>\n" \
        "      <rdf:Alt>\n" \
        "        <rdf:li xml:lang=\"x-default\">Some description</rdf:li>\n" \
        "      </rdf:Alt>\n" \
        "    </dc:description>\n" \
        "  </rdf:Description>\n" \
        "</rdf:RDF>\n" \
        '<?xpacket end="r"?>'
      )
    end
  end
end
