# Helm

This guide covers using the Helm DSL.

## Same DSL, Same Power

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
