# frozen_string_literal: true

# Implements a consistent interface for IO objects.

require 'stringio'

module PDF
  module Core
    class IoWrapper
      attr_reader :size

      def self.wrap(io)
        return io if self === io
        io.set_encoding(::Encoding::ASCII_8BIT) if io.instance_of?(StringIO)
        new(io)
      end

      def initialize(io)
        @io = io
        @size = 0
      end

      def printf(*args, **kwargs)
        self << sprintf(*args, **kwargs)
      end

      def <<(chunk)
        @io << chunk
        @size += chunk.to_s.bytesize
        self
      end

      def string
        return unless @io.instance_of?(StringIO)

        str = @io.string
        str.force_encoding(::Encoding::ASCII_8BIT)
        str
      end
    end
  end
end
