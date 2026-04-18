# frozen_string_literal: true

require 'rubyshell'

#require_relative 'helm/string_builder'
require_relative 'helm/instance'

module Kube
  def self.helm(&block)
    Kube::Helm::Instance.new.call(&block).then do |command|
      Kube::Helm.run(command)
    end
  end

  module Helm
    def self.run(args)
      sh { helm args }
    end
  end
end
