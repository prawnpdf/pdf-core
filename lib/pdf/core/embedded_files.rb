# frozen_string_literal: true

module PDF
  module Core
    module EmbeddedFiles #:nodoc:
      # The maximum number of children to fit into a single node in the
      # EmbeddedFiles tree.
      NAME_TREE_CHILDREN_LIMIT = 20 #:nodoc:

      # The EmbeddedFiles name tree in the Name dictionary (see
      # Prawn::Document::Internal#names). This name tree is used to store named
      # embedded files (PDF spec 3.10.3). (For more on name trees, see section
      # 3.8.4 in the PDF spec.)
      #
      def embedded_files
        names.data[:EmbeddedFiles] ||= ref!(
          PDF::Core::NameTree::Node.new(self, NAME_TREE_CHILDREN_LIMIT)
        )
      end

      # Adds a new embedded file to the EmbeddedFiles name tree
      # (see #embedded_files). The +reference+ parameter will be converted into
      # a PDF::Core::Reference if it is not already one.
      #
      def add_embedded_file(name, reference)
        reference = ref!(reference) unless reference.is_a?(PDF::Core::Reference)
        embedded_files.data.add(name, reference)
      end

      # Friendly method alias to attach file specifications in the catalog
      alias :attach_file :add_embedded_file
    end
  end
end