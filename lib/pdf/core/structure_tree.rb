# frozen_string_literal: true

module PDF
  module Core
    # Manages the PDF structure tree for tagged/accessible PDFs.
    #
    # The structure tree provides the logical structure of a document,
    # mapping marked content sequences in page content streams to
    # structure elements (headings, paragraphs, tables, etc.).
    #
    # PDF spec references: Section 14.7 (Logical Structure)
    #
    # @api private
    class StructureTree
      # @return [PDF::Core::Renderer] owning renderer
      attr_reader :renderer

      # @return [PDF::Core::Reference] StructTreeRoot indirect object
      attr_reader :root_ref

      # @return [PDF::Core::Reference] Document-level structure element
      attr_reader :document_elem_ref

      # @return [Array<Hash>] all structure elements created
      attr_reader :elements

      # @return [Hash{Integer => Array}] page StructParents index => array of
      #   structure element refs for marked content on that page
      attr_reader :parent_tree_map

      # @return [Integer] next available MCID for the current page
      attr_reader :next_mcid

      # @return [Array<PDF::Core::Reference>] stack of open structure elements
      attr_reader :element_stack

      # @param renderer [PDF::Core::Renderer]
      def initialize(renderer)
        @renderer = renderer
        @elements = []
        @parent_tree_map = {}
        @next_mcid = 0
        @element_stack = []
        @page_mcid_map = {} # page_ref_id => next mcid for that page
        @root_ref = nil
        @document_elem_ref = nil
      end

      # Allocate the next MCID for the current page and track it.
      #
      # @return [Integer] the allocated MCID
      def allocate_mcid
        page = renderer.state.page
        page_id = page.dictionary.identifier

        @page_mcid_map[page_id] ||= 0
        mcid = @page_mcid_map[page_id]
        @page_mcid_map[page_id] += 1

        mcid
      end

      # Add a structure element as a child of the current open element
      # (or the document element if none is open).
      #
      # @param tag [Symbol] structure type (e.g., :P, :H1, :Table, :TD)
      # @param attributes [Hash] additional attributes for the structure element
      # @option attributes [String] :Alt alternative text (for Figure, Formula)
      # @option attributes [String] :ActualText replacement text for screen
      #   readers (e.g., "required" instead of reading "*")
      # @option attributes [String] :Lang language tag
      # @option attributes [Symbol] :Scope TH scope (:Column, :Row, :Both)
      # @return [PDF::Core::Reference] the structure element reference
      def add_element(tag, attributes = {})
        parent_ref = current_element || document_element

        elem_data = {
          Type: :StructElem,
          S: tag,
          P: parent_ref,
          K: [],
        }

        elem_data[:Alt] = attributes[:Alt] if attributes[:Alt]
        elem_data[:ActualText] = attributes[:ActualText] if attributes[:ActualText]
        elem_data[:Lang] = attributes[:Lang] if attributes[:Lang]

        if attributes[:Scope]
          elem_data[:A] = {
            O: :Table,
            Scope: attributes[:Scope],
          }
        end

        elem_ref = renderer.ref!(elem_data)
        @elements << elem_ref

        # Add as child of parent
        parent_data = renderer.deref(parent_ref)
        parent_data[:K] << elem_ref

        elem_ref
      end

      # Begin a structure element scope. Content rendered inside will be
      # children of this element.
      #
      # @param tag [Symbol] structure type
      # @param attributes [Hash] additional attributes
      # @return [PDF::Core::Reference] the opened structure element
      def begin_element(tag, attributes = {})
        elem_ref = add_element(tag, attributes)
        @element_stack.push(elem_ref)
        elem_ref
      end

      # End the current structure element scope.
      #
      # @return [PDF::Core::Reference] the closed structure element
      def end_element
        @element_stack.pop
      end

      # Add marked content to the current structure element.
      # This allocates an MCID, records the mapping, and emits BDC/EMC
      # operators around the yielded block.
      #
      # @param tag [Symbol] marked content tag (e.g., :P, :Span)
      # @param struct_elem_ref [PDF::Core::Reference, nil] the structure element
      #   this content belongs to. If nil, uses current_element.
      # @yield content to render inside the marked content sequence
      # @return [void]
      def mark_content(tag, struct_elem_ref: nil)
        elem_ref = struct_elem_ref || current_element || document_element
        mcid = allocate_mcid
        page = renderer.state.page
        page_ref = page.dictionary

        # Record in parent tree map
        page_struct_parents = page_struct_parents_index(page_ref)
        @parent_tree_map[page_struct_parents] ||= []

        # Add marked content reference to the structure element's K array
        mcr = { Type: :MCR, MCID: mcid, Pg: page_ref }
        elem_data = renderer.deref(elem_ref)
        elem_data[:K] << mcr

        # Track which struct element owns this MCID on this page
        @parent_tree_map[page_struct_parents][mcid] = elem_ref

        # Emit BDC/EMC in content stream
        renderer.begin_marked_content_with_properties(tag, { MCID: mcid })
        yield if block_given?
        renderer.end_marked_content
      end

      # Mark content as an artifact (decorative, not read by screen readers).
      #
      # @param artifact_type [Symbol, nil] optional artifact type
      #   (:Pagination, :Layout, :Page, :Background)
      # @yield content to render as artifact
      # @return [void]
      def mark_artifact(artifact_type: nil)
        if artifact_type
          renderer.begin_marked_content_with_properties(
            :Artifact, { Type: artifact_type },
          )
        else
          renderer.begin_marked_content(:Artifact)
        end
        yield if block_given?
        renderer.end_marked_content
      end

      # Finalize the structure tree before rendering. Called via
      # before_render callback.
      #
      # Builds the StructTreeRoot, ParentTree, and wires everything
      # into the Catalog.
      #
      # @return [void]
      def finalize!
        return if @elements.empty? && @parent_tree_map.empty?

        build_root
        build_parent_tree
        assign_struct_parents_to_pages
        attach_to_catalog
      end

      private

      # The current open structure element, or nil if none.
      #
      # @return [PDF::Core::Reference, nil]
      def current_element
        @element_stack.last
      end

      # Get or create the Document-level structure element.
      #
      # @return [PDF::Core::Reference]
      def document_element
        return @document_elem_ref if @document_elem_ref

        @document_elem_ref = renderer.ref!(
          Type: :StructElem,
          S: :Document,
          P: nil, # will be set to StructTreeRoot in finalize!
          K: [],
        )
        @elements << @document_elem_ref
        @document_elem_ref
      end

      # Get or assign a StructParents index for a page.
      #
      # @param page_ref [PDF::Core::Reference] page dictionary reference
      # @return [Integer] the StructParents index
      def page_struct_parents_index(page_ref)
        page_ref.data[:StructParents] ||= @parent_tree_map.size
        page_ref.data[:StructParents]
      end

      # Build the StructTreeRoot object.
      #
      # @return [void]
      def build_root
        @root_ref = renderer.ref!(
          Type: :StructTreeRoot,
          K: document_element,
          ParentTree: nil, # set in build_parent_tree
        )

        # Point Document element's parent to the root
        doc_data = renderer.deref(@document_elem_ref)
        doc_data[:P] = @root_ref
      end

      # Build the ParentTree (a number tree mapping StructParents indices
      # to arrays of structure element references).
      #
      # @return [void]
      def build_parent_tree
        # ParentTree is a number tree. For simplicity, use a flat Nums array
        # since most documents won't have enough pages to need a balanced tree.
        nums = []
        @parent_tree_map.sort_by { |k, _| k }.each do |index, elem_array|
          nums << index
          nums << renderer.ref!(elem_array)
        end

        parent_tree_ref = renderer.ref!(Type: :ParentTree, Nums: nums)
        root_data = renderer.deref(@root_ref)
        root_data[:ParentTree] = parent_tree_ref
      end

      # Ensure each page that has marked content has a StructParents entry.
      # (Already handled lazily in page_struct_parents_index, but verify.)
      #
      # @return [void]
      def assign_struct_parents_to_pages
        # Already assigned lazily when mark_content is called.
        # This method exists as a hook for any additional finalization.
      end

      # Wire the StructTreeRoot into the document Catalog.
      #
      # @return [void]
      def attach_to_catalog
        renderer.state.store.root.data[:StructTreeRoot] = @root_ref
      end
    end
  end
end
