# frozen_string_literal: true
#
module Kube
  module Helm
    class Instance
      #attr_reader :kubeconfig

      #def initialize(kubeconfig: ENV['KUBECONFIG'])
      #  @kubeconfig = kubeconfig
      #end

      def call(&block)
        if block
          sb.instance_eval(&block)
        end

        #StringBuilder.new.tap do |sb|
        #  if block
        #    sb.instance_eval(&block)
        #  end
        #end
      end

      def run(string)
        Kube::Helm.run "#{string}"
      end
    end
  end
end
