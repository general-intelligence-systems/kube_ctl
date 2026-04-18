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
        sb.concat_handler = Kube::Ctl::Concat
        if block
          sb.wrap(&block)
        else
          sb
        end
      end

      def run(string)
        Kube::Ctl.run "KUBECONFIG=#{@kubeconfig} #{string}"
      end
    end
  end
end
