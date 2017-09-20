module PDF
  module Core
    class XmpMetadata
      attr_accessor :enable_pdfa_1b

      # These attributes must all be synchronized with their counterparts in the
      # document information dictionary to be PDF/A-1b compliant.
      attr_accessor :dc_title, :dc_creator, :dc_description,
        :pdf_keywords, :xmp_creator_tool, :pdf_producer,
        :xmp_create_date, :xmp_modify_date

      def initialize(options = {})
        # Convert options for the document information dictionary to their
        # counterparts in XMP.
        @dc_title = options[:Title] if options[:Title]
        @dc_creator = options[:Author] if options[:Author]
        @dc_description = options[:Subject] if options[:Subject]
        @pdf_keywords = options[:Keywords] if options[:Keywords]
        @xmp_creator_tool = options[:Creator] if options[:Creator]
        @pdf_producer = options[:Producer] if options[:Producer]
        @xmp_create_date = options[:CreationDate] if options[:CreationDate]
        @xmp_modify_date = options[:ModDate] if options[:ModDate]
      end

      def render
        result = "<?xpacket begin=\"\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n"
        result << "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n"
        result << render_pdfaid if @enable_pdfa_1b
        result << render_xmp if @xmp_creator_tool || @xmp_create_date || @xmp_modify_date
        result << render_pdf if @pdf_keywords || @pdf_producer
        result << render_dc if @dc_title || @dc_creator || @dc_description
        result << "</rdf:RDF>\n"
        result << '<?xpacket end="r"?>'
      end

      private

      def render_pdfaid
        "  <rdf:Description xmlns:pdfaid=\"http://www.aiim.org/pdfa/ns/id/\" rdf:about=\"\">\n" \
        "    <pdfaid:part>1</pdfaid:part>\n" \
        "    <pdfaid:conformance>B</pdfaid:conformance>\n" \
        "  </rdf:Description>\n"
      end

      def render_xmp
        result = "  <rdf:Description xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\" rdf:about=\"\">\n"
        result << "    <xmp:CreatorTool>#{xml_char_data(@xmp_creator_tool)}</xmp:CreatorTool>\n" if @xmp_creator_tool
        result << "    <xmp:CreateDate>#{xml_char_data(to_xmp_timestamp(@xmp_create_date))}</xmp:CreateDate>\n" if @xmp_create_date
        result << "    <xmp:ModifyDate>#{xml_char_data(to_xmp_timestamp(@xmp_modify_date))}</xmp:ModifyDate>\n" if @xmp_modify_date
        result << "  </rdf:Description>\n"
      end

      def render_pdf
        result = "  <rdf:Description xmlns:pdf=\"http://ns.adobe.com/pdf/1.3/\" rdf:about=\"\">\n"
        result << "    <pdf:Keywords>#{xml_char_data(@pdf_keywords)}</pdf:Keywords>\n" if @pdf_keywords
        result << "    <pdf:Producer>#{xml_char_data(@pdf_producer)}</pdf:Producer>\n" if @pdf_producer
        result << "  </rdf:Description>\n"
      end

      def render_dc
        result = "  <rdf:Description xmlns:dc=\"http://purl.org/dc/elements/1.1/\" rdf:about=\"\">\n"
        if @dc_title
          result << "    <dc:title>\n"
          result << "      <rdf:Alt>\n"
          result << "        <rdf:li xml:lang=\"x-default\">#{xml_char_data(@dc_title)}</rdf:li>\n"
          result << "      </rdf:Alt>\n"
          result << "    </dc:title>\n"
        end
        if @dc_creator
          result << "    <dc:creator>\n"
          result << "      <rdf:Seq>\n"
          result << "        <rdf:li>#{xml_char_data(@dc_creator)}</rdf:li>\n"
          result << "      </rdf:Seq>\n"
          result << "    </dc:creator>\n"
        end
        if @dc_description
          result << "    <dc:description>\n"
          result << "      <rdf:Alt>\n"
          result << "        <rdf:li xml:lang=\"x-default\">#{xml_char_data(@dc_description)}</rdf:li>\n"
          result << "      </rdf:Alt>\n"
          result << "    </dc:description>\n"
        end
        result << "  </rdf:Description>\n" \
      end

      def to_xmp_timestamp(time)
        time.strftime('%Y-%m-%dT%H:%M:%S')
      end

      def xml_char_data(string)
        string.gsub('&', '&amp;').gsub('<', '&lt;')
      end
    end
  end
end
