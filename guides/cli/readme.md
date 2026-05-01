# The CLI

This guide covers the `kube` command-line interface.

## Usage

The `kube` command ships with this gem. It dispatches to subcommands.

```
$ kube help

Usage: kube <command> [args...]

Commands:
  ctl       Run a kubectl command
  helm      Run a helm command

Run 'kube <command> --help' for more information on a command.
```

## Examples

```
$ kube ctl get pods -o wide
$ kube helm install my-release bitnami/nginx
```
