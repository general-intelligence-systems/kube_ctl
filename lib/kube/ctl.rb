# frozen_string_literal: true

require 'yaml'
require 'shellwords'
require 'rubyshell'

require_relative 'helm'
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
      sh { kubectl Shellwords.escape(args) }
    end
  end
end
