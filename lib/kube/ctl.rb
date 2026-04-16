# frozen_string_literal: true

require_relative 'ctl/version'
require_relative 'ctl/string_builder'
require_relative 'ctl/instance'

module Kube
  def self.ctl(&block)
    Kube::Ctl::Instance.new.call(&block)
  end

  module Ctl
  end
end
