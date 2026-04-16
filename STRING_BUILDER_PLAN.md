KUBECTL_SCHEMA = DataTree[
  Node("get")[
    Node("*")
  ],
  Node("*")[
    FlagNode("*")[]
  ]
]

module Kernel
  def Node(name)      = SchemaNode.new(name, :plain)
  def FlagNode(name)  = SchemaNode.new(name, :flag)
end

class SchemaNode
  attr_reader :name, :kind, :children

  def initialize(name, kind, children = [])
    @name = name
    @kind = kind
    @children = children.freeze
  end

  # Node("get")[ Node("*") ] — attach children, return a new node.
  def [](*children)
    self.class.new(@name, @kind, children)
  end

  def match(method_name)
    key = method_name.to_s
    @children.find { |c| c.name == key } ||
      @children.find { |c| c.name == "*" }
  end
end

class DataTree
  def self.[](*children)
    SchemaNode.new("root", :root, children)
  end
end

class StringBuilder
  attr_reader :nodes, :cursor

  def initialize(nodes: [], cursor:)
    @nodes = nodes.freeze
    @cursor = cursor
  end

  def method_missing(name, *args, &_block)
    matched = @cursor.match(name)
    next_node = build_node(matched.kind, name, args)
    self.class.new(nodes: @nodes + [next_node], cursor: matched)
  end

  def respond_to_missing?(_name, _private = false)
    true
  end

  def call(token)
    matched = @cursor.match(token)
    self.class.new(nodes: @nodes + [Node.new(token)], cursor: matched)
  end

  def /(segment)
    *head, tail = @nodes
    self.class.new(
      nodes: head + [tail.extend_path(coerce(segment))],
      cursor: @cursor
    )
  end

  def all
    @nodes.map(&:to_s).join(" ")
  end

  alias to_s all

  private

  def build_node(kind, name, args)
    kind == :flag ? FlagNode.new(name, args.first) : Node.new(name)
  end

  def coerce(seg)
    seg.is_a?(StringBuilder) ? seg.nodes.map(&:to_s).join("/") : seg.to_s
  end
end

Kubectl = StringBuilder.new(cursor: KUBECTL_SCHEMA)
