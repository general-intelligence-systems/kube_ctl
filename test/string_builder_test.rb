# frozen_string_literal: true

require "test_helper"

class StringBuilderTest < Minitest::Test
  def test_get
    result = Kube.ctl { get }
    assert_equal [["get", []]], result.buffer
  end

  def test_get_deployment
    result = Kube.ctl { get.deployment }
    assert_equal [["get", []], ["deployment", []]], result.buffer
  end

  def test_get_deployment_slash_v1
    result = Kube.ctl { get.deployment / v1 }
    expected = [["get", []], ["deployment", []], ["v1", []], :slash]
    assert_equal expected, result.buffer
  end

  def test_get_deployment_slash_v1_slash_app
    result = Kube.ctl { get.deployment / v1 / app }
    expected = [["get", []], ["deployment", []], ["v1", []], :slash, ["app", []], :slash]
    assert_equal expected, result.buffer
  end

  def test_get_deployment_slash_v1_slash_app_namespace
    result = Kube.ctl { get.deployment / v1 / app .namespace("default") }
    expected = [
      ["get", []], ["deployment", []], ["v1", []], :slash,
      ["app", []], ["namespace", ["default"]], :slash
    ]
    assert_equal expected, result.buffer
  end

  def test_blockless_chaining
    result = Kube.ctl.get.deployment
    assert_equal [["get", []], ["deployment", []]], result.buffer
  end

  def test_call_with_string_arg
    result = Kube.ctl.get.("deployment/v1/apps")
    assert_equal [["get", []], ["deployment/v1/apps", []]], result.buffer
  end

  def test_call_with_string_arg_then_chain
    result = Kube.ctl.get.("deployment/v1/apps").all
    assert_equal [["get", []], ["deployment/v1/apps", []], ["all", []]], result.buffer
  end

  def test_call_with_no_args_raises
    assert_raises(ArgumentError) do
      Kube.ctl.get.call
    end
  end
end
