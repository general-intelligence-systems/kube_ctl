# The DSL

This guide covers the full kubectl DSL syntax.

## Tokens and Flags

```ruby
# bare methods are tokens
Kube.ctl { get.pods }                          # get pods

# single-char methods with args are short flags
Kube.ctl { get.pods.o(:json) }                 # get pods -o json

# multi-char methods with args are long flags
Kube.ctl { get.pods.namespace('kube-system') } # get pods --namespace=kube-system

# true makes a boolean flag
Kube.ctl { get.pods.all_namespaces(true) }     # get pods --all-namespaces

# underscores become hyphens in flags
Kube.ctl { get.pods.sort_by('.status.phase') } # get pods --sort-by=.status.phase
```

## Operators

```ruby
# ruby's `-` operator joins tokens with hyphens
Kube.ctl { cluster-info }                      # cluster-info

# ruby's `/` operator joins tokens with slashes
Kube.ctl { get.deployment/nginx }              # get deployment/nginx

# .() injects literal strings for non-Ruby-safe tokens
Kube.ctl { get.('rc,services') }               # get rc,services

# .() with kwargs produces key=value pairs
Kube.ctl { annotate.pods.foo.(description: 'my frontend') }
# annotate pods foo description='my frontend'

# multiple args become comma-separated values
Kube.ctl { create.clusterrole.reader.verb(:get, :list, :watch).resource(:pods) }
# create clusterrole reader --verb=get,list,watch --resource=pods
```

## Full Deployment Example

```ruby
Kube.ctl { create.namespace.my-app }
Kube.ctl { config.set-context.current.namespace('my-app') }
Kube.ctl { create.configmap.app-config.from_file('config/settings.yaml') }
Kube.ctl { create.deployment.web.image('registry.example.com/my-app:v1') }
Kube.ctl { apply.f './k8s/' }
Kube.ctl { expose.deployment.web.port(80).target_port(8080).name('web-svc') }
Kube.ctl { scale.deployment/web.replicas(5) }
Kube.ctl { autoscale.deployment.web.min(2).max(10).cpu_percent(80) }
Kube.ctl { set.image.deployment/web.('my-app=registry.example.com/my-app:v2') }
Kube.ctl { rollout.status.deployment/web }
Kube.ctl { rollout.undo.deployment/web.to_revision(3) }
Kube.ctl { delete.namespace.my-app }
```
