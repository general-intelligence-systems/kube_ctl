# frozen_string_literal: true

require 'yaml'
require_relative '../ctl/command_tree/node'

module Kube
  module VCluster
    class CommandTree
      Result = Struct.new(:commands, :positional, :flags, :errors, :valid) do
        def to_s
          parts = []
          parts.concat(commands)
          parts.concat(positional)
          parts.concat(flags)
          parts.join(' ')
        end
      end

      # Parses vcluster.yaml's flat commands array (same format as helm.yaml).
      #
      # Each entry has a `name` like "vcluster", "vcluster create",
      # "vcluster platform create vcluster".
      # We split on spaces, skip the leading "vcluster" token, and insert
      # into a tree rooted at a synthetic "vcluster" node.
      def initialize(data)
        @root = Kube::Ctl::CommandTree::Node.new(name: 'vcluster')

        data.fetch('commands', []).each do |cmd|
          name = cmd['name']
          next unless name

          parts = name.split
          # Skip the root "vcluster" entry itself (no subcommand path)
          next if parts.size <= 1

          # Walk/create intermediate nodes, attach leaf with full metadata
          node = @root
          parts[1..].each_with_index do |part, idx|
            existing = node.find_subcommand(part)
            if idx == parts.size - 2
              # Leaf node — build with full options/inherited_options/usage
              if existing
                node = existing
              else
                leaf = Kube::Ctl::CommandTree::Node.new(
                  name: part,
                  options: cmd['options'] || [],
                  inherited_options: cmd['inherited_options'] || [],
                  usage: cmd['usage']
                )
                node.add_subcommand(leaf)
                node = leaf
              end
            elsif existing
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

      # Evaluate a StringBuilder buffer against the vcluster command tree.
      #
      # Classifies tokens as:
      #   - commands:   matched subcommand path (e.g. ["platform", "create", "vcluster"])
      #   - positional: bare tokens after commands (vcluster names, URLs, etc.)
      #   - flags:      tokens with arguments (--namespace test, --output json)
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

          # If not found, try building a hyphenated name by looking ahead
          # past :dash tokens (e.g. current :dash user -> "current-user")
          unless child
            hyphenated = name
            peek = i + 1
            while peek < buffer.length && buffer[peek] == :dash
              peek2 = peek + 1
              break unless peek2 < buffer.length && buffer[peek2].is_a?(Array)

              next_name, next_args = buffer[peek2]
              break unless next_args.empty?

              hyphenated = "#{hyphenated}-#{next_name}"
              child = node.find_subcommand(hyphenated)
              if child
                name = hyphenated
                i = peek2 # will be incremented below
                break
              end
              peek = peek2 + 1
            end
          end

          break unless child

          commands << name
          node = child
          i += 1

          # Consume :dash separated subcommand parts (e.g. cluster-access-key)
          while i < buffer.length && buffer[i] == :dash
            next_i = i + 1
            break unless next_i < buffer.length && buffer[next_i].is_a?(Array)

            next_name, next_args = buffer[next_i]
            break unless next_args.empty?

            hyphenated = "#{commands.last}-#{next_name}"
            child = node.find_subcommand(hyphenated)
            break unless child

            commands[-1] = hyphenated
            node = child
            i = next_i + 1

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
              if current_positional && !current_positional.end_with?('-') && !current_positional.end_with?('/')
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
              flag_name = name.tr('_', '-')
              prefix = name.length == 1 ? '-' : '--'

              if args == [true]
                flags << "#{prefix}#{flag_name}"
              else
                value = args.map(&:to_s).join(',')
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
