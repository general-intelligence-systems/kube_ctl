# frozen_string_literal: true

module Kube
  module Ctl
    class Concat
      attr_reader :buffer

      def self.call(buffer) = new(buffer).concat
      def initialize(buffer) = @buffer = buffer.to_a

      def concat
        parts = []

        join_next = false

        buffer.each do |entry|
          case entry
          when :dash
            # Append '-' to previous token; next token joins directly
            parts[-1] = "#{parts.last}-" if parts.last
            join_next = true
          when :slash
            # Append '/' to previous token; next token joins directly
            parts[-1] = "#{parts.last}/" if parts.last
            join_next = true
          when Array
            part = render_entry(entry)
            if join_next
              parts[-1] = "#{parts.last}#{part}"
            else
              parts << part
            end
            join_next = false
          end
        end

        parts.join(" ")
      end

      private

      def render_entry(entry)
        name, args = entry

        # Hash entry from .() kwargs — e.g. [{description: 'my frontend'}]
        if name.is_a?(Hash)
          return name.map { |k, v|
            v_str = v.include?(' ') ? "'#{v}'" : v
            "#{k}=#{v_str}"
          }.join(" ")
        end

        # No args — bare token
        if args.nil? || args.empty?
          return name
        end

        # Check if args is a single hash (kwargs passed to a method)
        if args.length == 1 && args[0].is_a?(Hash)
          kwargs = args[0]
          if name.length == 1
            # Short flag with kwargs: -l app=nginx
            kv = kwargs.map { |k, v| "#{k}=#{format_arg(v)}" }.join(" ")
            return "-#{name} #{kv}"
          else
            # Long flag with kwargs: -o jsonpath='...'
            flag_name = name.tr('_', '-')
            kv = kwargs.map { |k, v| "#{k}=#{format_arg(v)}" }.join(" ")
            return "-#{name.length == 1 ? '' : '-'}#{flag_name} #{kv}"
          end
        end

        # Single arg that is `true` — boolean flag
        if args == [true]
          if name.length == 1
            return "-#{name}"
          else
            flag_name = name.tr('_', '-')
            return "--#{flag_name}"
          end
        end

        # Has args — flag with value(s)
        if name.length == 1
          # Short flag: -f value
          value = args.map { |a| format_arg(a) }.join(",")
          return "-#{name} #{value}"
        else
          # Long flag: --name=value
          flag_name = name.tr('_', '-')
          value = args.map { |a| format_arg(a) }.join(",")
          return "--#{flag_name}=#{value}"
        end
      end

      def format_arg(arg)
        case arg
        when Symbol then arg.to_s
        when true then "true"
        when false then "false"
        else arg.to_s
        end
      end
    end
  end
end
