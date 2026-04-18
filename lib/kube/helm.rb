# frozen_string_literal: true

require 'rubyshell'

require_relative 'helm/instance'
require_relative 'helm/command_tree'

module Kube
  def self.helm(&block)
    Kube::Helm::Instance.new.call(&block)
  end

  module Helm
    def self.run(args)
      sh { helm args }
    end
  end
end
