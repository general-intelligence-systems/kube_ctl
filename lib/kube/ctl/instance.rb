# frozen_string_literal: true

module Kube
  module Ctl
    class Instance
      attr_reader :kubeconfig

      def initialize(kubeconfig: ENV['KUBECONFIG'])
        @kubeconfig = kubeconfig
      end

      def call(&block)
        sb = StringBuilder.new
        sb.instance_eval(&block) if block
        sb
      end
    end
  end
end
