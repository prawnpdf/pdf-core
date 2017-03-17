require 'pdf/core/pdf_object'
require 'pdf/core/annotations'
require 'pdf/core/byte_string'
require 'pdf/core/destinations'
require 'pdf/core/filters'
require 'pdf/core/stream'
require 'pdf/core/reference'
require 'pdf/core/literal_string'
require 'pdf/core/filter_list'
require 'pdf/core/graphics_state'
require 'pdf/core/page'
require 'pdf/core/object_store'
require 'pdf/core/document_state'
require 'pdf/core/name_tree'
require 'pdf/core/graphics_state'
require 'pdf/core/page_geometry'
require 'pdf/core/outline_root'
require 'pdf/core/outline_item'
require 'pdf/core/renderer'
require 'pdf/core/text'

module PDF
  module Core
    module Errors
      # This error is raised when pdf_object() fails
      FailedObjectConversion = Class.new(StandardError)

      # This error is raise when trying to restore a graphic state that
      EmptyGraphicStateStack = Class.new(StandardError)

      # This error is raised when Document#page_layout is set to anything
      # other than :portrait or :landscape
      InvalidPageLayout = Class.new(StandardError)
    end
  end
end
