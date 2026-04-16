# File path: ./lib/kube/ctl/string_builder.rb
# frozen_string_literal: true
module Kube
  module Ctl
    class StringBuilder
      attr_reader :buffer

      def initialize
        @buffer = []
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end

      def method_missing(name, *args, &_block)
        tap do
          @buffer << [name.to_s, args]
        end
      end

      def call(token)
        tap do
          @buffer << [token.to_s, []]
        end
      end

      def /(_other)
        tap do
          @buffer << :slash
        end
      end

      def -(_other)
        tap do
          @buffer << :dash
        end
      end
    end
  end
end
