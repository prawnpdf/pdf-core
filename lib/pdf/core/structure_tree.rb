# frozen_string_literal: true

module PDF
  module Core
    # Logical structure of a tagged PDF (section *14.7 Logical Structure* in
    # PDF 1.7 spec) and the marked content that ties it to page content
    # (section *14.6 Marked Content*).
    #
    # Structure elements and artifacts are opened and closed as a stack.
    # Content belongs to the innermost one. Marked-content sequences are never
    # nested: a page has at most one open sequence, and when the innermost
    # entry changes, the next content written to that page closes the old
    # sequence and opens a new one. Every sequence gets its own MCID, so an
    # element can continue across a page break or around an artifact.
    #
    # @api private
    class StructureTree
      # An artifact entry on the stack (section *14.8.2.2 Real Content and
      # Artifacts*).
      Artifact = Struct.new(:properties)

      # StructTreeRoot dictionary.
      #
      # @return [PDF::Core::Reference<Hash>]
      attr_reader :root

      # @param store [PDF::Core::ObjectStore]
      def initialize(store)
        @parent_tree = store.ref(Nums: [])
        @root = store.ref(
          Type: :StructTreeRoot,
          K: [],
          ParentTree: @parent_tree,
          ParentTreeNextKey: 0,
        )
        @store = store
        @stack = []
        @open = {}
        @page_parents = {}

        store.root.data[:StructTreeRoot] = @root
        store.root.data[:MarkInfo] = { Marked: true }
      end

      # Opens a structure element as a child of the innermost open element, or
      # of the root when none is open.
      #
      # @param type [Symbol] structure type, e.g. `:P`, `:H1`, `:Figure`
      # @param attributes [Hash] additional StructElem entries, e.g. `:Alt`,
      #   `:ActualText`, `:Lang`, `:A`
      # @yieldparam element [PDF::Core::Reference<Hash>]
      # @return [void]
      def element(type, attributes = {})
        parent = innermost_element || root
        element = @store.ref(
          attributes.merge(Type: :StructElem, S: type, P: parent, K: []),
        )
        parent.data[:K] << element

        within(element) { yield element }
      end

      # Marks content drawn in the block as an artifact: content that is not
      # part of the document's logical structure, such as page numbers or
      # decoration.
      #
      # @param properties [Hash] artifact properties, e.g. `Type: :Pagination`
      # @return [void]
      def artifact(properties = {}, &block)
        within(Artifact.new(properties), &block)
      end

      # Prepares a page for content: makes sure its open marked-content
      # sequence belongs to the innermost structure element or artifact.
      #
      # Stamps are skipped. Their content is marked where they are drawn.
      #
      # @param page [PDF::Core::Page]
      # @return [void]
      def mark(page)
        return if page.in_stamp_stream?

        entry = @stack.last
        return if @open[page].equal?(entry)

        close(page)
        open_sequence(page, entry) if entry
      end

      # Closes the page's open marked-content sequence, if any.
      #
      # @param page [PDF::Core::Page]
      # @return [void]
      def close(page)
        page.content << "EMC\n" if @open.delete(page)
      end

      # Makes an annotation part of the innermost structure element, so
      # assistive technology finds it in reading order.
      #
      # @param page [PDF::Core::Page]
      # @param annotation [PDF::Core::Reference<Hash>]
      # @return [void]
      def annotate(page, annotation)
        return if page.in_stamp_stream?

        page.dictionary.data[:Tabs] = :S
        element = @stack.last
        return unless element.is_a?(Reference)

        key = next_key
        annotation.data[:StructParent] = key
        @parent_tree.data[:Nums].push(key, element)
        element.data[:K] << { Type: :OBJR, Obj: annotation, Pg: page.dictionary }
      end

      private

      def within(entry)
        @stack.push(entry)
        yield
      ensure
        @stack.pop
      end

      def innermost_element
        @stack.reverse_each.find { |entry| entry.is_a?(Reference) }
      end

      def open_sequence(page, entry)
        page.content <<
          if entry.is_a?(Artifact)
            artifact_operator(entry.properties)
          else
            element_operator(page, entry)
          end
        @open[page] = entry
      end

      def artifact_operator(properties)
        if properties.empty?
          "/Artifact BMC\n"
        else
          "/Artifact #{PDF::Core.pdf_object(properties, true)} BDC\n"
        end
      end

      def element_operator(page, element)
        parents = page_parents(page)
        mcid = parents.length
        parents << element
        element.data[:K] << { Type: :MCR, Pg: page.dictionary, MCID: mcid }

        type = PDF::Core.pdf_object(element.data[:S], true)
        "#{type} #{PDF::Core.pdf_object({ MCID: mcid }, true)} BDC\n"
      end

      # The parent tree maps each page's MCIDs back to their structure
      # elements, which is how a reader goes from content to structure.
      def page_parents(page)
        @page_parents[page] ||=
          begin
            key = next_key
            page.dictionary.data[:StructParents] = key
            [].tap { |parents| @parent_tree.data[:Nums].push(key, parents) }
          end
      end

      def next_key
        key = root.data[:ParentTreeNextKey]
        root.data[:ParentTreeNextKey] += 1
        key
      end
    end
  end
end
