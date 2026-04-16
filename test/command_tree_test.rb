require "json"
require "test_helper"
require_relative "../lib/kube/ctl/command_tree"

class CommandTreeTest < Minitest::Test
  def setup
    data = JSON.parse(File.read(File.expand_path("../data/kubectl-command-tree-v1-minimal.json", __dir__)))
    @tree = Kube::Ctl::CommandTree.new(data)
  end

  def test_matches_known_command_chain_with_resource_segments
    result = @tree.evaluate(Kube.ctl { get.deployment.v1.apps })

    assert_equal ["get"], result.commands
    assert_equal ["deployment.v1.apps"], result.resources
    assert_predicate result, :valid
    assert_equal "get deployment.v1.apps", result.to_s
  end

  def test_resource_with_dots_and_unknown_names
    result = @tree.evaluate(Kube.ctl { get.cronjobs.v1.batch") })

    assert_equal ["get"], result.commands
    assert_equal ["cronjobs.v1.batch"], result.resources
    assert_predicate result, :valid
  end

  def test_unknown_root_command_returns_error
    result = @tree.evaluate(Kube.ctl { definitely_missing })

    refute_predicate result, :valid
    assert_equal [], result.commands
    assert_equal ["definitely_missing"], result.resources
    assert_equal "invalid command start: `definitely_missing`", result.errors.first
  end

  def test_invalid_resource_is_reported_when_dataset_enabled
    dataset = ["pod.v1/apps"]
    result = @tree.evaluate(Kube.ctl { get.pod.v1.apps }, resource_dataset: dataset)

    refute_predicate result, :valid
    assert_equal ["get"], result.commands
    assert_equal ["pod.v1.apps"], result.resources
    assert_equal "unknown resource: `pod.v1.apps`", result.errors.first
  end

  def test_flag_like_tokens_are_kept_separate
    result = @tree.evaluate(Kube.ctl { get.deployment/v1.output("yaml") })

    assert_equal ["get"], result.commands
    assert_equal ["deployment/v1"], result.resources
    assert_equal ["--output yaml"], result.flags
    assert_predicate result, :valid
    assert_equal "get v1/apps -o yaml", result.to_s
  end

  def test_method_with_arg_becomes_long_flag_after_command
    result = @tree.evaluate(Kube.ctl { get.deployment.v1.apps.namespace("default") })

    assert_equal ["get"], result.commands
    assert_equal ["deployment.v1.apps"], result.resources
    assert_equal ["--namespace default"], result.flags
    assert_predicate result, :valid
    assert_equal "get deployment.v1.apps --namespace default", result.to_s
  end

  def test_hyphenated_node_resource_with_patch_file_flag
    result = @tree.evaluate(Kube.ctl { patch.node.k8s-node-1.patch_file("file.yaml") })

    assert_equal ["patch"], result.commands
    assert_equal ["node.k8s-node-1"], result.resources
    assert_equal ["--patch-file file.yaml"], result.flags
    assert_predicate result, :valid
    assert_equal "patch node.k8s-node-1 --patch-file file.yaml", result.to_s
  end

  def test_call_with_space_node_resource_and_patch_file_flag
    result = @tree.evaluate(Kube.ctl.patch.("node k8s-node-1").patch_file("file.yaml"))

    assert_equal ["patch"], result.commands
    assert_equal ["node k8s-node-1"], result.resources
    assert_equal ["--patch-file file.yaml"], result.flags
    assert_predicate result, :valid
    assert_equal "patch node k8s-node-1 --patch-file file.yaml", result.to_s
  end

  def test_rollout_restart_deployment_selector
    result = @tree.evaluate(Kube.ctl { rollout.restart.deployment.selector("app=nginx") })

    assert_equal ["rollout", "restart"], result.commands
    assert_equal ["deployment"], result.resources
    assert_equal ["--selector app=nginx"], result.flags
    assert_predicate result, :valid
    assert_equal "rollout restart deployment --selector app=nginx", result.to_s
  end

  def test_apply_file_all_prune_allowlist
    result = @tree.evaluate(Kube.ctl { apply.file("manifest.yaml").all(true).prune_allowlist("core/v1/ConfigMap") })

    assert_equal ["apply"], result.commands
    assert_equal [], result.resources
    assert_equal ["--file manifest.yaml", "--all true", "--prune-allowlist core/v1/ConfigMap"], result.flags
    assert_predicate result, :valid
    assert_equal "apply --file manifest.yaml --all true --prune-allowlist core/v1/ConfigMap", result.to_s
  end

  def test_rollout_undo_deployment_abc
    result = @tree.evaluate(Kube.ctl { rollout.undo.deployment/abc })

    assert_equal ["rollout", "undo"], result.commands
    assert_equal ["deployment/abc"], result.resources
    assert_equal [], result.flags
    assert_predicate result, :valid
    assert_equal "rollout undo deployment/abc", result.to_s
  end
end
