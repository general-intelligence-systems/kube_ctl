# frozen_string_literal: true

module Kube
  module Helm
    class Instance
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
        Kube::Helm.run(string.to_s)
      end
    end
  end
end
