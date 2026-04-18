# frozen_string_literal: true

module Kube
  module CLI
    @commands = {}

    # Register a subcommand.
    #
    #   Kube::CLI.register("cluster", handler)
    #
    # +name+    - the subcommand name (String)
    # +handler+ - any object that responds to .call(argv)
    #             where argv is the remaining ARGV after the subcommand
    # +description+ - short one-line description for help output
    def self.register(name, handler, description: nil)
      @commands[name.to_s] = { handler: handler, description: description }
    end

    # Look up a registered subcommand handler by name.
    def self.lookup(name)
      entry = @commands[name.to_s]
      entry&.fetch(:handler)
    end

    # All registered command names.
    def self.commands
      @commands.dup
    end

    # Run the CLI. Parses the first argument as the subcommand,
    # passes the rest to the handler.
    def self.run(argv = ARGV)
      subcommand = argv.shift

      if subcommand.nil? || subcommand == "help" || subcommand == "--help" || subcommand == "-h"
        print_help
        return
      end

      handler = lookup(subcommand)

      if handler.nil?
        $stderr.puts "kube: unknown command '#{subcommand}'"
        $stderr.puts
        print_help($stderr)
        exit 1
      end

      handler.call(argv)
    end

    def self.print_help(io = $stdout)
      io.puts "Usage: kube <command> [args...]"
      io.puts
      io.puts "Commands:"

      max_width = @commands.keys.map(&:length).max || 0

      @commands.sort_by { |name, _| name }.each do |name, entry|
        if entry[:description]
          io.puts "  %-#{max_width}s  %s" % [name, entry[:description]]
        else
          io.puts "  #{name}"
        end
      end

      io.puts
      io.puts "Run 'kube <command> --help' for more information on a command."
    end
  end
end
