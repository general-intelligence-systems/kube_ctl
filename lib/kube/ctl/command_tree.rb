# frozen_string_literal: true

require "set"
require "json"

module Kube
  module Ctl
    class CommandTree
      Evaluation = Struct.new(:commands, :resources, :flags, :errors, :rendered, :valid) do
        def to_s
          rendered
        end
      end

      include Enumerable

      attr_reader :tree

      def self.from_file(path)
        new(JSON.parse(File.read(path)))
      end

      def initialize(tree_data)
        @tree_data = tree_data
      end

      def each
        yield @tree_data
      end

      def evaluate(string_builder, resource_dataset: nil)
        units = extract_units(string_builder)
        resources = []
        command_tokens = []
        flags = []
        errors = []

        command_cursor = children_of(@tree_data)

        in_command_phase = true
        command_ended = false
        resource_buffer = String.new
        slash_pending = false
        dash_pending = false
        pending_flag_arg = false
        resource_set = resource_dataset ? normalize_resource_set(resource_dataset) : nil

        units.each do |unit|
          if unit[:type] == :separator
            separator = unit[:value]
            if separator == "/"
              slash_pending = true
            elsif separator == "-"
              dash_pending = true
            end
            next
          end

          token = unit[:value]
          args = unit[:args]
          rendered = unit[:rendered] || render_token(token)

          if in_command_phase
            if command_cursor.key?(token)
              command_tokens << token
              command_cursor = children_of(command_cursor[token])
              next
            end

            in_command_phase = false
            command_ended = true
            if command_tokens.empty?
              errors << "invalid command start: `#{token}`"
            end
          end

          if pending_flag_arg && !token.start_with?("-")
            flags[-1] = "#{flags[-1]} #{rendered}"
            pending_flag_arg = false
            next
          end

          if token.start_with?("-")
            flags << rendered
            pending_flag_arg = true
            next
          end

          if args.any?
            flags << "--#{render_flag(token)} #{render_token(token, args).split(" ", 2).last}"
            next
          end

          if slash_pending
            resource_buffer << "/"
          elsif dash_pending
            resource_buffer << "-"
          elsif !resource_buffer.empty?
            resource_buffer << "."
          end
          resource_buffer << rendered
          slash_pending = false
          dash_pending = false
        end

        if command_ended
          resources << resource_buffer unless resource_buffer.empty?
          if resource_set && !resource_set.empty? && !resource_set.include?(resource_buffer)
            errors << "unknown resource: `#{resource_buffer}`"
          end
        end

        rendered = [command_tokens.join(" "), resources.join(" "), flags.join(" ")].reject(&:empty?).join(" ")

        Evaluation.new(
          command_tokens,
          resources,
          flags,
          errors,
          rendered,
          errors.empty?
        )
      end

      private

      def normalize_resource_set(resource_dataset)
        resource_set = if resource_dataset.is_a?(Set)
          resource_dataset
        else
          Set.new(resource_dataset)
        end

        resource_set
      end

      def extract_units(string_builder)
        (string_builder.respond_to?(:buffer) ? string_builder.buffer : []).map do |entry|
          if entry == :slash
            { type: :separator, value: "/" }
          elsif entry == :dash
            { type: :separator, value: "-" }
          else
            next unless entry.is_a?(Array) && entry.length == 2

            name = entry[0].to_s
            args = entry[1] || []
            {
              type: :token,
              value: name,
              args: args,
              rendered: render_token(name, args),
            }
          end
        end.compact
      end

      def children_of(node)
        return {} unless node.is_a?(Hash)
        return node["subcommands"] if node.key?("subcommands") && node["subcommands"].is_a?(Hash)

        node
      end

      def render_token(token, args = nil)
        arg_values = args || []
        return token if arg_values.empty?

        serialized = arg_values.map(&:to_s).join(" ")
        [token, serialized].join(" ")
      end

      def render_flag(token)
        token.tr("_", "-")
      end
    end
  end
end
