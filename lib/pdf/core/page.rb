# encoding: utf-8

# prawn/core/page.rb : Implements low-level representation of a PDF page
#
# Copyright February 2010, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#

require_relative 'graphics_state'

module PDF
  module Core
    class Page #:nodoc:
      attr_accessor :document, :margins, :bleeds, :stack
      attr_writer :content, :dictionary

      def initialize(document, options={})
        @document = document
        @margins  = options[:margins] || { :left   => 36,
                                           :right  => 36,
                                           :top    => 36,
                                           :bottom => 36  }
        @bleeds    = options[:bleeds] || { :left   => 0,
                                           :right  => 0,
                                           :top    => 0,
                                           :bottom => 0  }
        @stack = GraphicStateStack.new(options[:graphic_state])
        if options[:object_id]
          init_from_object(options)
        else
          init_new_page(options)
        end
      end

      def graphic_state
        stack.current_state
      end

      def layout
        return @layout if defined?(@layout) && @layout

        mb = dictionary.data[:MediaBox]
        if mb[3] > mb[2]
          :portrait
        else
          :landscape
        end
      end

      def size
        defined?(@size) && @size || dimensions[2,2]
      end

      def in_stamp_stream?
        !!@stamp_stream
      end

      def stamp_stream(dictionary)
        @stamp_stream     = ""
        @stamp_dictionary = dictionary
        graphic_stack_size = stack.stack.size

        document.save_graphics_state
        document.send(:freeze_stamp_graphics)
        yield if block_given?

        until graphic_stack_size == stack.stack.size
          document.restore_graphics_state
        end

        @stamp_dictionary << @stamp_stream

        @stamp_stream      = nil
        @stamp_dictionary  = nil
      end

      def content
        @stamp_stream || document.state.store[@content]
      end

      def dictionary
        defined?(@stamp_dictionary) && @stamp_dictionary || document.state.store[@dictionary]
      end

      def resources
        if dictionary.data[:Resources]
          document.deref(dictionary.data[:Resources])
        else
          dictionary.data[:Resources] = {}
        end
      end

      def fonts
        if resources[:Font]
          document.deref(resources[:Font])
        else
          resources[:Font] = {}
        end
      end

      def xobjects
        if resources[:XObject]
          document.deref(resources[:XObject])
        else
          resources[:XObject] = {}
        end
      end

      def ext_gstates
        if resources[:ExtGState]
          document.deref(resources[:ExtGState])
        else
          resources[:ExtGState] = {}
        end
      end

      def finalize
        if dictionary.data[:Contents].is_a?(Array)
          dictionary.data[:Contents].each do |stream|
            stream.stream.compress! if document.compression_enabled?
          end
        else
          content.stream.compress! if document.compression_enabled?
        end
      end

      def imported_page?
        @imported_page
      end

      def dimensions
        return inherited_dictionary_value(:MediaBox) if imported_page?

        coords = PDF::Core::PageGeometry::SIZES[size] || size
        [0,0] + case(layout)
        when :portrait
          coords
        when :landscape
          coords.reverse
        else
          raise PDF::Core::Errors::InvalidPageLayout,
            "Layout must be either :portrait or :landscape"
        end
      end

      def trimbox_dimensions
        x1, y1, x2, y2 = dimensions
        [x1 + bleeds[:left],  y1 + bleeds[:bottom],
         x2 - bleeds[:right], y2 - bleeds[:top]]
      end

      private

      def init_from_object(options)
        @dictionary = options[:object_id].to_i

        unless dictionary.data[:Contents].is_a?(Array) # content only on leafs
          @content    = dictionary.data[:Contents].identifier
        end

        @stamp_stream      = nil
        @stamp_dictionary  = nil
        @imported_page     = true
      end

      def init_new_page(options)
        @size     = options[:size]    ||  "LETTER"
        @layout   = options[:layout]  || :portrait

        @stamp_stream      = nil
        @stamp_dictionary  = nil
        @imported_page     = false

        @content    = document.ref({})
        content << "q" << "\n"
        @dictionary = document.ref(:Type        => :Page,
                                   :Parent      => document.state.store.pages,
                                   :MediaBox    => dimensions,
                                   :CropBox     => dimensions,
                                   :BleedBox    => dimensions,
                                   :TrimBox     => trimbox_dimensions,
                                   :Contents    => content)

        resources[:ProcSet] = [:PDF, :Text, :ImageB, :ImageC, :ImageI]
      end

      # some entries in the Page dict can be inherited from parent Pages dicts.
      #
      # Starting with the current page dict, this method will walk up the
      # inheritance chain return the first value that is found for key
      #
      #     inherited_dictionary_value(:MediaBox)
      #     => [ 0, 0, 595, 842 ]
      #
      def inherited_dictionary_value(key, local_dict = nil)
        local_dict ||= dictionary.data

        if local_dict.has_key?(key)
          local_dict[key]
        elsif local_dict.has_key?(:Parent)
          inherited_dictionary_value(key, local_dict[:Parent].data)
        else
          nil
        end
      end
    end
  end
end
