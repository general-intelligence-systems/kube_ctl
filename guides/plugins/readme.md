# Plugin System

This guide covers extending the `kube` CLI with plugins.

## Creating a Plugin

Other gems extend `kube` by dropping a file at `lib/kube/cli/<name>.rb`:

```ruby
# lib/kube/cli/generate.rb
require "kube/cli"

Kube::CLI.register "generate", ->(argv) {
  # your subcommand logic
}, description: "Generate kube_cluster resources"
```

## Auto-Discovery

The `kube` executable autodiscovers plugins from all installed gems. Install a gem, get a command.

```
$ gem install kube_cluster
$ kube help

Commands:
  cluster   Manage cluster connections
  ctl       Run a kubectl command
  generate  Generate kube_cluster resources
  helm      Run a helm command
```
