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

if __FILE__ == $0
  require "bundler/setup"
  require "minitest/autorun"
  require "yaml"
  require "kube/ctl"

  module Kube
    module Ctl
      def self.run(args) = args
    end

    module VCluster
      def self.run(args) = args
    end
  end

  class CommandTreeTest < Minitest::Test
    def setup
      data = YAML.load_file(File.expand_path("../../../data/kubectl.yaml", __dir__))
      @tree = Kube::Ctl::CommandTree.new(data)
    end

    def assert_results(result, final = nil, commands:, resources:, flags: nil, errors: nil, valid: true)
      assert_equal commands, result.commands
      assert_equal resources, result.resources
      if valid
        assert_predicate result, :valid
      else
        refute_predicate result, :valid
      end

      assert_equal flags, result.flags unless flags.nil?
      assert_equal errors, result.errors unless errors.nil?
      assert_equal final, result.to_s unless final.nil?
    end

    def test_matches_known_command_chain_with_resource_segments
      result = @tree.evaluate(Kube.ctl { get.deployment.v1.apps })

      assert_results(
        result,
        "get deployment.v1.apps",
        commands: ["get"],
        resources: ["deployment.v1.apps"],
        valid: true
      )
    end

    def test_resource_with_dots_and_unknown_names
      result = @tree.evaluate(Kube.ctl { get.cronjobs.v1.batch })

      assert_results(
        result,
        "get cronjobs.v1.batch",
        commands: ["get"],
        resources: ["cronjobs.v1.batch"],
        valid: true
      )
    end

    def test_unknown_root_command_returns_error
      result = @tree.evaluate(Kube.ctl { definitely_missing })

      assert_results(
        result,
        commands: [],
        resources: ["definitely_missing"],
        errors: ["invalid command start: `definitely_missing`"],
        valid: false
      )
    end

    def test_invalid_resource_is_reported_when_dataset_enabled
      dataset = ["pod.v1/apps"]
      result = @tree.evaluate(Kube.ctl { get.pod.v1.apps }, resource_dataset: dataset)

      assert_results(
        result,
        commands: ["get"],
        resources: ["pod.v1.apps"],
        errors: ["unknown resource: `pod.v1.apps`"],
        valid: false
      )
    end

    def test_flag_like_tokens_are_kept_separate
      result = @tree.evaluate(Kube.ctl { get.deployment/v1.output("yaml") })

      assert_results(
        result,
        "get deployment/v1 --output yaml",
        commands: ["get"],
        resources: ["deployment/v1"],
        flags: ["--output yaml"],
        valid: true
      )
    end

    def test_method_with_arg_becomes_long_flag_after_command
      result = @tree.evaluate(Kube.ctl { get.deployment.v1.apps.namespace("default") })

      assert_results(
        result,
        "get deployment.v1.apps --namespace default",
        commands: ["get"],
        resources: ["deployment.v1.apps"],
        flags: ["--namespace default"],
        valid: true
      )
    end

    def test_hyphenated_node_resource_with_patch_file_flag
      result = @tree.evaluate(Kube.ctl { patch.node.k8s-node-1.patch_file("file.yaml") })

      assert_results(
        result,
        "patch node.k8s-node-1 --patch-file file.yaml",
        commands: ["patch"],
        resources: ["node.k8s-node-1"],
        flags: ["--patch-file file.yaml"],
        valid: true
      )
    end

    def test_call_with_space_node_resource_and_patch_file_flag
      result = @tree.evaluate(Kube.ctl.patch.("node k8s-node-1").patch_file("file.yaml"))

      assert_results(
        result,
        "patch node k8s-node-1 --patch-file file.yaml",
        commands: ["patch"],
        resources: ["node k8s-node-1"],
        flags: ["--patch-file file.yaml"],
        valid: true
      )
    end

    def test_rollout_restart_deployment_selector
      result = @tree.evaluate(Kube.ctl { rollout.restart.deployment.selector("app=nginx") })

      assert_results(
        result,
        "rollout restart deployment --selector app=nginx",
        commands: ["rollout", "restart"],
        resources: ["deployment"],
        flags: ["--selector app=nginx"],
        valid: true
      )
    end

    def test_apply_file_all_prune_allowlist
      result = @tree.evaluate(Kube.ctl { apply.file("manifest.yaml").all(true).prune_allowlist("core/v1/ConfigMap") })

      assert_results(
        result,
        "apply --file manifest.yaml --all --prune-allowlist core/v1/ConfigMap",
        commands: ["apply"],
        resources: [],
        flags: ["--file manifest.yaml", "--all", "--prune-allowlist core/v1/ConfigMap"],
        valid: true
      )
    end

    def test_rollout_undo_deployment_abc
      result = @tree.evaluate(Kube.ctl { rollout.undo.deployment/abc })

      assert_results(
        result,
        "rollout undo deployment/abc",
        commands: ["rollout", "undo"],
        resources: ["deployment/abc"],
        flags: [],
        valid: true
      )
    end
  end
end
