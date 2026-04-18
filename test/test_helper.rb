# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "kube/ctl"
require "minitest/autorun"

module Kube
  module Ctl
    def self.run(args) = args
  end
end
