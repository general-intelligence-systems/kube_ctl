# kube_ctl

A Ruby DSL that compiles to kubectl and helm commands. No YAML. No templates. Just Ruby.

```ruby
Kube.ctl { get.pods.o(:wide) }
# => "get pods -o wide"
```

## Usage

Please see the [project documentation](https://general-intelligence-systems.github.io/kube_ctl/) for more details.

  - [Getting Started](https://general-intelligence-systems.github.io/kube_ctl/guides/getting-started/index) - This guide walks you through installing kube_ctl and building your first kubectl command with Ruby.

  - [The DSL](https://general-intelligence-systems.github.io/kube_ctl/guides/dsl/index) - This guide covers the full kubectl DSL syntax.

  - [Helm](https://general-intelligence-systems.github.io/kube_ctl/guides/helm/index) - This guide covers using the Helm DSL.

  - [Kubeconfig Scoping](https://general-intelligence-systems.github.io/kube_ctl/guides/kubeconfig/index) - This guide covers scoping commands to a specific kubeconfig.

  - [The CLI](https://general-intelligence-systems.github.io/kube_ctl/guides/cli/index) - This guide covers the `kube` command-line interface.

  - [Plugin System](https://general-intelligence-systems.github.io/kube_ctl/guides/plugins/index) - This guide covers extending the `kube` CLI with plugins.

## Related Projects

- [kube_cluster](https://github.com/general-intelligence-systems/kube_cluster) -- OOP Kubernetes resource management with dirty tracking and persistence
- [kube_schema](https://github.com/general-intelligence-systems/kube_schema) -- Kubernetes resource schema validation
- [kube_kit](https://github.com/general-intelligence-systems/kube_kit) -- Generators for kube_cluster projects
- [kube_engine](https://github.com/general-intelligence-systems/kube_engine) -- Kubernetes engine

## Built With

[string_builder](https://github.com/n-at-han-k/string_builder) -- captures Ruby method chains into a buffer and serializes them to strings.

## License

Apache-2.0
