require 'nokogiri'

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
        @xml_doc = Nokogiri::XML(
          "<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'/>"
        )

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
        render_pdfaid if @enable_pdfa_1b
        render_xmp if @xmp_creator_tool || @xmp_create_date || @xmp_modify_date
        render_pdf if @pdf_keywords || @pdf_producer
        render_dc if @dc_title || @dc_creator || @dc_description
        @xml_doc.root.to_xml
      end

      private

      def render_pdfaid
        description_node = @xml_doc.root.add_child(
          "<rdf:Description rdf:about='' xmlns:pdfaid='http://www.aiim.org/pdfa/ns/id/'/>"
        ).first
        part_node = description_node.add_child('<pdfaid:part/>').first
        part_node.content = '1'
        conformance_node = description_node.add_child('<pdfaid:conformance/>').first
        conformance_node.content = 'B'
      end

      def render_xmp
        description_node = @xml_doc.root.add_child(
          "<rdf:Description rdf:about='' xmlns:xmp='http://ns.adobe.com/xap/1.0/'/>"
        ).first
        if @xmp_creator_tool
          node = description_node.add_child('<xmp:CreatorTool/>').first
          node.content = @xmp_creator_tool
        end
        if @xmp_create_date
          node = description_node.add_child('<xmp:CreateDate/>').first
          node.content = to_xmp_timestamp @xmp_create_date
        end
        if @xmp_modify_date
          node = description_node.add_child('<xmp:ModifyDate/>').first
          node.content = to_xmp_timestamp @xmp_modify_date
        end
      end

      def render_pdf
        description_node = @xml_doc.root.add_child(
          "<rdf:Description rdf:about='' xmlns:pdf='http://ns.adobe.com/pdf/1.3/'/>"
        ).first
        if @pdf_keywords
          node = description_node.add_child('<pdf:Keywords/>').first
          node.content = @pdf_keywords
        end
        if @pdf_producer
          node = description_node.add_child('<pdf:Producer/>').first
          node.content = @pdf_producer
        end
      end

      def render_dc
        description_node = @xml_doc.root.add_child(
          "<rdf:Description rdf:about='' xmlns:dc='http://purl.org/dc/elements/1.1/'/>"
        ).first
        if @dc_title
          title_node = description_node.add_child('<dc:title/>').first
          alt_node = title_node.add_child('<rdf:Alt/>').first
          li_node = alt_node.add_child('<rdf:li/>').first
          li_node['xml:lang'] = 'x-default'
          li_node.content = @dc_title
        end
        if @dc_creator
          creator_node = description_node.add_child('<dc:creator/>').first
          seq_node = creator_node.add_child('<rdf:Seq/>').first
          li_node = seq_node.add_child('<rdf:li/>').first
          li_node.content = @dc_creator
        end
        if @dc_description
          description_node = description_node.add_child('<dc:description/>').first
          alt_node = description_node.add_child('<rdf:Alt/>').first
          li_node = alt_node.add_child('<rdf:li/>').first
          li_node['xml:lang'] = 'x-default'
          li_node.content = @dc_description
        end
      end

      def to_xmp_timestamp(time)
        time.strftime('%Y-%m-%dT%H:%M:%S')
      end
    end
  end
end
