# Getting Started

This guide walks you through installing kube_ctl and building your first kubectl command with Ruby.

## Install

```
gem install kube_kubectl
```

## Basic Usage

Method chains become commands. Arguments become flags.

```ruby
Kube.ctl { get.pods }                          # get pods
Kube.ctl { get.pods.o(:json) }                 # get pods -o json
Kube.ctl { get.pods.n('kube-system') }         # get pods -n kube-system
Kube.ctl { get.pods.namespace('kube-system') } # get pods --namespace=kube-system
```
