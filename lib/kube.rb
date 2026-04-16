# frozen_string_literal: true

require_relative 'kube/ctl'

module Kube
  def self.ctl(kubeconfig: ENV['KUBECONFIG'])
    Kube::Ctl::Instance.new(kubeconfig: kubeconfig)
  end
end
