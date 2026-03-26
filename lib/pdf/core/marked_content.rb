# frozen_string_literal: true

module PDF
  module Core
    # Provides methods for emitting marked content operators (BMC/BDC/EMC)
    # in PDF content streams. These operators associate content with structure
    # elements for accessibility (tagged PDF).
    #
    # @api private
    module MarkedContent
      # Begin a marked content sequence with no properties.
      #
      # @param tag [Symbol] structure type tag (e.g., :P, :Span, :Artifact)
      # @return [void]
      def begin_marked_content(tag)
        add_content("/#{tag} BMC")
      end

      # Begin a marked content sequence with properties (BDC operator).
      #
      # @param tag [Symbol] structure type tag
      # @param properties [Hash] properties dict (typically includes :MCID)
      # @return [void]
      def begin_marked_content_with_properties(tag, properties = {})
        props = PDF::Core.pdf_object(properties, true)
        add_content("/#{tag} #{props} BDC")
      end

      # End a marked content sequence.
      #
      # @return [void]
      def end_marked_content
        add_content('EMC')
      end

      # Wrap a block in a marked content sequence (BMC/EMC).
      #
      # @param tag [Symbol] structure type tag
      # @yield content to wrap
      # @return [void]
      def marked_content_sequence(tag)
        begin_marked_content(tag)
        yield if block_given?
        end_marked_content
      end

      # Wrap a block in a marked content sequence with properties (BDC/EMC).
      #
      # @param tag [Symbol] structure type tag
      # @param properties [Hash] properties dict
      # @yield content to wrap
      # @return [void]
      def marked_content_sequence_with_properties(tag, properties = {})
        begin_marked_content_with_properties(tag, properties)
        yield if block_given?
        end_marked_content
      end
    end
  end
end
