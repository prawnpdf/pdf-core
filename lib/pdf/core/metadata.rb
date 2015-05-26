# encoding: utf-8

# prawn/core/metadata.rb : Implements Metadata objects
#
# Copyright September 2014, Robert Bousquet.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module PDF
  module Core
    class Metadata

      attr_reader :input, :type, :subtype

      def initialize(input, options={})
        @input   = Stream.new.tap{|s| s << input }
        @type    = options[:type]    || :Metadata
        @subtype = options[:subtype] || :XML
      end

      def dictionary
        { :Length => input.length, :Type =>  type, :Subtype => subtype }
      end

      def content
        input.object
      end

    end
  end
end
