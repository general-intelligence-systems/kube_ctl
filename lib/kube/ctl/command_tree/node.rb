module Kube
  module Ctl
    class CommandTree
      class Node
        attr_reader :name, :options, :inherited_options, :subcommands, :usage

        def initialize(name:, options: [], inherited_options: [], usage: nil)
          @name = name
          @options = index_flags(options)
          @inherited_options = index_flags(inherited_options)
          @subcommands = {}
          @usage = usage
        end

        def add_subcommand(node)
          @subcommands[node.name] = node
        end

        def find_subcommand(token)
          @subcommands[token]
        end

        # Merge own + inherited flags. Inherited is "inherited from ancestors",
        # in kubectl's YAML it's already flattened per command.
        def known_flags
          @options.merge(@inherited_options)
        end

        private

        def index_flags(list)
          (list || []).each_with_object({}) do |f, h|
            h["--#{f['name']}"] = f
            h["-#{f['shorthand']}"] = f if f['shorthand']
          end
        end
      end
    end
  end
end
