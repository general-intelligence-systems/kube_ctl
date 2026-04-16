# frozen_string_literal: true

require 'json'

module Kube
  module Ctl
    class Instance
      GEM_ROOT = File.expand_path('../../..', __dir__)

      COMMAND_TREE = JSON.parse(
        File.read(File.join(GEM_ROOT, 'data', 'kubectl-command-tree-v1-minimal.json'))
      )

      ROOT = TreeNode.new(
        name: 'kubectl',
        type: :command,
        children: TreeNode.build(COMMAND_TREE)
      )

      attr_reader :kubeconfig

      # When kubeconfig is nil, no --kubeconfig flag is passed and
      # kubectl falls back to its own default (~/.kube/config).
      def initialize(kubeconfig: ENV['KUBECONFIG'])
        @kubeconfig = kubeconfig
      end

      def method_missing(name, *args, &block)
        root_node.public_send(name, *args, &block)
      end

      def respond_to_missing?(name, include_private = false)
        root_node.respond_to?(name) || super
      end

      def inspect
        "#<#{self.class.name} kubeconfig=#{@kubeconfig.inspect}>"
      end

      private

      def root_node
        CommandNode.new(current_node: ROOT, command_data: initial_command_data)
      end

      def initial_command_data
        CommandNode::BLANK_DATA.merge(flags: initial_flags)
      end

      def initial_flags
        @kubeconfig ? { 'kubeconfig' => @kubeconfig } : {}
      end
    end
  end
end
