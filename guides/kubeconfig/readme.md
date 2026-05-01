# Kubeconfig Scoping

This guide covers scoping commands to a specific kubeconfig.

## Instance-Based Scoping

```ruby
instance = Kube::Ctl::Instance.new(kubeconfig: "/path/to/kubeconfig")
builder = instance.call { get.pods.o(:wide) }
instance.run(builder.to_s)
# => kubectl get pods -o wide --kubeconfig=/path/to/kubeconfig
```

## REPL

In a TTY, calling `inspect` on a builder executes the command immediately:

```ruby
# irb
>> Kube.ctl { get.nodes }
NAME            STATUS   ROLES           AGE   VERSION
control-plane   Ready    control-plane   42d   v1.31.0
```
