# frozen_string_literal: true

module Kube
  module Helm
    class Instance
      attr_reader :kubeconfig

      def initialize(kubeconfig: ENV['KUBECONFIG'])
        @kubeconfig = kubeconfig
      end

      def call(&block)
        StringBuilder.new.tap do |builder|
          builder.concat_handler = Kube::Ctl::Concat

          if block_given?
            builder.wrap(&block)
          else
            builder
          end
        end
      end

      def run(string)
        if @kubeconfig
          Kube::Helm.run "#{string} --kubeconfig=#{@kubeconfig}"
        else
          Kube::Helm.run(string.to_s)
        end
      end
    end
  end
end
