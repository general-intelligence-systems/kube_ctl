require 'shellwords'

module Kube
  module Ctl
    class CommandTree
      class Validator
        Result = Struct.new(:valid?, :resolved_path, :positional, :flags, :errors)

        def initialize(root)
          @root = root
        end

        def validate(input)
          tokens = Shellwords.split(input)
          errors = []
          path   = [@root]
          node   = @root

          # 1. Descend through subcommands (handles arbitrary depth)
          while tokens.any? && (child = node.find_subcommand(tokens.first))
            node = child
            path << node
            tokens.shift
          end

          # If we never moved past root, the first token wasn't a valid command
          if path.size == 1
            errors << "Unknown command: #{tokens.first.inspect}"
            return Result.new(false, path, [], {}, errors)
          end

          # 2. Parse remaining tokens as flags + positionals
          positional, flags, parse_errors = parse_args(tokens, node)
          errors.concat(parse_errors)

          Result.new(errors.empty?, path, positional, flags, errors)
        end

        private

        def parse_args(tokens, node)
          known = node.known_flags
          positional = []
          flags = {}
          errors = []

          i = 0
          while i < tokens.length
            tok = tokens[i]

            if tok.start_with?('--') || (tok.start_with?('-') && tok.length > 1 && tok != '-')
              key, inline_val = tok.split('=', 2)
              spec = known[key]

              unless spec
                errors << "Unknown flag for `#{node.name}`: #{key}"
                i += 1
                next
              end

              if boolean_flag?(spec)
                flags[spec['name']] = inline_val.nil? ? true : truthy?(inline_val)
                i += 1
              else
                value = inline_val || tokens[i + 1]
                if value.nil? || (inline_val.nil? && value.start_with?('-'))
                  errors << "Flag #{key} requires a value"
                  i += 1
                else
                  flags[spec['name']] = value
                  i += inline_val ? 1 : 2
                end
              end
            else
              positional << tok
              i += 1
            end
          end

          [positional, flags, errors]
        end

        def boolean_flag?(spec)
          dv = spec['default_value']
          dv == 'true' || dv == 'false'
        end

        def truthy?(v)
          %w[true 1 yes].include?(v.to_s.downcase)
        end
      end
    end
  end
end
