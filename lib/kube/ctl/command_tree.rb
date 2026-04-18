# frozen_string_literal: true

require "yaml"
require_relative "command_tree/node"
require_relative "command_tree/validator"

module Kube
  module Ctl
    class CommandTree
      Result = Struct.new(:commands, :resources, :flags, :errors, :valid) do
        def to_s
          parts = []
          parts.concat(commands)
          parts.concat(resources)
          parts.concat(flags)
          parts.join(" ")
        end
      end

      def initialize(data)
        @root = Node.new(name: 'kubectl')

        data.fetch('toplevelcommandgroups', []).each do |group|
          group.fetch('commands', []).each do |entry|
            main = entry['maincommand']
            next unless main
            node = build_node(main)
            (entry['subcommands'] || []).each do |sub|
              node.add_subcommand(build_node(sub))
            end
            @root.add_subcommand(node)
          end
        end
      end

      def evaluate(builder, resource_dataset: nil)
        buffer = builder.to_a
        commands = []
        resources = []
        flags = []
        errors = []

        node = @root
        i = 0

        # 1. Walk commands/subcommands
        while i < buffer.length
          entry = buffer[i]
          break unless entry.is_a?(Array)
          name, args = entry
          break unless args.empty?

          child = node.find_subcommand(name)
          break unless child

          commands << name
          node = child
          i += 1

          # Consume :dash separated subcommand parts (e.g. set-last-applied)
          while i < buffer.length && buffer[i] == :dash
            next_i = i + 1
            break unless next_i < buffer.length && buffer[next_i].is_a?(Array)
            next_name, next_args = buffer[next_i]
            break unless next_args.empty?
            hyphenated = "#{commands.last}-#{next_name}"
            child = node.find_subcommand(hyphenated)
            if child
              commands[-1] = hyphenated
              node = child
              i = next_i + 1
            else
              break
            end
          end
        end

        if commands.empty? && buffer.any?
          first = buffer[0].is_a?(Array) ? buffer[0][0] : buffer[0].to_s
          errors << "invalid command start: `#{first}`"
        end

        # 2. Walk remaining buffer: classify as resources or flags
        current_resource = nil

        while i < buffer.length
          entry = buffer[i]

          case entry
          when :dash
            current_resource = "#{current_resource}-" if current_resource
            i += 1
          when :slash
            current_resource = "#{current_resource}/" if current_resource
            i += 1
          when Array
            name, args = entry

            if args.nil? || args.empty?
              # Bare token — resource segment
              if current_resource && !current_resource.end_with?("-") && !current_resource.end_with?("/")
                current_resource = "#{current_resource}.#{name}"
              elsif current_resource
                current_resource = "#{current_resource}#{name}"
              else
                current_resource = name
              end
              i += 1
            else
              # Has args — it's a flag
              flush_resource(resources, current_resource)
              current_resource = nil
              flag_name = name.tr("_", "-")

              if args == [true]
                flags << "--#{flag_name}"
              else
                value = args.map(&:to_s).join(",")
                flags << "--#{flag_name} #{value}"
              end
              i += 1
            end
          else
            i += 1
          end
        end

        flush_resource(resources, current_resource)

        # 3. Validate resources against dataset if provided
        if resource_dataset
          resources.each do |r|
            errors << "unknown resource: `#{r}`" unless resource_dataset.include?(r)
          end
        end

        Result.new(commands, resources, flags, errors, errors.empty?)
      end

      private

      def flush_resource(resources, current)
        resources << current if current && !current.empty?
      end

      def build_node(h)
        Node.new(
          name: h['name'],
          options: h['options'] || [],
          inherited_options: h['inherited_options'] || [],
          usage: h['usage']
        )
      end
    end
  end
end
