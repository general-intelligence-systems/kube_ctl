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
        pending_flag_arg = false
        resource_set = resource_dataset ? normalize_resource_set(resource_dataset) : nil
        resource_parts = []

        units.each do |unit|
          if unit[:type] == :separator
            resource_parts.last[:separator] = unit[:value] unless resource_parts.empty?
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
            if args.length == 1 && args[0] == true
              flags << "--#{render_flag(token)}"
            else
              flags << "--#{render_flag(token)} #{render_token(token, args).split(" ", 2).last}"
            end
            next
          end

          separator = resource_parts.empty? ? nil : "."
          resource_parts << { value: rendered, separator: separator }
        end

        if command_ended
          resource = serialize_resource(resource_parts)
          resources << resource unless resource.empty?

          if resource_set && !resource_set.empty? && !resource_set.include?(resource)
            errors << "unknown resource: `#{resource}`"
          end
        end

        rendered_resources = resources.map { |resource| render_resource(resource) }
        rendered_flags = flags.map { |flag| flag.start_with?("--output ") ? flag.sub("--output ", "-o ") : flag }
        rendered = [command_tokens.join(" "), rendered_resources.join(" "), rendered_flags.join(" ")].reject(&:empty?).join(" ")

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

      def render_resource(resource)
        return resource unless resource.include?("/")

        name, version = resource.split("/", 2)
        return resource unless version&.start_with?("v")

        resource_groups = {
          "deployment" => "apps"
        }

        group = resource_groups[name]
        return resource unless group

        "#{version}/#{group}"
      end

      def serialize_resource(resource_parts)
        result = String.new

        resource_parts.each do |part|
          if result.empty?
            result << part[:value]
          else
            separator = part[:separator] || "."
            result << separator
            result << part[:value]
          end
        end

        result
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
