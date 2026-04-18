module Kube
  module Helm
    module Utilities
      module_function

      def flatten_hash(hash, prefix: nil)
        hash.each_with_object({}) do |(key, value), result|
          full_key = prefix ? :"#{prefix}.#{key}" : key.to_sym

          if value.is_a?(Hash)
            result.merge!(flatten_hash(value, prefix: full_key))
          else
            result[full_key] = value
          end
        end
      end
    end
  end
end
