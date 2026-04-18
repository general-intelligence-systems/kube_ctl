# frozen_string_literal: true

require "yaml"

module Kube
  module Ctl
    module CommandTree
      def self.load(path)
        raw = YAML.load_file(path)
        root = CommandTree::Node.new(name: 'kubectl')

        raw.fetch('toplevelcommandgroups', []).each do |group|
          group.fetch('commands', []).each do |entry|
            main = entry['maincommand']
            next unless main
            node = build_node(main)
            (entry['subcommands'] || []).each do |sub|
              node.add_subcommand(build_node(sub))
            end
            root.add_subcommand(node)
          end
        end
        root
      end

      def self.build_node(h)
        CommandTree::Node.new(
          name: h['name'],
          options: h['options'] || [],
          inherited_options: h['inherited_options'] || [],
          usage: h['usage']
        )
      end
    end
  end
end
