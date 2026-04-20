# frozen_string_literal: true

require 'yaml'
require 'rubyshell'

require_relative 'helm'
require_relative 'vcluster'
require_relative 'ctl/version'
require 'string_builder'
require_relative 'ctl/string_builder'
require_relative 'ctl/concat'
require_relative 'ctl/instance'

module Kube
  def self.ctl(&block)
    Kube::Ctl::Instance.new.call(&block)
  end

  module Ctl
    def self.run(args)
      sh { kubectl args }
    end
  end
end

if __FILE__ == $0
  require "bundler/setup"
  require "minitest/autorun"

  class KubeCtlTest < Minitest::Test
    def test_version
      refute_nil Kube::Ctl::VERSION
    end
  end
end
