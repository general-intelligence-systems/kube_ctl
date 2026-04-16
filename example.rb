TREE = {
  "create" => {
    "secret" => {
      "docker-registry" => {},
      "generic" => {},
      "tls" => {}
    },
    "deployment" => {}
  },
  "get" => {},
  "rollout" => {
    "history" => {},
    "status" => {}
  }
}

buffer = [
  ["get", []],
  ["deployment", []],
  ["v1", []],
  ["apps", []],
  ["namespace", ["default"]],
]

# pull command tokens off the front, stop at first symbol
tokens = buffer.take_while { |e| e.is_a?(Array) }.map(&:first)
# => ["get", "deployment", "v1", "namespace"]

result = tokens.reduce(TREE) do |subtree, token|
  break "`#{token}` not valid here. expected: #{subtree.keys}" if subtree.empty?
  subtree.fetch(token) { break "`#{token}` not in #{subtree.keys}" }
end

puts result.is_a?(String) ? result : "ok"
