require "yaml"
require "test_helper"
require_relative "../lib/kube/ctl/command_tree"

class CommandTreeTest < Minitest::Test
  def setup
    data = YAML.load_file(File.expand_path("../data/kubectl.yaml", __dir__))
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
