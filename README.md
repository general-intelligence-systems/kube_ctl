# kube

A Ruby DSL that compiles to kubectl and helm commands. No YAML. No templates. Just Ruby.

```ruby
Kube.ctl { get.pods.o(:wide) }
# => "get pods -o wide"
```

## Install

```
gem install kube_kubectl
```

## The DSL

Method chains become commands. Arguments become flags. That's it.

```ruby
# bare methods are tokens
Kube.ctl { get.pods }                          # get pods

# single-char methods with args are short flags
Kube.ctl { get.pods.o(:json) }                 # get pods -o json
Kube.ctl { get.pods.n('kube-system') }         # get pods -n kube-system

# multi-char methods with args are long flags
Kube.ctl { get.pods.namespace('kube-system') } # get pods --namespace=kube-system

# true makes a boolean flag
Kube.ctl { get.pods.all_namespaces(true) }     # get pods --all-namespaces

# underscores become hyphens in flags
Kube.ctl { get.pods.sort_by('.status.phase') } # get pods --sort-by=.status.phase

# ruby's `-` operator joins tokens with hyphens
Kube.ctl { cluster-info }                      # cluster-info
Kube.ctl { config.use-context.prod }           # config use-context prod

# ruby's `/` operator joins tokens with slashes
Kube.ctl { get.deployment/nginx }              # get deployment/nginx
Kube.ctl { logs.f(true).deployment/web }       # logs -f deployment/web

# .() injects literal strings for non-Ruby-safe tokens
Kube.ctl { get.('rc,services') }               # get rc,services
Kube.ctl { exec.web.('-- /bin/sh') }           # exec web -- /bin/sh

# .() with kwargs produces key=value pairs
Kube.ctl { annotate.pods.foo.(description: 'my frontend') }
# annotate pods foo description='my frontend'

# multiple args become comma-separated values
Kube.ctl { create.clusterrole.reader.verb(:get, :list, :watch).resource(:pods) }
# create clusterrole reader --verb=get,list,watch --resource=pods
```

### Full deployment in 31 lines

```ruby
Kube.ctl { create.namespace.my-app }
Kube.ctl { config.set-context.current.namespace('my-app') }
Kube.ctl { create.configmap.app-config.from_file('config/settings.yaml') }
Kube.ctl { create.secret.docker-registry.registry-creds
  .docker_server('registry.example.com')
  .docker_username('deploy')
  .docker_password('s3cret') }
Kube.ctl { create.secret.tls.app-tls.cert('certs/tls.crt').key('certs/tls.key') }
Kube.ctl { create.deployment.web.image('registry.example.com/my-app:v1') }
Kube.ctl { apply.f './k8s/' }
Kube.ctl { expose.deployment.web.port(80).target_port(8080).name('web-svc') }
Kube.ctl { get.pods.o(:wide) }
Kube.ctl { logs.f(true).l(app: :web).tail(100) }
Kube.ctl { scale.deployment/web.replicas(5) }
Kube.ctl { autoscale.deployment.web.min(2).max(10).cpu_percent(80) }
Kube.ctl { set.image.deployment/web.('my-app=registry.example.com/my-app:v2') }
Kube.ctl { rollout.status.deployment/web }
Kube.ctl { rollout.undo.deployment/web.to_revision(3) }
Kube.ctl { port-forward.svc/web-svc.('8080:80') }
Kube.ctl { top.pod.l(app: :web) }
Kube.ctl { delete.namespace.my-app }
```

### Helm

Same DSL. Same power.

```ruby
Kube.helm { repo.add.("bitnami").("https://charts.bitnami.com/bitnami") }
Kube.helm { repo.update }

Kube.helm { install.my_nginx.("bitnami/nginx")
  .f("values.yaml")
  .set("image.tag=1.25.0")
  .namespace("web")
  .create_namespace(true)
  .wait(true)
  .timeout("5m0s") }

Kube.helm { upgrade.install(true).my_nginx.("bitnami/nginx")
  .f("values.yaml")
  .reuse_values(true)
  .set("image.tag=1.26.0")
  .namespace("web") }

Kube.helm { template.my_nginx.("bitnami/nginx").f("values.yaml").namespace("web") }
```

### Kubeconfig scoping

```ruby
instance = Kube::Ctl::Instance.new(kubeconfig: "/path/to/kubeconfig")
builder = instance.call { get.pods.o(:wide) }
instance.run(builder.to_s)
# => kubectl get pods -o wide --kubeconfig=/path/to/kubeconfig
```

### REPL

In a TTY, calling `inspect` on a builder executes the command immediately:

```ruby
# irb
>> Kube.ctl { get.nodes }
NAME            STATUS   ROLES           AGE   VERSION
control-plane   Ready    control-plane   42d   v1.31.0
```

## The CLI

The `kube` command ships with this gem. It dispatches to subcommands.

```
$ kube help

Usage: kube <command> [args...]

Commands:
  ctl       Run a kubectl command
  helm      Run a helm command

Run 'kube <command> --help' for more information on a command.
```

```
$ kube ctl get pods -o wide
$ kube helm install my-release bitnami/nginx
```

### Plugin system

Other gems extend `kube` by dropping a file at `lib/kube/cli/<name>.rb`:

```ruby
# lib/kube/cli/generate.rb
require "kube/cli"

Kube::CLI.register "generate", ->(argv) {
  # your subcommand logic
}, description: "Generate kube_cluster resources"
```

The `kube` executable autodiscovers these from all installed gems. Install a gem, get a command.

```
$ gem install kube_cluster
$ kube help

Commands:
  cluster   Manage cluster connections
  ctl       Run a kubectl command
  generate  Generate kube_cluster resources
  helm      Run a helm command
```

## Related projects

- [kube_cluster](https://github.com/general-intelligence-systems/kube_cluster) -- OOP Kubernetes resource management with dirty tracking and persistence
- [kube_schema](https://github.com/general-intelligence-systems/kube_schema) -- Kubernetes resource schema validation
- [kube_kit](https://github.com/general-intelligence-systems/kube_kit) -- Generators for kube_cluster projects
- [kube_engine](https://github.com/general-intelligence-systems/kube_engine) -- Kubernetes engine

## Built with

[string_builder](https://github.com/n-at-han-k/string_builder) -- captures Ruby method chains into a buffer and serializes them to strings. The entire DSL above is powered by it. See the [examples](https://github.com/n-at-han-k/string_builder/tree/main/examples) for more ideas on what you can build.
