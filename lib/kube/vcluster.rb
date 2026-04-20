# frozen_string_literal: true

require 'rubyshell'

require_relative 'vcluster/instance'
require_relative 'vcluster/command_tree'

module Kube
  def self.vcluster(&block)
    Kube::VCluster::Instance.new.call(&block)
  end

  module VCluster
    def self.run(args)
      sh { vcluster args }
    end
  end
end
