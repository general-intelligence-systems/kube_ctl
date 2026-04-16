# frozen_string_literal: true

require "test_helper"

class StringBuilderTest < Minitest::Test
  def assert_buffer(result, expected)
    assert_equal expected, result.buffer
  end

  def test_get
    result = Kube.ctl { get }
    assert_buffer(result, [["get", []]])
  end

  def test_get_deployment
    result = Kube.ctl { get.deployment }
    assert_buffer(result, [["get", []], ["deployment", []]])
  end

  def test_get_deployment_slash_v1
    result = Kube.ctl { get.deployment/v1 }
    assert_buffer(result, [["get", []], ["deployment", []], ["v1", []], :slash])
  end

  def test_get_deployment_slash_v1_slash_app
    result = Kube.ctl { get.deployment/v1/app }
    assert_buffer(result, [["get", []], ["deployment", []], ["v1", []], :slash, ["app", []], :slash])
  end

  def test_get_deployment_slash_v1_slash_app_namespace
    result = Kube.ctl { get.deployment/v1/app.namespace("default") }
    assert_buffer(
      result,
      [
        ["get", []], ["deployment", []], ["v1", []], :slash,
        ["app", []], ["namespace", ["default"]], :slash
      ]
    )
  end

  def test_dash_operator_marks_dash_token
    result = Kube.ctl { get.node.k8s-node }
    assert_buffer(result, [["get", []], ["node", []], ["k8s", []], ["node", []], :dash])
  end

  def test_blockless_chaining
    result = Kube.ctl.get.deployment
    assert_buffer(result, [["get", []], ["deployment", []]])
  end

  def test_call_with_string_arg
    result = Kube.ctl.get.("deployment/v1/apps")
    assert_buffer(result, [["get", []], ["deployment/v1/apps", []]])
  end

  def test_call_with_string_arg_then_chain
    result = Kube.ctl.get.("deployment/v1/apps").all
    assert_buffer(result, [["get", []], ["deployment/v1/apps", []], ["all", []]])
  end

  def test_call_with_no_args_raises
    assert_raises(ArgumentError) do
      Kube.ctl.get.()
    end
  end
end
