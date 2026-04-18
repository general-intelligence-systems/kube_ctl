# frozen_string_literal: true

require "yaml"
require_relative "../ctl/command_tree/node"

module Kube
  module Helm
    class CommandTree
      Result = Struct.new(:commands, :positional, :flags, :errors, :valid) do
        def to_s
          parts = []
          parts.concat(commands)
          parts.concat(positional)
          parts.concat(flags)
          parts.join(" ")
        end
      end

      # Parses helm.yaml's flat commands array.
      #
      # Each entry has a `name` like "helm", "helm install", "helm get values".
      # We split on spaces, skip the leading "helm" token, and insert into a
      # tree rooted at a synthetic "helm" node.
      def initialize(data)
        @root = Kube::Ctl::CommandTree::Node.new(name: "helm")

        data.fetch("commands", []).each do |cmd|
          name = cmd["name"]
          next unless name

          parts = name.split
          # Skip the root "helm" entry itself (no subcommand path)
          next if parts.size <= 1

          # Walk/create intermediate nodes, attach leaf with full metadata
          node = @root
          parts[1..].each_with_index do |part, idx|
            existing = node.find_subcommand(part)
            if idx == parts.size - 2
              # Leaf node — build with full options/inherited_options/usage
              if existing
                # Node was pre-created as an intermediate; we can't easily
                # replace it, but the intermediate was created bare. In
                # practice the YAML lists parent commands before children,
                # so the parent entry is processed first and the intermediate
                # won't exist yet when we hit the leaf. But just in case,
                # use the existing node.
                node = existing
              else
                leaf = Kube::Ctl::CommandTree::Node.new(
                  name: part,
                  options: cmd["options"] || [],
                  inherited_options: cmd["inherited_options"] || [],
                  usage: cmd["usage"]
                )
                node.add_subcommand(leaf)
                node = leaf
              end
            else
              if existing
                node = existing
              else
                # Create a bare intermediate node
                intermediate = Kube::Ctl::CommandTree::Node.new(name: part)
                node.add_subcommand(intermediate)
                node = intermediate
              end
            end
          end
        end
      end

      # Evaluate a StringBuilder buffer against the helm command tree.
      #
      # Classifies tokens as:
      #   - commands:   matched subcommand path (e.g. ["repo", "add"])
      #   - positional: bare tokens after commands (release names, chart refs, URLs)
      #   - flags:      tokens with arguments (--namespace default, --set foo=bar)
      def evaluate(builder)
        buffer = builder.to_a
        commands = []
        positional = []
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

          # Consume :dash separated subcommand parts (e.g. insecure-skip-tls-verify)
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

        # 2. Walk remaining buffer: classify as positional args or flags
        current_positional = nil

        while i < buffer.length
          entry = buffer[i]

          case entry
          when :dash
            current_positional = "#{current_positional}-" if current_positional
            i += 1
          when :slash
            current_positional = "#{current_positional}/" if current_positional
            i += 1
          when Array
            name, args = entry

            if args.nil? || args.empty?
              # Bare token — positional segment
              if current_positional && !current_positional.end_with?("-") && !current_positional.end_with?("/")
                # Flush previous positional and start a new one
                flush_positional(positional, current_positional)
                current_positional = name
              elsif current_positional
                # Continue building hyphenated/slashed positional
                current_positional = "#{current_positional}#{name}"
              else
                current_positional = name
              end
              i += 1
            else
              # Has args — it's a flag
              flush_positional(positional, current_positional)
              current_positional = nil
              flag_name = name.tr("_", "-")
              prefix = name.length == 1 ? "-" : "--"

              if args == [true]
                flags << "#{prefix}#{flag_name}"
              else
                value = args.map(&:to_s).join(",")
                flags << "#{prefix}#{flag_name} #{value}"
              end
              i += 1
            end
          else
            i += 1
          end
        end

        flush_positional(positional, current_positional)

        Result.new(commands, positional, flags, errors, errors.empty?)
      end

      private

      def flush_positional(positional, current)
        positional << current if current && !current.empty?
      end
    end
  end
end
