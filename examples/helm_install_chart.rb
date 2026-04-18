# frozen_string_literal: true

# Example: Downloading a helm chart and applying values
#
# Demonstrates adding a repo, installing a chart with custom values,
# and upgrading with overrides.

require_relative "../lib/kube/ctl"

# 1. Add the chart repository
Kube.helm { repo.add.("bitnami").("https://charts.bitnami.com/bitnami") }

# 2. Update repos to fetch the latest chart index
Kube.helm { repo.update }

# 3. Install a chart with a values file
Kube.helm { install.my_nginx.("bitnami/nginx").f("values.yaml").namespace("web").create_namespace(true) }

# 4. Install with inline value overrides instead of a file
Kube.helm { install.my_nginx.("bitnami/nginx").set("replicaCount=3").set("service.type=ClusterIP") }

# 5. Install combining a values file with set overrides
Kube.helm {
  install.my_nginx.("bitnami/nginx")
    .f("values.yaml")
    .set("image.tag=1.25.0")
    .namespace("web")
    .create_namespace(true)
    .wait(true)
    .timeout("5m0s")
}

# 6. Upgrade an existing release with new values
Kube.helm {
  upgrade.my_nginx.("bitnami/nginx")
    .f("values.yaml")
    .f("values-production.yaml")
    .set("replicaCount=5")
    .namespace("web")
    .wait(true)
}

# 7. Upgrade with --install so it creates the release if it doesn't exist
Kube.helm {
  upgrade.install(true).my_nginx.("bitnami/nginx")
    .f("values.yaml")
    .reuse_values(true)
    .set("image.tag=1.26.0")
    .namespace("web")
}

# 8. Pull (download) a chart tarball without installing
Kube.helm { pull.("bitnami/nginx").version("15.0.0") }

# 9. Pull and untar into a local directory for inspection
Kube.helm { pull.("bitnami/nginx").untar(true).untardir("./charts") }

# 10. Template locally to preview rendered manifests before installing
Kube.helm {
  template.my_nginx.("bitnami/nginx")
    .f("values.yaml")
    .namespace("web")
}
