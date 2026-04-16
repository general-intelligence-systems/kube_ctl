# frozen_string_literal: true

require "test_helper"

class KubeCtlTest < Minitest::Test
  def test_version
    refute_nil KubeCtl::VERSION
  end
end
