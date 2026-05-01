# frozen_string_literal: true

require "bundler/setup"
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
