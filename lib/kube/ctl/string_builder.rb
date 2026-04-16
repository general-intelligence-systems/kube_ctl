# frozen_string_literal: true

module Kube
  module Ctl
    class MethodCallToken
      attr_reader :base
      attr_reader :name
      attr_reader :args

      def initialize(base, name, args)
        @base = base
        @name = name
        @args = args
      end
    end

    class StringBuilder
      include Enumerable

      attr_reader :buffer

      def initialize
        @buffer = []
      end

      def each
        yield @buffer
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

      def -(other)
        tap do
          case other
          when MethodCallToken
            @buffer << [other.base.to_s, []]
            @buffer << :dash
            @buffer << [other.name.to_s, other.args]
          else
            @buffer << [other.to_s, []] unless other.is_a?(StringBuilder)
            @buffer << :dash
          end
        end
      end
    end

    class ::Integer
      def method_missing(name, *args, &_block)
        return super unless name.to_s.match?(/\A[a-z_][a-z0-9_]*\z/)

        MethodCallToken.new(self, name, args)
      end

      def respond_to_missing?(name, include_private = false)
        name.to_s.match?(/\A[a-z_][a-z0-9_]*\z/) || super
      end
    end
  end
end
