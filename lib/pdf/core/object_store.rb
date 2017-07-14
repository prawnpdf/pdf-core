# encoding: utf-8

# Implements PDF object repository
#
# Copyright August 2009, Brad Ediger.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module PDF
  module Core
    class ObjectStore #:nodoc:
      include Enumerable

      attr_reader :min_version

      def initialize(opts = {})
        @objects = {}
        @identifiers = []

        @info  ||= ref(opts[:info] || {}).identifier
        @root  ||= ref(Type: :Catalog).identifier

        if opts[:enable_pdfa_1b]
          # PDF/A-1b requirement: XMP metadata
          @xmp_metadata ||= ref(Type: :Metadata, Subtype: :XML).identifier
          root.data[:Metadata] = xmp_metadata
          xmp_metadata_content = XmpMetadata.new(opts[:info] || {})
          xmp_metadata_content.enable_pdfa_1b = true
          xmp_metadata.stream = Stream.new
          xmp_metadata.stream << xmp_metadata_content.render

          # PDF/A-1b requirement: OutputIntent with ICC profile stream
          initialize_output_intent
        end

        if opts[:print_scaling] == :none
          root.data[:ViewerPreferences] = { PrintScaling: :None }
        end
        if pages.nil?
          root.data[:Pages] = ref(Type: :Pages, Count: 0, Kids: [])
        end
      end

      def ref(data, &block)
        push(size + 1, data, &block)
      end

      def info
        @objects[@info]
      end

      def root
        @objects[@root]
      end

      def xmp_metadata
        @objects[@xmp_metadata]
      end

      def pages
        root.data[:Pages]
      end

      def page_count
        pages.data[:Count]
      end

      # Adds the given reference to the store and returns the reference object.
      # If the object provided is not a PDF::Core::Reference, one is created
      # from the arguments provided.
      #
      def push(*args, &block)
        reference =
          if args.first.is_a?(PDF::Core::Reference)
            args.first
          else
            PDF::Core::Reference.new(*args, &block)
          end

        @objects[reference.identifier] = reference
        @identifiers << reference.identifier
        reference
      end

      alias << push

      def each
        @identifiers.each do |id|
          yield @objects[id]
        end
      end

      def [](id)
        @objects[id]
      end

      def size
        @identifiers.size
      end
      alias length size

      # returns the object ID for a particular page in the document. Pages
      # are indexed starting at 1 (not 0!).
      #
      #   object_id_for_page(1)
      #   => 5
      #   object_id_for_page(10)
      #   => 87
      #   object_id_for_page(-11)
      #   => 17
      #
      def object_id_for_page(k)
        k -= 1 if k > 0
        flat_page_ids = get_page_objects(pages).flatten
        flat_page_ids[k]
      end

      private

      def initialize_output_intent
        icc_profile_name = 'sRGB2014.icc'.freeze

        icc_profile_stream = ref(N: 3)
        icc_profile_stream.stream = Stream.new
        icc_profile_stream << File.binread(File.join(File.dirname(__FILE__), '..', '..', '..', 'data', icc_profile_name))

        root.data[:OutputIntents] = [{
          Type: :OutputIntent,
          S: :GTS_PDFA1,
          OutputConditionIdentifier: LiteralString.new('Custom'),
          Info: LiteralString.new(File.basename(icc_profile_name, '.*')),
          DestOutputProfile: icc_profile_stream
        }]
      end
    end
  end
end
