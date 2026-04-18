# frozen_string_literal: true

# Example: Deploying an application with kubectl
#
# Demonstrates creating resources, deploying, scaling, updating,
# inspecting, and cleaning up a typical web application.

require_relative "../lib/kube/ctl"

# --- Namespace & Config ---

# 1. Create a namespace for the app
Kube.ctl { create.namespace.my-app }

# 2. Set the current context to use the new namespace
Kube.ctl { config.set-context.current.namespace('my-app') }

# --- Secrets & ConfigMaps ---

# 3. Create a configmap from a file
Kube.ctl { create.configmap.app-config.from_file('config/settings.yaml') }

# 4. Create a configmap from literal key-value pairs
Kube.ctl { create.configmap.app-env.from_literal('DATABASE_HOST=postgres').from_literal('CACHE_HOST=redis') }

# 5. Create a docker registry secret
Kube.ctl {
  create.secret.docker-registry.registry-creds
    .docker_server('registry.example.com')
    .docker_username('deploy')
    .docker_password('s3cret')
    .docker_email('deploy@example.com')
}

# 6. Create a TLS secret
Kube.ctl { create.secret.tls.app-tls.cert('certs/tls.crt').key('certs/tls.key') }

# --- Deploy ---

# 7. Create a deployment from an image
Kube.ctl { create.deployment.web.image('registry.example.com/my-app:v1') }

# 8. Apply a full manifest file
Kube.ctl { apply.f './k8s/deployment.yaml' }

# 9. Apply an entire directory of manifests
Kube.ctl { apply.f './k8s/' }

# 10. Expose the deployment as a service
Kube.ctl { expose.deployment.web.port(80).target_port(8080).name('web-svc') }

# --- Inspect ---

# 11. List pods with wide output
Kube.ctl { get.pods.o(:wide) }

# 12. Get the deployment as JSON
Kube.ctl { get.deployment.web.o(:json) }

# 13. Describe the deployment
Kube.ctl { describe.deployment.web }

# 14. Tail logs from the deployment
Kube.ctl { logs.f(true).deployment/web.c('my-app') }

# 15. Stream logs with a label selector
Kube.ctl { logs.f(true).l(app: :web).tail(100) }

# --- Scale & Update ---

# 16. Scale the deployment
Kube.ctl { scale.deployment/web.replicas(5) }

# 17. Autoscale based on CPU
Kube.ctl { autoscale.deployment.web.min(2).max(10).cpu_percent(80) }

# 18. Update the container image (rolling update)
Kube.ctl { set.image.deployment/web.('my-app=registry.example.com/my-app:v2') }

# 19. Set resource limits
Kube.ctl { set.resources.deployment.web.c('my-app').limits('cpu=500m,memory=512Mi').requests('cpu=100m,memory=256Mi') }

# --- Rollout ---

# 20. Check rollout status
Kube.ctl { rollout.status.deployment/web }

# 21. View rollout history
Kube.ctl { rollout.history.deployment/web }

# 22. Roll back to the previous revision
Kube.ctl { rollout.undo.deployment/web }

# 23. Roll back to a specific revision
Kube.ctl { rollout.undo.deployment/web.to_revision(3) }

# 24. Pause a rollout mid-way for a canary check
Kube.ctl { rollout.pause.deployment/web }

# 25. Resume the rollout
Kube.ctl { rollout.resume.deployment/web }

# --- Debug ---

# 26. Exec into a running pod
Kube.ctl { exec.i(true).t(true).web.c('my-app').('-- /bin/sh') }

# 27. Port-forward to a local port
Kube.ctl { port-forward.svc/web-svc.('8080:80') }

# 28. View resource usage
Kube.ctl { top.pod.l(app: :web) }

# --- Cleanup ---

# 29. Delete the deployment
Kube.ctl { delete.deployment.web }

# 30. Delete everything by label
Kube.ctl { delete.('pods,services,deployments').l(app: :web) }

# 31. Delete the entire namespace
Kube.ctl { delete.namespace.my-app }
