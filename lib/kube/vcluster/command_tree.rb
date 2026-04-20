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

  class VClusterCommandTreeTest < Minitest::Test
    def setup
      data = YAML.load_file(File.expand_path('../../../data/vcluster.yaml', __dir__))
      @tree = Kube::VCluster::CommandTree.new(data)
    end

    def assert_results(result, final = nil, commands:, positional:, flags: nil, errors: nil, valid: true)
      assert_equal commands, result.commands, 'commands mismatch'
      assert_equal positional, result.positional, 'positional mismatch'
      if valid
        assert result.valid, "expected valid but got errors: #{result.errors}"
      else
        refute result.valid, 'expected invalid'
      end

      assert_equal flags, result.flags, 'flags mismatch' unless flags.nil?
      assert_equal errors, result.errors, 'errors mismatch' unless errors.nil?
      assert_equal final, result.to_s, 'to_s mismatch' unless final.nil?
    end

    # ===================================================================
    # Core lifecycle
    # ===================================================================

    # vcluster create test --namespace test
    def test_create_with_namespace
      result = @tree.evaluate(Kube.vcluster { create.test.namespace('test') })
      assert_results(
        result,
        'create test --namespace test',
        commands: ['create'],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    # vcluster connect test --namespace test
    def test_connect_with_namespace
      result = @tree.evaluate(Kube.vcluster { connect.test.namespace('test') })
      assert_results(
        result,
        'connect test --namespace test',
        commands: ['connect'],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    # vcluster delete test --namespace test
    def test_delete_with_namespace
      result = @tree.evaluate(Kube.vcluster { delete.test.namespace('test') })
      assert_results(
        result,
        'delete test --namespace test',
        commands: ['delete'],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    # vcluster list
    def test_list
      result = @tree.evaluate(Kube.vcluster { list })
      assert_results(
        result,
        'list',
        commands: ['list'],
        positional: [],
        flags: [],
        valid: true
      )
    end

    # vcluster list --output json
    def test_list_output_json
      result = @tree.evaluate(Kube.vcluster { list.output('json') })
      assert_results(
        result,
        'list --output json',
        commands: ['list'],
        positional: [],
        flags: ['--output json'],
        valid: true
      )
    end

    # vcluster list --namespace test
    def test_list_namespace
      result = @tree.evaluate(Kube.vcluster { list.namespace('test') })
      assert_results(
        result,
        'list --namespace test',
        commands: ['list'],
        positional: [],
        flags: ['--namespace test'],
        valid: true
      )
    end

    # vcluster pause test --namespace test
    def test_pause_with_namespace
      result = @tree.evaluate(Kube.vcluster { pause.test.namespace('test') })
      assert_results(
        result,
        'pause test --namespace test',
        commands: ['pause'],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    # vcluster resume test --namespace test
    def test_resume_with_namespace
      result = @tree.evaluate(Kube.vcluster { resume.test.namespace('test') })
      assert_results(
        result,
        'resume test --namespace test',
        commands: ['resume'],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    # vcluster disconnect
    def test_disconnect
      result = @tree.evaluate(Kube.vcluster { disconnect })
      assert_results(
        result,
        'disconnect',
        commands: ['disconnect'],
        positional: [],
        flags: [],
        valid: true
      )
    end

    # vcluster describe test
    def test_describe
      result = @tree.evaluate(Kube.vcluster { describe.test })
      assert_results(
        result,
        'describe test',
        commands: ['describe'],
        positional: ['test'],
        flags: [],
        valid: true
      )
    end

    # vcluster ui
    def test_ui
      result = @tree.evaluate(Kube.vcluster { ui })
      assert_results(
        result,
        'ui',
        commands: ['ui'],
        positional: [],
        flags: [],
        valid: true
      )
    end

    # vcluster logout
    def test_logout
      result = @tree.evaluate(Kube.vcluster { logout })
      assert_results(
        result,
        'logout',
        commands: ['logout'],
        positional: [],
        flags: [],
        valid: true
      )
    end

    # ===================================================================
    # Debug
    # ===================================================================

    # vcluster debug shell my-vcluster --target=syncer
    def test_debug_shell_with_target
      result = @tree.evaluate(Kube.vcluster { debug.shell.my - vcluster.target('syncer') })
      assert_results(
        result,
        'debug shell my-vcluster --target syncer',
        commands: %w[debug shell],
        positional: ['my-vcluster'],
        flags: ['--target syncer'],
        valid: true
      )
    end

    # ===================================================================
    # Snapshot / Restore
    # ===================================================================

    # vcluster snapshot create my-vcluster oci://...
    def test_snapshot_create_oci
      result = @tree.evaluate(Kube.vcluster do
        snapshot.create.my - vcluster.call('oci://ghcr.io/my-user/my-repo:my-tag')
      end)
      assert_results(
        result,
        'snapshot create my-vcluster oci://ghcr.io/my-user/my-repo:my-tag',
        commands: %w[snapshot create],
        positional: ['my-vcluster', 'oci://ghcr.io/my-user/my-repo:my-tag'],
        flags: [],
        valid: true
      )
    end

    # vcluster restore my-vcluster s3://my-bucket/my-bucket-key
    def test_restore_s3
      result = @tree.evaluate(Kube.vcluster { restore.my - vcluster.call('s3://my-bucket/my-bucket-key') })
      assert_results(
        result,
        'restore my-vcluster s3://my-bucket/my-bucket-key',
        commands: ['restore'],
        positional: ['my-vcluster', 's3://my-bucket/my-bucket-key'],
        flags: [],
        valid: true
      )
    end

    # ===================================================================
    # Platform — login/logout
    # ===================================================================

    # vcluster platform login https://my-vcluster-platform.com
    def test_platform_login
      result = @tree.evaluate(Kube.vcluster { platform.login.call('https://my-vcluster-platform.com') })
      assert_results(
        result,
        'platform login https://my-vcluster-platform.com',
        commands: %w[platform login],
        positional: ['https://my-vcluster-platform.com'],
        flags: [],
        valid: true
      )
    end

    # vcluster platform login https://... --access-key myaccesskey
    def test_platform_login_with_access_key
      result = @tree.evaluate(Kube.vcluster do
        platform.login.call('https://my-vcluster-platform.com').access_key('myaccesskey')
      end)
      assert_results(
        result,
        'platform login https://my-vcluster-platform.com --access-key myaccesskey',
        commands: %w[platform login],
        positional: ['https://my-vcluster-platform.com'],
        flags: ['--access-key myaccesskey'],
        valid: true
      )
    end

    # vcluster platform logout
    def test_platform_logout
      result = @tree.evaluate(Kube.vcluster { platform.logout })
      assert_results(
        result,
        'platform logout',
        commands: %w[platform logout],
        positional: [],
        flags: [],
        valid: true
      )
    end

    # ===================================================================
    # Platform — list
    # ===================================================================

    def test_platform_list_clusters
      result = @tree.evaluate(Kube.vcluster { platform.list.clusters })
      assert_results(result, 'platform list clusters', commands: %w[platform list clusters], positional: [], flags: [], valid: true)
    end

    def test_platform_list_vclusters
      result = @tree.evaluate(Kube.vcluster { platform.list.vclusters })
      assert_results(result, 'platform list vclusters', commands: %w[platform list vclusters], positional: [], flags: [], valid: true)
    end

    def test_platform_list_namespaces
      result = @tree.evaluate(Kube.vcluster { platform.list.namespaces })
      assert_results(result, 'platform list namespaces', commands: %w[platform list namespaces], positional: [], flags: [], valid: true)
    end

    def test_platform_list_projects
      result = @tree.evaluate(Kube.vcluster { platform.list.projects })
      assert_results(result, 'platform list projects', commands: %w[platform list projects], positional: [], flags: [], valid: true)
    end

    def test_platform_list_secrets
      result = @tree.evaluate(Kube.vcluster { platform.list.secrets })
      assert_results(result, 'platform list secrets', commands: %w[platform list secrets], positional: [], flags: [], valid: true)
    end

    def test_platform_list_teams
      result = @tree.evaluate(Kube.vcluster { platform.list.teams })
      assert_results(result, 'platform list teams', commands: %w[platform list teams], positional: [], flags: [], valid: true)
    end

    # ===================================================================
    # Platform — get
    # ===================================================================

    def test_platform_get_current_user
      result = @tree.evaluate(Kube.vcluster { platform.get.current - user })
      assert_results(result, 'platform get current-user', commands: %w[platform get current-user], positional: [], flags: [], valid: true)
    end

    def test_platform_get_secret_with_project
      result = @tree.evaluate(Kube.vcluster { platform.get.secret.call('test-secret.key').project('myproject') })
      assert_results(
        result,
        'platform get secret test-secret.key --project myproject',
        commands: %w[platform get secret],
        positional: ['test-secret.key'],
        flags: ['--project myproject'],
        valid: true
      )
    end

    # ===================================================================
    # Platform — create
    # ===================================================================

    def test_platform_create_vcluster
      result = @tree.evaluate(Kube.vcluster { platform.create.vcluster.test.namespace('test') })
      assert_results(
        result,
        'platform create vcluster test --namespace test',
        commands: %w[platform create vcluster],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    def test_platform_create_namespace_with_project_and_team
      result = @tree.evaluate(Kube.vcluster { platform.create.namespace.myspace.project('myproject').team('myteam') })
      assert_results(
        result,
        'platform create namespace myspace --project myproject --team myteam',
        commands: %w[platform create namespace],
        positional: ['myspace'],
        flags: ['--project myproject', '--team myteam'],
        valid: true
      )
    end

    def test_platform_create_accesskey_in_cluster
      result = @tree.evaluate(Kube.vcluster { platform.create.accesskey.test.in_cluster(true).user('admin') })
      assert_results(
        result,
        'platform create accesskey test --in-cluster --user admin',
        commands: %w[platform create accesskey],
        positional: ['test'],
        flags: ['--in-cluster', '--user admin'],
        valid: true
      )
    end

    # ===================================================================
    # Platform — delete
    # ===================================================================

    def test_platform_delete_namespace_with_project
      result = @tree.evaluate(Kube.vcluster { platform.delete.namespace.myspace.project('myproject') })
      assert_results(
        result,
        'platform delete namespace myspace --project myproject',
        commands: %w[platform delete namespace],
        positional: ['myspace'],
        flags: ['--project myproject'],
        valid: true
      )
    end

    # ===================================================================
    # Platform — connect
    # ===================================================================

    def test_platform_connect_cluster
      result = @tree.evaluate(Kube.vcluster { platform.connect.cluster.mycluster })
      assert_results(result, 'platform connect cluster mycluster', commands: %w[platform connect cluster], positional: ['mycluster'], flags: [], valid: true)
    end

    def test_platform_connect_management
      result = @tree.evaluate(Kube.vcluster { platform.connect.management })
      assert_results(result, 'platform connect management', commands: %w[platform connect management], positional: [], flags: [], valid: true)
    end

    def test_platform_connect_namespace_with_project
      result = @tree.evaluate(Kube.vcluster { platform.connect.namespace.myspace.project('myproject') })
      assert_results(
        result,
        'platform connect namespace myspace --project myproject',
        commands: %w[platform connect namespace],
        positional: ['myspace'],
        flags: ['--project myproject'],
        valid: true
      )
    end

    def test_platform_connect_vcluster
      result = @tree.evaluate(Kube.vcluster { platform.connect.vcluster.test.namespace('test') })
      assert_results(
        result,
        'platform connect vcluster test --namespace test',
        commands: %w[platform connect vcluster],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    # ===================================================================
    # Platform — share
    # ===================================================================

    def test_platform_share_namespace_with_project_and_user
      result = @tree.evaluate(Kube.vcluster { platform.share.namespace.myspace.project('myproject').user('admin') })
      assert_results(
        result,
        'platform share namespace myspace --project myproject --user admin',
        commands: %w[platform share namespace],
        positional: ['myspace'],
        flags: ['--project myproject', '--user admin'],
        valid: true
      )
    end

    def test_platform_share_vcluster_with_project_and_user
      result = @tree.evaluate(Kube.vcluster { platform.share.vcluster.myvcluster.project('myproject').user('admin') })
      assert_results(
        result,
        'platform share vcluster myvcluster --project myproject --user admin',
        commands: %w[platform share vcluster],
        positional: ['myvcluster'],
        flags: ['--project myproject', '--user admin'],
        valid: true
      )
    end

    # ===================================================================
    # Platform — sleep/wakeup
    # ===================================================================

    def test_platform_sleep_vcluster
      result = @tree.evaluate(Kube.vcluster { platform.sleep.vcluster.test.namespace('test') })
      assert_results(
        result,
        'platform sleep vcluster test --namespace test',
        commands: %w[platform sleep vcluster],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    def test_platform_wakeup_vcluster
      result = @tree.evaluate(Kube.vcluster { platform.wakeup.vcluster.test.namespace('test') })
      assert_results(
        result,
        'platform wakeup vcluster test --namespace test',
        commands: %w[platform wakeup vcluster],
        positional: ['test'],
        flags: ['--namespace test'],
        valid: true
      )
    end

    def test_platform_wakeup_namespace_with_project
      result = @tree.evaluate(Kube.vcluster { platform.wakeup.namespace.myspace.project('myproject') })
      assert_results(
        result,
        'platform wakeup namespace myspace --project myproject',
        commands: %w[platform wakeup namespace],
        positional: ['myspace'],
        flags: ['--project myproject'],
        valid: true
      )
    end

    # ===================================================================
    # Platform — other
    # ===================================================================

    def test_platform_backup_management
      result = @tree.evaluate(Kube.vcluster { platform.backup.management })
      assert_results(result, 'platform backup management', commands: %w[platform backup management], positional: [], flags: [], valid: true)
    end

    def test_platform_reset_password_with_user
      result = @tree.evaluate(Kube.vcluster { platform.reset.password.user('admin') })
      assert_results(
        result,
        'platform reset password --user admin',
        commands: %w[platform reset password],
        positional: [],
        flags: ['--user admin'],
        valid: true
      )
    end

    def test_platform_add_cluster
      result = @tree.evaluate(Kube.vcluster { platform.add.cluster.my - cluster })
      assert_results(
        result,
        'platform add cluster my-cluster',
        commands: %w[platform add cluster],
        positional: ['my-cluster'],
        flags: [],
        valid: true
      )
    end

    # ===================================================================
    # Error case
    # ===================================================================

    def test_unknown_command_returns_error
      result = @tree.evaluate(Kube.vcluster { definitely_missing })
      assert_results(
        result,
        commands: [],
        positional: ['definitely_missing'],
        errors: ['invalid command start: `definitely_missing`'],
        valid: false
      )
    end
  end
end
