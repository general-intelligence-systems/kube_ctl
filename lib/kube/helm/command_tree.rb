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

if __FILE__ == $0
  require "bundler/setup"
  require "minitest/autorun"
  require "yaml"
  require "kube/ctl"

  module Kube
    module Ctl
      def self.run(args) = args
    end

    module Helm
      def self.run(args) = args
    end

    module VCluster
      def self.run(args) = args
    end
  end

  class HelmCommandTreeTest < Minitest::Test
    def setup
      data = YAML.load_file(File.expand_path("../../../data/helm.yaml", __dir__))
      @tree = Kube::Helm::CommandTree.new(data)
    end

    def assert_results(result, final = nil, commands:, positional:, flags: nil, errors: nil, valid: true)
      assert_equal commands, result.commands, "commands mismatch"
      assert_equal positional, result.positional, "positional mismatch"
      if valid
        assert result.valid, "expected valid but got errors: #{result.errors}"
      else
        refute result.valid, "expected invalid"
      end

      assert_equal flags, result.flags, "flags mismatch" unless flags.nil?
      assert_equal errors, result.errors, "errors mismatch" unless errors.nil?
      assert_equal final, result.to_s, "to_s mismatch" unless final.nil?
    end

    # --- Basic commands ---

    def test_install_chart_with_release_name
      result = @tree.evaluate(Kube.helm { install.my_release.("bitnami/nginx") })

      assert_results(
        result,
        "install my_release bitnami/nginx",
        commands: ["install"],
        positional: ["my_release", "bitnami/nginx"],
        flags: [],
        valid: true
      )
    end

    def test_install_chart_with_namespace_flag
      result = @tree.evaluate(Kube.helm { install.my_release.("bitnami/nginx").namespace("default") })

      assert_results(
        result,
        "install my_release bitnami/nginx --namespace default",
        commands: ["install"],
        positional: ["my_release", "bitnami/nginx"],
        flags: ["--namespace default"],
        valid: true
      )
    end

    def test_uninstall_release
      result = @tree.evaluate(Kube.helm { uninstall.my_release })

      assert_results(
        result,
        "uninstall my_release",
        commands: ["uninstall"],
        positional: ["my_release"],
        flags: [],
        valid: true
      )
    end

    def test_list_releases
      result = @tree.evaluate(Kube.helm { list })

      assert_results(
        result,
        "list",
        commands: ["list"],
        positional: [],
        flags: [],
        valid: true
      )
    end

    def test_list_all_namespaces
      result = @tree.evaluate(Kube.helm { list.all_namespaces(true) })

      assert_results(
        result,
        "list --all-namespaces",
        commands: ["list"],
        positional: [],
        flags: ["--all-namespaces"],
        valid: true
      )
    end

    # --- Subcommands ---

    def test_repo_add
      result = @tree.evaluate(Kube.helm { repo.add.("bitnami").("https://charts.bitnami.com/bitnami") })

      assert_results(
        result,
        "repo add bitnami https://charts.bitnami.com/bitnami",
        commands: ["repo", "add"],
        positional: ["bitnami", "https://charts.bitnami.com/bitnami"],
        flags: [],
        valid: true
      )
    end

    def test_repo_list
      result = @tree.evaluate(Kube.helm { repo.list })

      assert_results(
        result,
        "repo list",
        commands: ["repo", "list"],
        positional: [],
        flags: [],
        valid: true
      )
    end

    def test_repo_update
      result = @tree.evaluate(Kube.helm { repo.update })

      assert_results(
        result,
        "repo update",
        commands: ["repo", "update"],
        positional: [],
        flags: [],
        valid: true
      )
    end

    def test_repo_remove
      result = @tree.evaluate(Kube.helm { repo.remove.("bitnami") })

      assert_results(
        result,
        "repo remove bitnami",
        commands: ["repo", "remove"],
        positional: ["bitnami"],
        flags: [],
        valid: true
      )
    end

    # --- Deep subcommands ---

    def test_get_values_with_output_flag
      result = @tree.evaluate(Kube.helm { get.values.my_release.output("json") })

      assert_results(
        result,
        "get values my_release --output json",
        commands: ["get", "values"],
        positional: ["my_release"],
        flags: ["--output json"],
        valid: true
      )
    end

    def test_get_manifest
      result = @tree.evaluate(Kube.helm { get.manifest.my_release })

      assert_results(
        result,
        "get manifest my_release",
        commands: ["get", "manifest"],
        positional: ["my_release"],
        flags: [],
        valid: true
      )
    end

    def test_get_all_with_revision
      result = @tree.evaluate(Kube.helm { get.all.my_release.revision(3) })

      assert_results(
        result,
        "get all my_release --revision 3",
        commands: ["get", "all"],
        positional: ["my_release"],
        flags: ["--revision 3"],
        valid: true
      )
    end

    def test_get_hooks
      result = @tree.evaluate(Kube.helm { get.hooks.my_release })

      assert_results(
        result,
        "get hooks my_release",
        commands: ["get", "hooks"],
        positional: ["my_release"],
        flags: [],
        valid: true
      )
    end

    # --- Upgrade ---

    def test_upgrade_with_install_flag
      result = @tree.evaluate(Kube.helm { upgrade.install(true).my_release.("bitnami/nginx") })

      assert_results(
        result,
        "upgrade my_release bitnami/nginx --install",
        commands: ["upgrade"],
        positional: ["my_release", "bitnami/nginx"],
        flags: ["--install"],
        valid: true
      )
    end

    def test_upgrade_with_set_flag
      result = @tree.evaluate(Kube.helm { upgrade.my_release.("bitnami/nginx").set("image.tag=latest") })

      assert_results(
        result,
        "upgrade my_release bitnami/nginx --set image.tag=latest",
        commands: ["upgrade"],
        positional: ["my_release", "bitnami/nginx"],
        flags: ["--set image.tag=latest"],
        valid: true
      )
    end

    def test_upgrade_with_values_file
      result = @tree.evaluate(Kube.helm { upgrade.my_release.("bitnami/nginx").f("values.yaml") })

      assert_results(
        result,
        "upgrade my_release bitnami/nginx -f values.yaml",
        commands: ["upgrade"],
        positional: ["my_release", "bitnami/nginx"],
        flags: ["-f values.yaml"],
        valid: true
      )
    end

    # --- Dependency subcommands ---

    def test_dependency_update
      result = @tree.evaluate(Kube.helm { dependency.update.("./my-chart") })

      assert_results(
        result,
        "dependency update ./my-chart",
        commands: ["dependency", "update"],
        positional: ["./my-chart"],
        flags: [],
        valid: true
      )
    end

    def test_dependency_build
      result = @tree.evaluate(Kube.helm { dependency.build.("./my-chart") })

      assert_results(
        result,
        "dependency build ./my-chart",
        commands: ["dependency", "build"],
        positional: ["./my-chart"],
        flags: [],
        valid: true
      )
    end

    def test_dependency_list
      result = @tree.evaluate(Kube.helm { dependency.list.("./my-chart") })

      assert_results(
        result,
        "dependency list ./my-chart",
        commands: ["dependency", "list"],
        positional: ["./my-chart"],
        flags: [],
        valid: true
      )
    end

    # --- Template & Show ---

    def test_template_with_namespace
      result = @tree.evaluate(Kube.helm { template.my_release.("bitnami/nginx").namespace("prod") })

      assert_results(
        result,
        "template my_release bitnami/nginx --namespace prod",
        commands: ["template"],
        positional: ["my_release", "bitnami/nginx"],
        flags: ["--namespace prod"],
        valid: true
      )
    end

    def test_show_values
      result = @tree.evaluate(Kube.helm { show.values.("bitnami/nginx") })

      assert_results(
        result,
        "show values bitnami/nginx",
        commands: ["show", "values"],
        positional: ["bitnami/nginx"],
        flags: [],
        valid: true
      )
    end

    def test_show_chart
      result = @tree.evaluate(Kube.helm { show.chart.("bitnami/nginx") })

      assert_results(
        result,
        "show chart bitnami/nginx",
        commands: ["show", "chart"],
        positional: ["bitnami/nginx"],
        flags: [],
        valid: true
      )
    end

    # --- Search ---

    def test_search_repo
      result = @tree.evaluate(Kube.helm { search.repo.("nginx") })

      assert_results(
        result,
        "search repo nginx",
        commands: ["search", "repo"],
        positional: ["nginx"],
        flags: [],
        valid: true
      )
    end

    def test_search_hub
      result = @tree.evaluate(Kube.helm { search.hub.("nginx") })

      assert_results(
        result,
        "search hub nginx",
        commands: ["search", "hub"],
        positional: ["nginx"],
        flags: [],
        valid: true
      )
    end

    # --- Other commands ---

    def test_rollback_with_revision
      result = @tree.evaluate(Kube.helm { rollback.my_release.("2") })

      assert_results(
        result,
        "rollback my_release 2",
        commands: ["rollback"],
        positional: ["my_release", "2"],
        flags: [],
        valid: true
      )
    end

    def test_history
      result = @tree.evaluate(Kube.helm { history.my_release })

      assert_results(
        result,
        "history my_release",
        commands: ["history"],
        positional: ["my_release"],
        flags: [],
        valid: true
      )
    end

    def test_status_with_output
      result = @tree.evaluate(Kube.helm { status.my_release.o(:json) })

      assert_results(
        result,
        "status my_release -o json",
        commands: ["status"],
        positional: ["my_release"],
        flags: ["-o json"],
        valid: true
      )
    end

    def test_env
      result = @tree.evaluate(Kube.helm { env })

      assert_results(
        result,
        "env",
        commands: ["env"],
        positional: [],
        flags: [],
        valid: true
      )
    end

    def test_create_chart
      result = @tree.evaluate(Kube.helm { create.my-chart })

      assert_results(
        result,
        "create my-chart",
        commands: ["create"],
        positional: ["my-chart"],
        flags: [],
        valid: true
      )
    end

    def test_lint_chart
      result = @tree.evaluate(Kube.helm { lint.("./my-chart") })

      assert_results(
        result,
        "lint ./my-chart",
        commands: ["lint"],
        positional: ["./my-chart"],
        flags: [],
        valid: true
      )
    end

    def test_package_chart
      result = @tree.evaluate(Kube.helm { package.("./my-chart") })

      assert_results(
        result,
        "package ./my-chart",
        commands: ["package"],
        positional: ["./my-chart"],
        flags: [],
        valid: true
      )
    end

    # --- Plugin subcommands ---

    def test_plugin_list
      result = @tree.evaluate(Kube.helm { plugin.list })

      assert_results(
        result,
        "plugin list",
        commands: ["plugin", "list"],
        positional: [],
        flags: [],
        valid: true
      )
    end

    def test_plugin_install
      result = @tree.evaluate(Kube.helm { plugin.install.("https://example.com/plugin.git") })

      assert_results(
        result,
        "plugin install https://example.com/plugin.git",
        commands: ["plugin", "install"],
        positional: ["https://example.com/plugin.git"],
        flags: [],
        valid: true
      )
    end

    # --- Registry subcommands ---

    def test_registry_login
      result = @tree.evaluate(Kube.helm { registry.login.("localhost:5000").username("admin").password("secret") })

      assert_results(
        result,
        "registry login localhost:5000 --username admin --password secret",
        commands: ["registry", "login"],
        positional: ["localhost:5000"],
        flags: ["--username admin", "--password secret"],
        valid: true
      )
    end

    # --- Error cases ---

    def test_unknown_command_returns_error
      result = @tree.evaluate(Kube.helm { definitely_missing })

      assert_results(
        result,
        commands: [],
        positional: ["definitely_missing"],
        errors: ["invalid command start: `definitely_missing`"],
        valid: false
      )
    end

    # --- Complex flag combinations ---

    def test_install_with_multiple_flags
      result = @tree.evaluate(Kube.helm {
        install.my_release.("bitnami/nginx")
          .namespace("prod")
          .create_namespace(true)
          .wait(true)
          .timeout("5m0s")
      })

      assert_results(
        result,
        "install my_release bitnami/nginx --namespace prod --create-namespace --wait --timeout 5m0s",
        commands: ["install"],
        positional: ["my_release", "bitnami/nginx"],
        flags: ["--namespace prod", "--create-namespace", "--wait", "--timeout 5m0s"],
        valid: true
      )
    end

    def test_upgrade_install_with_values_and_set
      result = @tree.evaluate(Kube.helm {
        upgrade.install(true).my_release.("bitnami/nginx")
          .f("values.yaml")
          .set("replicaCount=3")
          .namespace("prod")
      })

      assert_results(
        result,
        "upgrade my_release bitnami/nginx --install -f values.yaml --set replicaCount=3 --namespace prod",
        commands: ["upgrade"],
        positional: ["my_release", "bitnami/nginx"],
        flags: ["--install", "-f values.yaml", "--set replicaCount=3", "--namespace prod"],
        valid: true
      )
    end

    # --- to_s output ---

    def test_to_s_produces_valid_command_string
      result = @tree.evaluate(Kube.helm { install.my_release.("bitnami/nginx").namespace("default").wait(true) })
      assert_equal "install my_release bitnami/nginx --namespace default --wait", result.to_s
    end
  end
end
