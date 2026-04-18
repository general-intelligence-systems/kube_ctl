# frozen_string_literal: true

require "test_helper"

class CommandTreeTest < Minitest::Test
  def sb(&block)
    Kube.ctl(&block)
  end

  def assert_buffer(result, expected)
    assert_equal expected, result.to_a
  end

  def assert_string(result, expected)
    assert_equal expected, result.to_s
  end

  def test_kubectl_annotate_pods_foo_description_my_frontend
    result = Kube.ctl { annotate.pods.foo.(description: 'my frontend') }
    assert_buffer(result, [["annotate", []], ["pods", []], ["foo", []], [{description: 'my frontend'}]])
    assert_string(result, "kubectl annotate pods foo description='my frontend'")
  end

  def test_kubectl_annotate_f_pod_json_description_my_frontend
    result = Kube.ctl { annotate.f('pod.json').(description: 'my frontend') }
    assert_buffer(result, [["annotate", []], ["f", ["pod.json"]], [{description: 'my frontend'}]])
    assert_string(result, "kubectl annotate -f pod.json description='my frontend'")
  end

  def test_kubectl_annotate_overwrite_pods_foo_description_my_frontend_running_nginx
    result = Kube.ctl { annotate.overwrite(true).pods.foo.(description: 'my frontend running nginx')}
    assert_buffer(result, [["annotate", []], ["overwrite", [true]], ["pods", []], ["foo", []], [{description: 'my frontend running nginx'}]])
    assert_string(result, "kubectl annotate --overwrite pods foo description='my frontend running nginx'")
  end

  def test_kubectl_annotate_pods_all_description_my_frontend_running_nginx
    result = Kube.ctl { annotate.pods.all(true).(description: 'my frontend running nginx')}
    assert_buffer(result, [["annotate", []], ["pods", []], ["all", [true]], [{description: 'my frontend running nginx'}]])
    assert_string(result, "kubectl annotate pods --all description='my frontend running nginx'")
  end

  def test_kubectl_annotate_pods_foo_description_my_frontend_running_nginx_resource_version_1
    result = Kube.ctl { annotate.pods.foo.(description: 'my frontend running nginx').resource_version(1)}
    assert_buffer(result, [["annotate", []], ["pods", []], ["foo", []], [{description: 'my frontend running nginx'}], ["resource_version", [1]]])
    assert_string(result, "kubectl annotate pods foo description='my frontend running nginx' --resource-version=1")
  end

  # Skipped: trailing dash (description-) is not valid Ruby syntax
  # def test_kubectl_annotate_pods_foo_description
  #   result = Kube.ctl { annotate.pods.foo.description- }
  #   assert_buffer(result, [["annotate", []], ["pods", []], ["foo", []], ["description", []], :dash])
  #   assert_string(result, "kubectl annotate pods foo description-")
  # end

  def test_kubectl_api_versions
    result = Kube.ctl { api-versions }
    assert_buffer(result, [["api", []], :dash, ["versions", []]])
    assert_string(result, "kubectl api-versions")
  end

  def test_kubectl_apply_f_pod_json
    result = Kube.ctl { apply.f './pod.json' }
    assert_buffer(result, [["apply", []], ["f", ["./pod.json"]]])
    assert_string(result, "kubectl apply -f ./pod.json")
  end

  def test_kubectl_apply_prune_f_manifest_yaml_l_app_nginx
    result = Kube.ctl { apply.prune(true).f('manifest.yaml').l(app: :nginx) }
    assert_buffer(result, [["apply", []], ["prune", [true]], ["f", ["manifest.yaml"]], ["l", [{app: :nginx}]]])
    assert_string(result, "kubectl apply --prune -f manifest.yaml -l app=nginx")
  end

  def test_kubectl_apply_prune_f_manifest_yaml_all_prune_whitelist_core_v1_configmap
    result = Kube.ctl { apply.prune(true).f('manifest.yaml').all(true).prune_whitelist('core/v1/ConfigMap') }
    assert_buffer(result, [["apply", []], ["prune", [true]], ["f", ["manifest.yaml"]], ["all", [true]], ["prune_whitelist", ["core/v1/ConfigMap"]]])
    assert_string(result, "kubectl apply --prune -f manifest.yaml --all --prune-whitelist=core/v1/ConfigMap")
  end

  def test_kubectl_apply_edit_last_applied_deployment_nginx
    result = Kube.ctl { apply.edit-last-applied.deployment/nginx }
    assert_buffer(result, [["apply", []], ["edit", []], :dash, ["last", []], :dash, ["applied", []], ["deployment", []], :slash, ["nginx", []]])
    assert_string(result, "kubectl apply edit-last-applied deployment/nginx")
  end

  def test_kubectl_apply_edit_last_applied_f_deploy_yaml_o_json
    result = Kube.ctl { apply.edit-last-applied.f('deploy.yaml').o('json') }
    assert_buffer(result, [["apply", []], ["edit", []], :dash, ["last", []], :dash, ["applied", []], ["f", ["deploy.yaml"]], ["o", ["json"]]])
    assert_string(result, "kubectl apply edit-last-applied -f deploy.yaml -o json")
  end

  def test_kubectl_apply_set_last_applied_f_deploy_yaml
    result = Kube.ctl { apply.set-last-applied.f('deploy.yaml') }
    assert_buffer(result, [["apply", []], ["set", []], :dash, ["last", []], :dash, ["applied", []], ["f", ["deploy.yaml"]]])
    assert_string(result, "kubectl apply set-last-applied -f deploy.yaml")
  end

  def test_kubectl_apply_set_last_applied_f_path
    result = Kube.ctl { apply.set-last-applied.f('path/') }
    assert_buffer(result, [["apply", []], ["set", []], :dash, ["last", []], :dash, ["applied", []], ["f", ["path/"]]])
    assert_string(result, "kubectl apply set-last-applied -f path/")
  end

  def test_kubectl_apply_set_last_applied_f_deploy_yaml_create_annotation_true
    result = Kube.ctl { apply.set-last-applied.f('deploy.yaml').create_annotation(true) }
    assert_buffer(result, [["apply", []], ["set", []], :dash, ["last", []], :dash, ["applied", []], ["f", ["deploy.yaml"]], ["create_annotation", [true]]])
    assert_string(result, "kubectl apply set-last-applied -f deploy.yaml --create-annotation")
  end

  def test_kubectl_apply_view_last_applied_deployment_nginx
    result = Kube.ctl { apply.view-last-applied.deployment/nginx }
    assert_buffer(result, [["apply", []], ["view", []], :dash, ["last", []], :dash, ["applied", []], ["deployment", []], :slash, ["nginx", []]])
    assert_string(result, "kubectl apply view-last-applied deployment/nginx")
  end

  def test_kubectl_apply_view_last_applied_f_deploy_yaml_o_json
    result = Kube.ctl { apply.view-last-applied.f('deploy.yaml').o('json') }
    assert_buffer(result, [["apply", []], ["view", []], :dash, ["last", []], :dash, ["applied", []], ["f", ["deploy.yaml"]], ["o", ["json"]]])
    assert_string(result, "kubectl apply view-last-applied -f deploy.yaml -o json")
  end

  # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
  # def test_kubectl_attach_123456_7890
  #   result = Kube.ctl { attach.123456-7890 }
  #   assert_buffer(result, [["attach", []], ["123456", []], :dash, ["7890", []]])
  #   assert_string(result, "kubectl attach 123456-7890")
  # end

  # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
  # def test_kubectl_attach_123456_7890_c_ruby_container
  #   result = Kube.ctl { attach.123456-7890.c 'ruby-container' }
  #   assert_buffer(result, [["attach", []], ["123456", []], :dash, ["7890", []], ["c", ["ruby-container"]]])
  #   assert_string(result, "kubectl attach 123456-7890 -c ruby-container")
  # end

  # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
  # def test_kubectl_attach_123456_7890_c_ruby_container_i_t
  #   result = Kube.ctl { attach.123456-7890.c('ruby-container').i(true).t(true) }
  #   assert_buffer(result, [["attach", []], ["123456", []], :dash, ["7890", []], ["c", ["ruby-container"]], ["i", [true]], ["t", [true]]])
  #   assert_string(result, "kubectl attach 123456-7890 -c ruby-container -i -t")
  # end

  def test_kubectl_attach_rs_nginx
    result = Kube.ctl { attach.rs/nginx }
    assert_buffer(result, [["attach", []], ["rs", []], :slash, ["nginx", []]])
    assert_string(result, "kubectl attach rs/nginx")
  end

  def test_kubectl_auth_can_i_create_pods_all_namespaces
    result = Kube.ctl { auth.can-i.create.pods.all_namespaces(true) }
    assert_buffer(result, [["auth", []], ["can", []], :dash, ["i", []], ["create", []], ["pods", []], ["all_namespaces", [true]]])
    assert_string(result, "kubectl auth can-i create pods --all-namespaces")
  end

  def test_kubectl_auth_can_i_list_deployments_extensions
    result = Kube.ctl { auth.can-i.list.deployments.extensions }
    assert_buffer(result, [["auth", []], ["can", []], :dash, ["i", []], ["list", []], ["deployments", []], ["extensions", []]])
    assert_string(result, "kubectl auth can-i list deployments extensions")
  end

  def test_kubectl_auth_can_i
    result = Kube.ctl { auth.can-i.('*').('*') }
    assert_buffer(result, [["auth", []], ["can", []], :dash, ["i", []], ["*", []], ["*", []]])
    assert_string(result, "kubectl auth can-i * *")
  end

  def test_kubectl_auth_can_i_list_jobs_batch_bar_n_foo
    result = Kube.ctl { auth.can-i.list.jobs.batch/bar.n('foo') }
    assert_buffer(result, [["auth", []], ["can", []], :dash, ["i", []], ["list", []], ["jobs", []], ["batch", []], :slash, ["bar", []], ["n", ["foo"]]])
    assert_string(result, "kubectl auth can-i list jobs batch/bar -n foo")
  end

  def test_kubectl_auth_can_i_get_pods_subresource_log
    result = Kube.ctl { auth.can-i.get.pods.subresource('log') }
    assert_buffer(result, [["auth", []], ["can", []], :dash, ["i", []], ["get", []], ["pods", []], ["subresource", ["log"]]])
    assert_string(result, "kubectl auth can-i get pods --subresource=log")
  end

  def test_kubectl_auth_can_i_get_logs
    result = Kube.ctl { auth.can-i.get.('/logs/') }
    assert_buffer(result, [["auth", []], ["can", []], :dash, ["i", []], ["get", []], ["/logs/", []]])
    assert_string(result, "kubectl auth can-i get /logs/")
  end

  def test_kubectl_autoscale_deployment_foo_min_2_max_10
    result = Kube.ctl { autoscale.deployment.foo.min(2).max(10) }
    assert_buffer(result, [["autoscale", []], ["deployment", []], ["foo", []], ["min", [2]], ["max", [10]]])
    assert_string(result, "kubectl autoscale deployment foo --min=2 --max=10")
  end

  def test_kubectl_autoscale_rc_foo_max_5_cpu_percent_80
    result = Kube.ctl { autoscale.rc.foo.max(5).cpu_percent(80) }
    assert_buffer(result, [["autoscale", []], ["rc", []], ["foo", []], ["max", [5]], ["cpu_percent", [80]]])
    assert_string(result, "kubectl autoscale rc foo --max=5 --cpu-percent=80")
  end

  def test_kubectl_cluster_info
    result = Kube.ctl { cluster-info }
    assert_buffer(result, [["cluster", []], :dash, ["info", []]])
    assert_string(result, "kubectl cluster-info")
  end

  def test_kubectl_cluster_info_dump
    result = Kube.ctl { cluster-info.dump }
    assert_buffer(result, [["cluster", []], :dash, ["info", []], ["dump", []]])
    assert_string(result, "kubectl cluster-info dump")
  end

  def test_kubectl_cluster_info_dump_output_directory_path_to_cluster_state
    result = Kube.ctl { cluster-info.dump.output_directory('/path/to/cluster-state') }
    assert_buffer(result, [["cluster", []], :dash, ["info", []], ["dump", []], ["output_directory", ["/path/to/cluster-state"]]])
    assert_string(result, "kubectl cluster-info dump --output-directory=/path/to/cluster-state")
  end

  def test_kubectl_cluster_info_dump_all_namespaces
    result = Kube.ctl { cluster-info.dump.all_namespaces(true) }
    assert_buffer(result, [["cluster", []], :dash, ["info", []], ["dump", []], ["all_namespaces", [true]]])
    assert_string(result, "kubectl cluster-info dump --all-namespaces")
  end

  def test_kubectl_cluster_info_dump_namespaces_default_kube_system_output_directory_path_to_cluster_state
    result = Kube.ctl { cluster-info.dump.namespaces('default', 'kube-system').output_directory('/path/to/cluster-state')}
    assert_buffer(result, [["cluster", []], :dash, ["info", []], ["dump", []], ["namespaces", ["default", "kube-system"]], ["output_directory", ["/path/to/cluster-state"]]])
    assert_string(result, "kubectl cluster-info dump --namespaces=default,kube-system --output-directory=/path/to/cluster-state")
  end

  def test_kubectl_config_current_context
    result = Kube.ctl { config.current-context }
    assert_buffer(result, [["config", []], ["current", []], :dash, ["context", []]])
    assert_string(result, "kubectl config current-context")
  end

  def test_kubectl_config_delete_cluster_minikube
    result = Kube.ctl { config.delete-cluster.minikube }
    assert_buffer(result, [["config", []], ["delete", []], :dash, ["cluster", []], ["minikube", []]])
    assert_string(result, "kubectl config delete-cluster minikube")
  end

  def test_kubectl_config_delete_context_minikube
    result = Kube.ctl { config.delete-context.minikube }
    assert_buffer(result, [["config", []], ["delete", []], :dash, ["context", []], ["minikube", []]])
    assert_string(result, "kubectl config delete-context minikube")
  end

  def test_kubectl_config_get_clusters
    result = Kube.ctl { config.get-clusters }
    assert_buffer(result, [["config", []], ["get", []], :dash, ["clusters", []]])
    assert_string(result, "kubectl config get-clusters")
  end

  def test_kubectl_config_get_contexts
    result = Kube.ctl { config.get-contexts }
    assert_buffer(result, [["config", []], ["get", []], :dash, ["contexts", []]])
    assert_string(result, "kubectl config get-contexts")
  end

  def test_kubectl_config_get_contexts_my_context
    result = Kube.ctl { config.get-contexts.my-context }
    assert_buffer(result, [["config", []], ["get", []], :dash, ["contexts", []], ["my", []], :dash, ["context", []]])
    assert_string(result, "kubectl config get-contexts my-context")
  end

  def test_kubectl_config_rename_context_old_name_new_name
    result = Kube.ctl { config.rename-context.old-name.new-name }
    assert_buffer(result, [["config", []], ["rename", []], :dash, ["context", []], ["old", []], :dash, ["name", []], ["new", []], :dash, ["name", []]])
    assert_string(result, "kubectl config rename-context old-name new-name")
  end

  def test_kubectl_config_set_cluster_e2e_server_https_1_2_3_4
    result = Kube.ctl { config.set-cluster.e2e.server('https://1.2.3.4') }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["cluster", []], ["e2e", []], ["server", ["https://1.2.3.4"]]])
    assert_string(result, "kubectl config set-cluster e2e --server=https://1.2.3.4")
  end

  def test_kubectl_config_set_cluster_e2e_certificate_authority_kube_e2e_kubernetes_ca_crt
    result = Kube.ctl { config.set-cluster.e2e.cluster_authority('~/.kube/e2e/kubernetes.ca.crt')}
    assert_buffer(result, [["config", []], ["set", []], :dash, ["cluster", []], ["e2e", []], ["cluster_authority", ["~/.kube/e2e/kubernetes.ca.crt"]]])
    assert_string(result, "kubectl config set-cluster e2e --cluster-authority=~/.kube/e2e/kubernetes.ca.crt")
  end

  def test_kubectl_config_set_cluster_e2e_insecure_skip_tls_verify_true
    result = Kube.ctl { config.set-cluster.e2e.insecure_skip_tls_verify(true) }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["cluster", []], ["e2e", []], ["insecure_skip_tls_verify", [true]]])
    assert_string(result, "kubectl config set-cluster e2e --insecure-skip-tls-verify")
  end

  def test_kubectl_config_set_context_gce_user_cluster_admin
    result = Kube.ctl { config.set-context.gce.user('cluster-admin') }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["context", []], ["gce", []], ["user", ["cluster-admin"]]])
    assert_string(result, "kubectl config set-context gce --user=cluster-admin")
  end

  def test_kubectl_config_set_credentials_cluster_admin_client_key_kube_admin_key
    result = Kube.ctl { config.set-credentials.cluster-admin.client_key('~/.kube/admin.key') }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["credentials", []], ["cluster", []], :dash, ["admin", []], ["client_key", ["~/.kube/admin.key"]]])
    assert_string(result, "kubectl config set-credentials cluster-admin --client-key=~/.kube/admin.key")
  end

  def test_kubectl_config_set_credentials_cluster_admin_username_admin_password_uxfgweu9l35qcif
    result = Kube.ctl { config.set-credentials.cluster-admin.username('admin').password('uXFGweU9l35qcif') }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["credentials", []], ["cluster", []], :dash, ["admin", []], ["username", ["admin"]], ["password", ["uXFGweU9l35qcif"]]])
    assert_string(result, "kubectl config set-credentials cluster-admin --username=admin --password=uXFGweU9l35qcif")
  end

  def test_kubectl_config_set_credentials_cluster_admin_client_certificate_kube_admin_crt_embed_certs_true
    result = Kube.ctl { config.set-credentials.cluster-admin.client_certificate('~/.kube/admin.crt').embed_certs(true) }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["credentials", []], ["cluster", []], :dash, ["admin", []], ["client_certificate", ["~/.kube/admin.crt"]], ["embed_certs", [true]]])
    assert_string(result, "kubectl config set-credentials cluster-admin --client-certificate=~/.kube/admin.crt --embed-certs")
  end

  def test_kubectl_config_set_credentials_cluster_admin_auth_provider_gcp
    result = Kube.ctl { config.set-credentials.cluster-admin.auth_provider('gcp') }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["credentials", []], ["cluster", []], :dash, ["admin", []], ["auth_provider", ["gcp"]]])
    assert_string(result, "kubectl config set-credentials cluster-admin --auth-provider=gcp")
  end

  def test_kubectl_config_set_credentials_cluster_admin_auth_provider_oidc_auth_provider_arg_client_id_foo_auth_provider_arg_client_secret_bar
    result = Kube.ctl { config.set-credentials.cluster-admin.auth_provider('oidc').auth_provider_arg('client-id=foo').auth_provider_arg('client-secret=bar') }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["credentials", []], ["cluster", []], :dash, ["admin", []], ["auth_provider", ["oidc"]], ["auth_provider_arg", ["client-id=foo"]], ["auth_provider_arg", ["client-secret=bar"]]])
    assert_string(result, "kubectl config set-credentials cluster-admin --auth-provider=oidc --auth-provider-arg=client-id=foo --auth-provider-arg=client-secret=bar")
  end

  def test_kubectl_config_set_credentials_cluster_admin_auth_provider_oidc_auth_provider_arg_client_secret
    result = Kube.ctl { config.set-credentials.cluster-admin.auth_provider('oidc').auth_provider_arg('client-secret-') }
    assert_buffer(result, [["config", []], ["set", []], :dash, ["credentials", []], ["cluster", []], :dash, ["admin", []], ["auth_provider", ["oidc"]], ["auth_provider_arg", ["client-secret-"]]])
    assert_string(result, "kubectl config set-credentials cluster-admin --auth-provider=oidc --auth-provider-arg=client-secret-")
  end

  def test_kubectl_config_use_context_minikube
    result = Kube.ctl { config.use-context.minikube }
    assert_buffer(result, [["config", []], ["use", []], :dash, ["context", []], ["minikube", []]])
    assert_string(result, "kubectl config use-context minikube")
  end

  def test_kubectl_config_view
    result = Kube.ctl { config.view }
    assert_buffer(result, [["config", []], ["view", []]])
    assert_string(result, "kubectl config view")
  end

  def test_kubectl_config_view_o_jsonpath_users_name_e2e_user_password
    result = Kube.ctl { config.view.o("jsonpath": "'{.users[?(@.name == \"e2e\")].user.password}'")}
    assert_buffer(result, [["config", []], ["view", []], ["o", [{jsonpath: "'{.users[?(@.name == \"e2e\")].user.password}'"}]]])
    assert_string(result, "kubectl config view -o jsonpath='{.users[?(@.name == \"e2e\")].user.password}'")
  end

  def test_kubectl_convert_f_pod_yaml
    result = Kube.ctl { convert.f('pod.yaml') }
    assert_buffer(result, [["convert", []], ["f", ["pod.yaml"]]])
    assert_string(result, "kubectl convert -f pod.yaml")
  end

  def test_kubectl_convert_f_pod_yaml_local_o_json
    result = Kube.ctl { convert.f('pod.yaml').local(true).o('json') }
    assert_buffer(result, [["convert", []], ["f", ["pod.yaml"]], ["local", [true]], ["o", ["json"]]])
    assert_string(result, "kubectl convert -f pod.yaml --local -o json")
  end

  def test_kubectl_cordon_foo
    result = Kube.ctl { cordon.foo }
    assert_buffer(result, [["cordon", []], ["foo", []]])
    assert_string(result, "kubectl cordon foo")
  end

  def test_kubectl_cp_tmp_foo_some_pod_tmp_bar_c_specific_container
    result = Kube.ctl { cp.('/tmp/foo').('<some-pod>:/tmp/bar').c('<specific-container>')}
    assert_buffer(result, [["cp", []], ["/tmp/foo", []], ["<some-pod>:/tmp/bar", []], ["c", ["<specific-container>"]]])
    assert_string(result, "kubectl cp /tmp/foo <some-pod>:/tmp/bar -c <specific-container>")
  end

  def test_kubectl_cp_tmp_foo_some_namespace_some_pod_tmp_bar
    result = Kube.ctl { cp.('/tmp/foo').('<some-namespace>/<some-pod>:/tmp/bar')}
    assert_buffer(result, [["cp", []], ["/tmp/foo", []], ["<some-namespace>/<some-pod>:/tmp/bar", []]])
    assert_string(result, "kubectl cp /tmp/foo <some-namespace>/<some-pod>:/tmp/bar")
  end

  def test_kubectl_cp_some_namespace_some_pod_tmp_foo_tmp_bar
    result = Kube.ctl { cp.('<some-namespace>/<some-pod>:/tmp/foo').('/tmp/bar')}
    assert_buffer(result, [["cp", []], ["<some-namespace>/<some-pod>:/tmp/foo", []], ["/tmp/bar", []]])
    assert_string(result, "kubectl cp <some-namespace>/<some-pod>:/tmp/foo /tmp/bar")
  end

  def test_kubectl_create_f_pod_json
    result = Kube.ctl { create.f './pod.json' }
    assert_buffer(result, [["create", []], ["f", ["./pod.json"]]])
    assert_string(result, "kubectl create -f ./pod.json")
  end

  def test_kubectl_create_f_docker_registry_yaml_edit_output_version_v1_o_json
    result = Kube.ctl { create.f('docker-registry.yaml').edit(true).output_version('v1').o('json') }
    assert_buffer(result, [["create", []], ["f", ["docker-registry.yaml"]], ["edit", [true]], ["output_version", ["v1"]], ["o", ["json"]]])
    assert_string(result, "kubectl create -f docker-registry.yaml --edit --output-version=v1 -o json")
  end

  def test_kubectl_create_clusterrole_pod_reader_verb_get_list_watch_resource_pods
    result = Kube.ctl { create.clusterrole.pod-reader.verb(:get, :list, :watch).resource(:pods)}
    assert_buffer(result, [["create", []], ["clusterrole", []], ["pod", []], :dash, ["reader", []], ["verb", [:get, :list, :watch]], ["resource", [:pods]]])
    assert_string(result, "kubectl create clusterrole pod-reader --verb=get,list,watch --resource=pods")
  end

  def test_kubectl_create_clusterrole_pod_reader_verb_get_list_watch_resource_pods_resource_name_readablepod_resource_name_anotherpod
    result = Kube.ctl { create.clusterrole.pod-reader.verb(:get, :list, :watch).resource(:pods).resource_name(:readablepod).resource_name(:anotherpod) }
    assert_buffer(result, [["create", []], ["clusterrole", []], ["pod", []], :dash, ["reader", []], ["verb", [:get, :list, :watch]], ["resource", [:pods]], ["resource_name", [:readablepod]], ["resource_name", [:anotherpod]]])
    assert_string(result, "kubectl create clusterrole pod-reader --verb=get,list,watch --resource=pods --resource-name=readablepod --resource-name=anotherpod")
  end

  def test_kubectl_create_clusterrole_foo_verb_get_list_watch_resource_rs_extensions
    result = Kube.ctl { create.clusterrole.foo.verb(:get, :list, :watch).resource('rs.extensions') }
    assert_buffer(result, [["create", []], ["clusterrole", []], ["foo", []], ["verb", [:get, :list, :watch]], ["resource", ["rs.extensions"]]])
    assert_string(result, "kubectl create clusterrole foo --verb=get,list,watch --resource=rs.extensions")
  end

  def test_kubectl_create_clusterrole_foo_verb_get_list_watch_resource_pods_pods_status
    result = Kube.ctl { create.clusterrole.foo.verb(:get, :list, :watch).resource(:pods, 'pods/status') }
    assert_buffer(result, [["create", []], ["clusterrole", []], ["foo", []], ["verb", [:get, :list, :watch]], ["resource", [:pods, "pods/status"]]])
    assert_string(result, "kubectl create clusterrole foo --verb=get,list,watch --resource=pods,pods/status")
  end

  def test_kubectl_create_clusterrole_foo_verb_get_non_resource_url_logs
    result = Kube.ctl { create.clusterrole.('"foo"').verb(:get).non_resource_url('/logs/*') }
    assert_buffer(result, [["create", []], ["clusterrole", []], ["\"foo\"", []], ["verb", [:get]], ["non_resource_url", ["/logs/*"]]])
    assert_string(result, "kubectl create clusterrole \"foo\" --verb=get --non-resource-url=/logs/*")
  end

  def test_kubectl_create_clusterrolebinding_cluster_admin_clusterrole_cluster_admin_user_user1_user_user2_group_group1
    result = Kube.ctl { create.clusterrolebinding.cluster-admin.clusterrole('cluster-admin').user('user1').user('user2').group('group1') }
    assert_buffer(result, [["create", []], ["clusterrolebinding", []], ["cluster", []], :dash, ["admin", []], ["clusterrole", ["cluster-admin"]], ["user", ["user1"]], ["user", ["user2"]], ["group", ["group1"]]])
    assert_string(result, "kubectl create clusterrolebinding cluster-admin --clusterrole=cluster-admin --user=user1 --user=user2 --group=group1")
  end

  def test_kubectl_create_configmap_my_config_from_file_path_to_bar
    result = Kube.ctl { create.configmap.my-config.from_file('path/to/bar') }
    assert_buffer(result, [["create", []], ["configmap", []], ["my", []], :dash, ["config", []], ["from_file", ["path/to/bar"]]])
    assert_string(result, "kubectl create configmap my-config --from-file=path/to/bar")
  end

  def test_kubectl_create_configmap_my_config_from_file_key1_path_to_bar_file1_txt_from_file_key2_path_to_bar_file2_txt
    result = Kube.ctl { create.configmap.my-config.from_file('key1=/path/to/bar/file1.txt').from_file('key2=/path/to/bar/file2.txt') }
    assert_buffer(result, [["create", []], ["configmap", []], ["my", []], :dash, ["config", []], ["from_file", ["key1=/path/to/bar/file1.txt"]], ["from_file", ["key2=/path/to/bar/file2.txt"]]])
    assert_string(result, "kubectl create configmap my-config --from-file=key1=/path/to/bar/file1.txt --from-file=key2=/path/to/bar/file2.txt")
  end

  def test_kubectl_create_configmap_my_config_from_literal_key1_config1_from_literal_key2_config2
    result = Kube.ctl { create.configmap.my-config.from_literal('key1=config1').from_literal('key2=config2') }
    assert_buffer(result, [["create", []], ["configmap", []], ["my", []], :dash, ["config", []], ["from_literal", ["key1=config1"]], ["from_literal", ["key2=config2"]]])
    assert_string(result, "kubectl create configmap my-config --from-literal=key1=config1 --from-literal=key2=config2")
  end

  def test_kubectl_create_configmap_my_config_from_env_file_path_to_bar_env
    result = Kube.ctl { create.configmap.my-config.from_env_file('path/to/bar.env') }
    assert_buffer(result, [["create", []], ["configmap", []], ["my", []], :dash, ["config", []], ["from_env_file", ["path/to/bar.env"]]])
    assert_string(result, "kubectl create configmap my-config --from-env-file=path/to/bar.env")
  end

  def test_kubectl_create_deployment_my_dep_image_busybox
    result = Kube.ctl { create.deployment.my-dep.image(:busybox) }
    assert_buffer(result, [["create", []], ["deployment", []], ["my", []], :dash, ["dep", []], ["image", [:busybox]]])
    assert_string(result, "kubectl create deployment my-dep --image=busybox")
  end

  def test_kubectl_create_namespace_my_namespace
    result = Kube.ctl { create.namespace.my-namespace }
    assert_buffer(result, [["create", []], ["namespace", []], ["my", []], :dash, ["namespace", []]])
    assert_string(result, "kubectl create namespace my-namespace")
  end

  def test_kubectl_create_poddisruptionbudget_my_pdb_selector_app_rails_min_available_1
    result = Kube.ctl { create.poddisruptionbudget.my-pdb.selector('app=rails').min_available(1) }
    assert_buffer(result, [["create", []], ["poddisruptionbudget", []], ["my", []], :dash, ["pdb", []], ["selector", ["app=rails"]], ["min_available", [1]]])
    assert_string(result, "kubectl create poddisruptionbudget my-pdb --selector=app=rails --min-available=1")
  end

  def test_kubectl_create_pdb_my_pdb_selector_app_nginx_min_available_50
    result = Kube.ctl { create.pdb.my-pdb.selector('app=nginx').min_available('50%') }
    assert_buffer(result, [["create", []], ["pdb", []], ["my", []], :dash, ["pdb", []], ["selector", ["app=nginx"]], ["min_available", ["50%"]]])
    assert_string(result, "kubectl create pdb my-pdb --selector=app=nginx --min-available=50%")
  end

  def test_kubectl_create_quota_my_quota_hard_cpu_1_memory_1g_pods_2_services_3_replicationcontrollers_2_resourcequotas_1_secrets_5_persistentvolumeclaims_10
    result = Kube.ctl { create.quota.my-quota.hard('cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10') }
    assert_buffer(result, [["create", []], ["quota", []], ["my", []], :dash, ["quota", []], ["hard", ["cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10"]]])
    assert_string(result, "kubectl create quota my-quota --hard=cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10")
  end

  def test_kubectl_create_quota_best_effort_hard_pods_100_scopes_besteffort
    result = Kube.ctl { create.quota.best-effort.hard('pods=100').scopes('BestEffort') }
    assert_buffer(result, [["create", []], ["quota", []], ["best", []], :dash, ["effort", []], ["hard", ["pods=100"]], ["scopes", ["BestEffort"]]])
    assert_string(result, "kubectl create quota best-effort --hard=pods=100 --scopes=BestEffort")
  end

  def test_kubectl_create_role_pod_reader_verb_get_verb_list_verb_watch_resource_pods
    result = Kube.ctl { create.role.pod-reader.verb(:get).verb(:list).verb(:watch).resource(:pods) }
    assert_buffer(result, [["create", []], ["role", []], ["pod", []], :dash, ["reader", []], ["verb", [:get]], ["verb", [:list]], ["verb", [:watch]], ["resource", [:pods]]])
    assert_string(result, "kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods")
  end

  def test_kubectl_create_role_pod_reader_verb_get_list_watch_resource_pods_resource_name_readablepod_resource_name_anotherpod
    result = Kube.ctl { create.role.pod-reader.verb(:get, :list, :watch).resource(:pods).resource_name(:readablepod).resource_name(:anotherpod) }
    assert_buffer(result, [["create", []], ["role", []], ["pod", []], :dash, ["reader", []], ["verb", [:get, :list, :watch]], ["resource", [:pods]], ["resource_name", [:readablepod]], ["resource_name", [:anotherpod]]])
    assert_string(result, "kubectl create role pod-reader --verb=get,list,watch --resource=pods --resource-name=readablepod --resource-name=anotherpod")
  end

  def test_kubectl_create_role_foo_verb_get_list_watch_resource_rs_extensions
    result = Kube.ctl { create.role.foo.verb(:get, :list, :watch).resource('rs.extensions') }
    assert_buffer(result, [["create", []], ["role", []], ["foo", []], ["verb", [:get, :list, :watch]], ["resource", ["rs.extensions"]]])
    assert_string(result, "kubectl create role foo --verb=get,list,watch --resource=rs.extensions")
  end

  def test_kubectl_create_role_foo_verb_get_list_watch_resource_pods_pods_status
    result = Kube.ctl { create.role.foo.verb(:get, :list, :watch).resource(:pods, 'pods/status') }
    assert_buffer(result, [["create", []], ["role", []], ["foo", []], ["verb", [:get, :list, :watch]], ["resource", [:pods, "pods/status"]]])
    assert_string(result, "kubectl create role foo --verb=get,list,watch --resource=pods,pods/status")
  end

  def test_kubectl_create_rolebinding_admin_clusterrole_admin_user_user1_user_user2_group_group1
    result = Kube.ctl { create.rolebinding.admin.clusterrole(:admin).user('user1').user('user2').group('group1') }
    assert_buffer(result, [["create", []], ["rolebinding", []], ["admin", []], ["clusterrole", [:admin]], ["user", ["user1"]], ["user", ["user2"]], ["group", ["group1"]]])
    assert_string(result, "kubectl create rolebinding admin --clusterrole=admin --user=user1 --user=user2 --group=group1")
  end

  def test_kubectl_create_secret_docker_registry_my_secret_docker_server_docker_registry_server_docker_username_docker_user_docker_password_docker_password_docker_email_docker_email
    result = Kube.ctl { create.secret.docker-registry.my-secret.docker_server('DOCKER_REGISTRY_SERVER').docker_username('DOCKER_USER').docker_password('DOCKER_PASSWORD').docker_email('DOCKER_EMAIL') }
    assert_buffer(result, [["create", []], ["secret", []], ["docker", []], :dash, ["registry", []], ["my", []], :dash, ["secret", []], ["docker_server", ["DOCKER_REGISTRY_SERVER"]], ["docker_username", ["DOCKER_USER"]], ["docker_password", ["DOCKER_PASSWORD"]], ["docker_email", ["DOCKER_EMAIL"]]])
    assert_string(result, "kubectl create secret docker-registry my-secret --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL")
  end

  def test_kubectl_create_secret_generic_my_secret_from_file_path_to_bar
    result = Kube.ctl { create.secret.generic.my-secret.from_file('path/to/bar') }
    assert_buffer(result, [["create", []], ["secret", []], ["generic", []], ["my", []], :dash, ["secret", []], ["from_file", ["path/to/bar"]]])
    assert_string(result, "kubectl create secret generic my-secret --from-file=path/to/bar")
  end

  def test_kubectl_create_secret_generic_my_secret_from_file_ssh_privatekey_ssh_id_rsa_from_file_ssh_publickey_ssh_id_rsa_pub
    result = Kube.ctl { create.secret.generic.my-secret.from_file('ssh-privatekey=~/.ssh/id_rsa').from_file('ssh-publickey=~/.ssh/id_rsa.pub') }
    assert_buffer(result, [["create", []], ["secret", []], ["generic", []], ["my", []], :dash, ["secret", []], ["from_file", ["ssh-privatekey=~/.ssh/id_rsa"]], ["from_file", ["ssh-publickey=~/.ssh/id_rsa.pub"]]])
    assert_string(result, "kubectl create secret generic my-secret --from-file=ssh-privatekey=~/.ssh/id_rsa --from-file=ssh-publickey=~/.ssh/id_rsa.pub")
  end

  def test_kubectl_create_secret_generic_my_secret_from_literal_key1_supersecret_from_literal_key2_topsecret
    result = Kube.ctl { create.secret.generic.my-secret.from_literal('key1=supersecret').from_literal('key2=topsecret') }
    assert_buffer(result, [["create", []], ["secret", []], ["generic", []], ["my", []], :dash, ["secret", []], ["from_literal", ["key1=supersecret"]], ["from_literal", ["key2=topsecret"]]])
    assert_string(result, "kubectl create secret generic my-secret --from-literal=key1=supersecret --from-literal=key2=topsecret")
  end

  def test_kubectl_create_secret_generic_my_secret_from_env_file_path_to_bar_env
    result = Kube.ctl { create.secret.generic.my-secret.from_env_file('path/to/bar.env') }
    assert_buffer(result, [["create", []], ["secret", []], ["generic", []], ["my", []], :dash, ["secret", []], ["from_env_file", ["path/to/bar.env"]]])
    assert_string(result, "kubectl create secret generic my-secret --from-env-file=path/to/bar.env")
  end

  def test_kubectl_create_secret_tls_tls_secret_cert_path_to_tls_cert_key_path_to_tls_key
    result = Kube.ctl { create.secret.tls.tls-secret.cert('path/to/tls.cert').key('path/to/tls.key') }
    assert_buffer(result, [["create", []], ["secret", []], ["tls", []], ["tls", []], :dash, ["secret", []], ["cert", ["path/to/tls.cert"]], ["key", ["path/to/tls.key"]]])
    assert_string(result, "kubectl create secret tls tls-secret --cert=path/to/tls.cert --key=path/to/tls.key")
  end

  def test_kubectl_create_service_clusterip_my_cs_tcp_5678_8080
    result = Kube.ctl { create.service.clusterip.my-cs.tcp('5678:8080') }
    assert_buffer(result, [["create", []], ["service", []], ["clusterip", []], ["my", []], :dash, ["cs", []], ["tcp", ["5678:8080"]]])
    assert_string(result, "kubectl create service clusterip my-cs --tcp=5678:8080")
  end

  def test_kubectl_create_service_clusterip_my_cs_clusterip_none
    result = Kube.ctl { create.service.clusterip.my-cs.clusterip('"None"') }
    assert_buffer(result, [["create", []], ["service", []], ["clusterip", []], ["my", []], :dash, ["cs", []], ["clusterip", ["\"None\""]]])
    assert_string(result, "kubectl create service clusterip my-cs --clusterip=\"None\"")
  end

  def test_kubectl_create_service_externalname_my_ns_external_name_bar_com
    result = Kube.ctl { create.service.externalname.my-ns.external_name('bar.com') }
    assert_buffer(result, [["create", []], ["service", []], ["externalname", []], ["my", []], :dash, ["ns", []], ["external_name", ["bar.com"]]])
    assert_string(result, "kubectl create service externalname my-ns --external-name=bar.com")
  end

  def test_kubectl_create_service_loadbalancer_my_lbs_tcp_5678_8080
    result = Kube.ctl { create.service.loadbalancer.my-lbs.tcp('5678:8080') }
    assert_buffer(result, [["create", []], ["service", []], ["loadbalancer", []], ["my", []], :dash, ["lbs", []], ["tcp", ["5678:8080"]]])
    assert_string(result, "kubectl create service loadbalancer my-lbs --tcp=5678:8080")
  end

  def test_kubectl_create_service_nodeport_my_ns_tcp_5678_8080
    result = Kube.ctl { create.service.nodeport.my-ns.tcp('5678:8080') }
    assert_buffer(result, [["create", []], ["service", []], ["nodeport", []], ["my", []], :dash, ["ns", []], ["tcp", ["5678:8080"]]])
    assert_string(result, "kubectl create service nodeport my-ns --tcp=5678:8080")
  end

  def test_kubectl_create_serviceaccount_my_service_account
    result = Kube.ctl { create.serviceaccount.my-service-account }
    assert_buffer(result, [["create", []], ["serviceaccount", []], ["my", []], :dash, ["service", []], :dash, ["account", []]])
    assert_string(result, "kubectl create serviceaccount my-service-account")
  end

  def test_kubectl_delete_f_pod_json
    result = Kube.ctl { delete.f './pod.json' }
    assert_buffer(result, [["delete", []], ["f", ["./pod.json"]]])
    assert_string(result, "kubectl delete -f ./pod.json")
  end

  def test_kubectl_delete_pod_service_baz_foo
    result = Kube.ctl { delete.('pod,service').baz.foo }
    assert_buffer(result, [["delete", []], ["pod,service", []], ["baz", []], ["foo", []]])
    assert_string(result, "kubectl delete pod,service baz foo")
  end

  def test_kubectl_delete_pods_services_l_name_mylabel
    result = Kube.ctl { delete.('pods,services').l(name: 'myLabel') }
    assert_buffer(result, [["delete", []], ["pods,services", []], ["l", [{name: "myLabel"}]]])
    assert_string(result, "kubectl delete pods,services -l name=myLabel")
  end

  def test_kubectl_delete_pod_foo_now
    result = Kube.ctl { delete.pod.foo.now(true) }
    assert_buffer(result, [["delete", []], ["pod", []], ["foo", []], ["now", [true]]])
    assert_string(result, "kubectl delete pod foo --now")
  end

  def test_kubectl_delete_pod_foo_grace_period_0_force
    result = Kube.ctl { delete.pod.foo.grace_period(0).force(true) }
    assert_buffer(result, [["delete", []], ["pod", []], ["foo", []], ["grace_period", [0]], ["force", [true]]])
    assert_string(result, "kubectl delete pod foo --grace-period=0 --force")
  end

  def test_kubectl_delete_pods_all
    result = Kube.ctl { delete.pods.all(true) }
    assert_buffer(result, [["delete", []], ["pods", []], ["all", [true]]])
    assert_string(result, "kubectl delete pods --all")
  end

  def test_kubectl_describe_nodes_kubernetes_node_emt8_c_myproject_internal
    result = Kube.ctl { describe.nodes.('kubernetes-node-emt8.c.myproject.internal') }
    assert_buffer(result, [["describe", []], ["nodes", []], ["kubernetes-node-emt8.c.myproject.internal", []]])
    assert_string(result, "kubectl describe nodes kubernetes-node-emt8.c.myproject.internal")
  end

  def test_kubectl_describe_pods_nginx
    result = Kube.ctl { describe.pods/nginx }
    assert_buffer(result, [["describe", []], ["pods", []], :slash, ["nginx", []]])
    assert_string(result, "kubectl describe pods/nginx")
  end

  def test_kubectl_describe_f_pod_json
    result = Kube.ctl { describe.f 'pod.json' }
    assert_buffer(result, [["describe", []], ["f", ["pod.json"]]])
    assert_string(result, "kubectl describe -f pod.json")
  end

  def test_kubectl_describe_pods
    result = Kube.ctl { describe.pods }
    assert_buffer(result, [["describe", []], ["pods", []]])
    assert_string(result, "kubectl describe pods")
  end

  def test_kubectl_describe_po_l_name_mylabel
    result = Kube.ctl { describe.po.l(name: 'myLabel') }
    assert_buffer(result, [["describe", []], ["po", []], ["l", [{name: "myLabel"}]]])
    assert_string(result, "kubectl describe po -l name=myLabel")
  end

  def test_kubectl_describe_pods_frontend
    result = Kube.ctl { describe.pods.frontend }
    assert_buffer(result, [["describe", []], ["pods", []], ["frontend", []]])
    assert_string(result, "kubectl describe pods frontend")
  end

  def test_kubectl_drain_foo_force
    result = Kube.ctl { drain.foo.force(true) }
    assert_buffer(result, [["drain", []], ["foo", []], ["force", [true]]])
    assert_string(result, "kubectl drain foo --force")
  end

  def test_kubectl_drain_foo_grace_period_900
    result = Kube.ctl { drain.foo.grace_period(900) }
    assert_buffer(result, [["drain", []], ["foo", []], ["grace_period", [900]]])
    assert_string(result, "kubectl drain foo --grace-period=900")
  end

  def test_kubectl_edit_svc_docker_registry
    result = Kube.ctl { edit.svc/docker-registry }
    assert_buffer(result, [["edit", []], ["svc", []], :slash, ["docker", []], :dash, ["registry", []]])
    assert_string(result, "kubectl edit svc/docker-registry")
  end

  def test_kubectl_edit_job_v1_batch_myjob_o_json
    result = Kube.ctl { edit.job.v1.batch/myjob.o('json') }
    assert_buffer(result, [["edit", []], ["job", []], ["v1", []], ["batch", []], :slash, ["myjob", []], ["o", ["json"]]])
    assert_string(result, "kubectl edit job v1 batch/myjob -o json")
  end

  def test_kubectl_edit_deployment_mydeployment_o_yaml_save_config
    result = Kube.ctl { edit.deployment/mydeployment.o(:yaml).save_config(true) }
    assert_buffer(result, [["edit", []], ["deployment", []], :slash, ["mydeployment", []], ["o", [:yaml]], ["save_config", [true]]])
    assert_string(result, "kubectl edit deployment/mydeployment -o yaml --save-config")
  end

  # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
  # def test_kubectl_exec_123456_7890_date
  #   result = Kube.ctl { exec.123456-7890.date }
  #   assert_buffer(result, [["exec", []], ["123456", []], :dash, ["7890", []], ["date", []]])
  #   assert_string(result, "kubectl exec 123456-7890 date")
  # end

  # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
  # def test_kubectl_exec_123456_7890_c_ruby_container_date
  #   result = Kube.ctl { exec.123456-7890.c('ruby-container').date }
  #   assert_buffer(result, [["exec", []], ["123456", []], :dash, ["7890", []], ["c", ["ruby-container"]], ["date", []]])
  #   assert_string(result, "kubectl exec 123456-7890 -c ruby-container date")
  # end

  # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
  # def test_kubectl_exec_123456_7890_c_ruby_container_i_t_bash_il
  #   result = Kube.ctl { exec.123456-7890.c('ruby-container').i(true).t(true).('-- bash -il') }
  #   assert_buffer(result, [["exec", []], ["123456", []], :dash, ["7890", []], ["c", ["ruby-container"]], ["i", [true]], ["t", [true]], ["-- bash -il", []]])
  #   assert_string(result, "kubectl exec 123456-7890 -c ruby-container -i -t -- bash -il")
  # end

  # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
  # def test_kubectl_exec_123456_7890_i_t_ls_t_usr
  #   result = Kube.ctl { exec.123456-7890.i(true).t(true).('-- ls -t /usr') }
  #   assert_buffer(result, [["exec", []], ["123456", []], :dash, ["7890", []], ["i", [true]], ["t", [true]], ["-- ls -t /usr", []]])
  #   assert_string(result, "kubectl exec 123456-7890 -i -t -- ls -t /usr")
  # end

  def test_kubectl_explain_pods
    result = Kube.ctl { explain.pods }
    assert_buffer(result, [["explain", []], ["pods", []]])
    assert_string(result, "kubectl explain pods")
  end

  def test_kubectl_explain_pods_spec_containers
    result = Kube.ctl { explain.pods.spec.containers }
    assert_buffer(result, [["explain", []], ["pods", []], ["spec", []], ["containers", []]])
    assert_string(result, "kubectl explain pods spec containers")
  end

  def test_kubectl_expose_rc_nginx_port_80_target_port_8000
    result = Kube.ctl { expose.rc.nginx.port(80).target_port(8000) }
    assert_buffer(result, [["expose", []], ["rc", []], ["nginx", []], ["port", [80]], ["target_port", [8000]]])
    assert_string(result, "kubectl expose rc nginx --port=80 --target-port=8000")
  end

  def test_kubectl_expose_f_nginx_controller_yaml_port_80_target_port_8000
    result = Kube.ctl { expose.f('nginx-controller.yaml').port(80).target_port(8000) }
    assert_buffer(result, [["expose", []], ["f", ["nginx-controller.yaml"]], ["port", [80]], ["target_port", [8000]]])
    assert_string(result, "kubectl expose -f nginx-controller.yaml --port=80 --target-port=8000")
  end

  def test_kubectl_expose_pod_valid_pod_port_444_name_frontend
    result = Kube.ctl { expose.pod.valid-pod.port(444).name(:frontend) }
    assert_buffer(result, [["expose", []], ["pod", []], ["valid", []], :dash, ["pod", []], ["port", [444]], ["name", [:frontend]]])
    assert_string(result, "kubectl expose pod valid-pod --port=444 --name=frontend")
  end

  def test_kubectl_expose_service_nginx_port_443_target_port_8443_name_nginx_https
    result = Kube.ctl { expose.service.nginx.port(443).target_port(8443).name('nginx-https') }
    assert_buffer(result, [["expose", []], ["service", []], ["nginx", []], ["port", [443]], ["target_port", [8443]], ["name", ["nginx-https"]]])
    assert_string(result, "kubectl expose service nginx --port=443 --target-port=8443 --name=nginx-https")
  end

  def test_kubectl_expose_rc_streamer_port_4100_protocol_udp_name_video_stream
    result = Kube.ctl { expose.rc.streamer.port(4100).protocol(:udp).name('video-stream') }
    assert_buffer(result, [["expose", []], ["rc", []], ["streamer", []], ["port", [4100]], ["protocol", [:udp]], ["name", ["video-stream"]]])
    assert_string(result, "kubectl expose rc streamer --port=4100 --protocol=udp --name=video-stream")
  end

  def test_kubectl_expose_rs_nginx_port_80_target_port_8000
    result = Kube.ctl { expose.rs.nginx.port(80).target_port(8000) }
    assert_buffer(result, [["expose", []], ["rs", []], ["nginx", []], ["port", [80]], ["target_port", [8000]]])
    assert_string(result, "kubectl expose rs nginx --port=80 --target-port=8000")
  end

  def test_kubectl_expose_deployment_nginx_port_80_target_port_8000
    result = Kube.ctl { expose.deployment.nginx.port(80).target_port(8000) }
    assert_buffer(result, [["expose", []], ["deployment", []], ["nginx", []], ["port", [80]], ["target_port", [8000]]])
    assert_string(result, "kubectl expose deployment nginx --port=80 --target-port=8000")
  end

  def test_kubectl_get_pods
    result = Kube.ctl { get.pods }
    assert_buffer(result, [["get", []], ["pods", []]])
    assert_string(result, "kubectl get pods")
  end

  def test_kubectl_get_pods_o_wide
    result = Kube.ctl { get.pods.o(:wide) }
    assert_buffer(result, [["get", []], ["pods", []], ["o", [:wide]]])
    assert_string(result, "kubectl get pods -o wide")
  end

  def test_kubectl_get_replicationcontroller_web
    result = Kube.ctl { get.replicationcontroller.web }
    assert_buffer(result, [["get", []], ["replicationcontroller", []], ["web", []]])
    assert_string(result, "kubectl get replicationcontroller web")
  end

  # Skipped: 13je7 is not a valid Ruby identifier (starts with digit)
  # def test_kubectl_get_o_json_pod_web_pod_13je7
  #   result = Kube.ctl { get.o(:json).pod.web-pod-13je7 }
  #   assert_buffer(result, [["get", []], ["o", [:json]], ["pod", []], ["web", []], :dash, ["pod", []], :dash, ["13je7", []]])
  #   assert_string(result, "kubectl get -o json pod web-pod-13je7")
  # end

  def test_kubectl_get_f_pod_yaml_o_json
    result = Kube.ctl { get.f('pod.yaml').o(:json) }
    assert_buffer(result, [["get", []], ["f", ["pod.yaml"]], ["o", [:json]]])
    assert_string(result, "kubectl get -f pod.yaml -o json")
  end

  # Skipped: 13je7 is not a valid Ruby identifier (starts with digit)
  # def test_kubectl_get_o_template_pod_web_pod_13je7_template_status_phase
  #   result = Kube.ctl { get.o(:template).pod/web-pod-13je7.template('{{.status.phase}}') }
  #   assert_buffer(result, [["get", []], ["o", [:template]], ["pod", []], :slash, ["web", []], :dash, ["pod", []], :dash, ["13je7", []], ["template", ["{{.status.phase}}"]]])
  #   assert_string(result, "kubectl get -o template pod/web-pod-13je7 --template={{.status.phase}}")
  # end

  def test_kubectl_get_rc_services
    result = Kube.ctl { get.('rc,services') }
    assert_buffer(result, [["get", []], ["rc,services", []]])
    assert_string(result, "kubectl get rc,services")
  end

  # Skipped: 13je7 is not a valid Ruby identifier (starts with digit)
  # def test_kubectl_get_rc_web_service_frontend_pods_web_pod_13je7
  #   result = Kube.ctl { get.rc/web.service/frontend.pods/web-pod-13je7 }
  #   assert_buffer(result, [["get", []], ["rc", []], :slash, ["web", []], ["service", []], :slash, ["frontend", []], ["pods", []], :slash, ["web", []], :dash, ["pod", []], :dash, ["13je7", []]])
  #   assert_string(result, "kubectl get rc/web service/frontend pods/web-pod-13je7")
  # end

  def test_kubectl_get_all
    result = Kube.ctl { get.all }
    assert_buffer(result, [["get", []], ["all", []]])
    assert_string(result, "kubectl get all")
  end

  def test_kubectl_label_pods_foo_unhealthy_true
    result = Kube.ctl { label.pods.foo.(unhealthy: 'true') }
    assert_buffer(result, [["label", []], ["pods", []], ["foo", []], [{unhealthy: "true"}]])
    assert_string(result, "kubectl label pods foo unhealthy=true")
  end

  def test_kubectl_label_overwrite_pods_foo_status_unhealthy
    result = Kube.ctl { label.overwrite(true).pods.foo.(status: 'unhealthy') }
    assert_buffer(result, [["label", []], ["overwrite", [true]], ["pods", []], ["foo", []], [{status: "unhealthy"}]])
    assert_string(result, "kubectl label --overwrite pods foo status=unhealthy")
  end

  def test_kubectl_label_pods_all_status_unhealthy
    result = Kube.ctl { label.pods.all(true).(status: 'unhealthy') }
    assert_buffer(result, [["label", []], ["pods", []], ["all", [true]], [{status: "unhealthy"}]])
    assert_string(result, "kubectl label pods --all status=unhealthy")
  end

  def test_kubectl_label_f_pod_json_status_unhealthy
    result = Kube.ctl { label.f('pod.json').(status: 'unhealthy') }
    assert_buffer(result, [["label", []], ["f", ["pod.json"]], [{status: "unhealthy"}]])
    assert_string(result, "kubectl label -f pod.json status=unhealthy")
  end

  def test_kubectl_label_pods_foo_status_unhealthy_resource_version_1
    result = Kube.ctl { label.pods.foo.(status: 'unhealthy').resource_version(1) }
    assert_buffer(result, [["label", []], ["pods", []], ["foo", []], [{status: "unhealthy"}], ["resource_version", [1]]])
    assert_string(result, "kubectl label pods foo status=unhealthy --resource-version=1")
  end

  # Skipped: trailing dash (bar-) is not valid Ruby syntax
  # def test_kubectl_label_pods_foo_bar
  #   result = Kube.ctl { label.pods.foo.bar- }
  #   assert_buffer(result, [["label", []], ["pods", []], ["foo", []], ["bar", []], :dash])
  #   assert_string(result, "kubectl label pods foo bar-")
  # end

  def test_kubectl_logs_nginx
    result = Kube.ctl { logs.nginx }
    assert_buffer(result, [["logs", []], ["nginx", []]])
    assert_string(result, "kubectl logs nginx")
  end

  def test_kubectl_logs_lapp_nginx
    result = Kube.ctl { logs.l(app: :nginx) }
    assert_buffer(result, [["logs", []], ["l", [{app: :nginx}]]])
    assert_string(result, "kubectl logs -lapp=nginx")
  end

  def test_kubectl_logs_p_c_ruby_web_1
    result = Kube.ctl { logs.p(true).c(:ruby).web-1 }
    assert_buffer(result, [["logs", []], ["p", [true]], ["c", [:ruby]], ["web", []], :dash, ["1", []]])
    assert_string(result, "kubectl logs -p -c ruby web-1")
  end

  def test_kubectl_logs_f_c_ruby_web_1
    result = Kube.ctl { logs.f(true).c(:ruby).web-1 }
    assert_buffer(result, [["logs", []], ["f", [true]], ["c", [:ruby]], ["web", []], :dash, ["1", []]])
    assert_string(result, "kubectl logs -f -c ruby web-1")
  end

  def test_kubectl_logs_tail_20_nginx
    result = Kube.ctl { logs.tail(20).nginx }
    assert_buffer(result, [["logs", []], ["tail", [20]], ["nginx", []]])
    assert_string(result, "kubectl logs --tail=20 nginx")
  end

  def test_kubectl_logs_since_1h_nginx
    result = Kube.ctl { logs.since('1h').nginx }
    assert_buffer(result, [["logs", []], ["since", ["1h"]], ["nginx", []]])
    assert_string(result, "kubectl logs --since=1h nginx")
  end

  def test_kubectl_logs_job_hello
    result = Kube.ctl { logs.job/hello }
    assert_buffer(result, [["logs", []], ["job", []], :slash, ["hello", []]])
    assert_string(result, "kubectl logs job/hello")
  end

  def test_kubectl_logs_deployment_nginx_c_nginx_1
    result = Kube.ctl { logs.deployment/nginx.c('nginx-1') }
    assert_buffer(result, [["logs", []], ["deployment", []], :slash, ["nginx", []], ["c", ["nginx-1"]]])
    assert_string(result, "kubectl logs deployment/nginx -c nginx-1")
  end

  def test_kubectl_options
    result = Kube.ctl { options }
    assert_buffer(result, [["options", []]])
    assert_string(result, "kubectl options")
  end

  def test_kubectl_patch_node_k8s_node_1_p_spec_unschedulable_true
    result = Kube.ctl { patch.node.k8s-node-1.p('\'{"spec":{"unschedulable":true}}\'') }
    assert_buffer(result, [["patch", []], ["node", []], ["k8s", []], :dash, ["node", []], :dash, ["1", []], ["p", ["'{\"spec\":{\"unschedulable\":true}}'"]]])
    assert_string(result, "kubectl patch node k8s-node-1 -p '{\"spec\":{\"unschedulable\":true}}'")
  end

  def test_kubectl_patch_f_node_json_p_spec_unschedulable_true
    result = Kube.ctl { patch.f('node.json').p('\'{"spec":{"unschedulable":true}}\'') }
    assert_buffer(result, [["patch", []], ["f", ["node.json"]], ["p", ["'{\"spec\":{\"unschedulable\":true}}'"]]])
    assert_string(result, "kubectl patch -f node.json -p '{\"spec\":{\"unschedulable\":true}}'")
  end

  def test_kubectl_patch_pod_valid_pod_p_spec_containers_name_kubernetes_serve_hostname_image_new_image
    result = Kube.ctl { patch.pod.valid-pod.p('\'{"spec":{"containers":[{"name":"kubernetes-serve-hostname","image":"new image"}]}}\'') }
    assert_buffer(result, [["patch", []], ["pod", []], ["valid", []], :dash, ["pod", []], ["p", ["'{\"spec\":{\"containers\":[{\"name\":\"kubernetes-serve-hostname\",\"image\":\"new image\"}]}}'"]]])
    assert_string(result, "kubectl patch pod valid-pod -p '{\"spec\":{\"containers\":[{\"name\":\"kubernetes-serve-hostname\",\"image\":\"new image\"}]}}'")
  end

  def test_kubectl_patch_pod_valid_pod_type_json_p_op_replace_path_spec_containers_0_image_value_new_image
    result = Kube.ctl { patch.pod.valid-pod.type("'json'").p("'[{\"op\": \"replace\", \"path\": \"/spec/containers/0/image\", \"value\":\"new image\"}]'") }
    assert_buffer(result, [["patch", []], ["pod", []], ["valid", []], :dash, ["pod", []], ["type", ["'json'"]], ["p", ["'[{\"op\": \"replace\", \"path\": \"/spec/containers/0/image\", \"value\":\"new image\"}]'"]]])
    assert_string(result, "kubectl patch pod valid-pod --type='json' -p '[{\"op\": \"replace\", \"path\": \"/spec/containers/0/image\", \"value\":\"new image\"}]'")
  end

  def test_kubectl_port_forward_mypod_5000_6000
    result = Kube.ctl { port-forward.mypod.('5000').('6000') }
    assert_buffer(result, [["port", []], :dash, ["forward", []], ["mypod", []], ["5000", []], ["6000", []]])
    assert_string(result, "kubectl port-forward mypod 5000 6000")
  end

  def test_kubectl_port_forward_mypod_8888_5000
    result = Kube.ctl { port-forward.mypod.('8888:5000') }
    assert_buffer(result, [["port", []], :dash, ["forward", []], ["mypod", []], ["8888:5000", []]])
    assert_string(result, "kubectl port-forward mypod 8888:5000")
  end

  def test_kubectl_port_forward_mypod_5000
    result = Kube.ctl { port-forward.mypod.(':5000') }
    assert_buffer(result, [["port", []], :dash, ["forward", []], ["mypod", []], [":5000", []]])
    assert_string(result, "kubectl port-forward mypod :5000")
  end

  def test_kubectl_port_forward_mypod_0_5000
    result = Kube.ctl { port-forward.mypod.('0:5000') }
    assert_buffer(result, [["port", []], :dash, ["forward", []], ["mypod", []], ["0:5000", []]])
    assert_string(result, "kubectl port-forward mypod 0:5000")
  end

  def test_kubectl_proxy_api_prefix
    result = Kube.ctl { proxy.api_prefix('/') }
    assert_buffer(result, [["proxy", []], ["api_prefix", ["/"]]])
    assert_string(result, "kubectl proxy --api-prefix=/")
  end

  def test_kubectl_proxy_www_my_files_www_prefix_static_api_prefix_api
    result = Kube.ctl { proxy.www('/my/files').www_prefix('/static/').api_prefix('/api/') }
    assert_buffer(result, [["proxy", []], ["www", ["/my/files"]], ["www_prefix", ["/static/"]], ["api_prefix", ["/api/"]]])
    assert_string(result, "kubectl proxy --www=/my/files --www-prefix=/static/ --api-prefix=/api/")
  end

  def test_kubectl_proxy_api_prefix_custom
    result = Kube.ctl { proxy.api_prefix('/custom/') }
    assert_buffer(result, [["proxy", []], ["api_prefix", ["/custom/"]]])
    assert_string(result, "kubectl proxy --api-prefix=/custom/")
  end

  def test_kubectl_proxy_port_8011_www_local_www
    result = Kube.ctl { proxy.port(8011).www('./local/www/') }
    assert_buffer(result, [["proxy", []], ["port", [8011]], ["www", ["./local/www/"]]])
    assert_string(result, "kubectl proxy --port=8011 --www=./local/www/")
  end

  def test_kubectl_proxy_port_0
    result = Kube.ctl { proxy.port(0) }
    assert_buffer(result, [["proxy", []], ["port", [0]]])
    assert_string(result, "kubectl proxy --port=0")
  end

  def test_kubectl_proxy_api_prefix_k8s_api
    result = Kube.ctl { proxy.api_prefix('/k8s-api') }
    assert_buffer(result, [["proxy", []], ["api_prefix", ["/k8s-api"]]])
    assert_string(result, "kubectl proxy --api-prefix=/k8s-api")
  end

  def test_kubectl_replace_f_pod_json
    result = Kube.ctl { replace.f './pod.json' }
    assert_buffer(result, [["replace", []], ["f", ["./pod.json"]]])
    assert_string(result, "kubectl replace -f ./pod.json")
  end


  def test_kubectl_replace_force_f_pod_json
    result = Kube.ctl { replace.force(true).f './pod.json' }
    assert_buffer(result, [["replace", []], ["force", [true]], ["f", ["./pod.json"]]])
    assert_string(result, "kubectl replace --force -f ./pod.json")
  end

  def test_kubectl_scale_replicas_3_rs_foo
    result = Kube.ctl { scale.replicas(3).rs/foo }
    assert_buffer(result, [["scale", []], ["replicas", [3]], ["rs", []], :slash, ["foo", []]])
    assert_string(result, "kubectl scale --replicas=3 rs/foo")
  end

  def test_kubectl_scale_replicas_3_f_foo_yaml
    result = Kube.ctl { scale.replicas(3).f 'foo.yaml' }
    assert_buffer(result, [["scale", []], ["replicas", [3]], ["f", ["foo.yaml"]]])
    assert_string(result, "kubectl scale --replicas=3 -f foo.yaml")
  end

  def test_kubectl_scale_current_replicas_2_replicas_3_deployment_mysql
    result = Kube.ctl { scale.current_replicas(2).replicas(3).deployment/mysql }
    assert_buffer(result, [["scale", []], ["current_replicas", [2]], ["replicas", [3]], ["deployment", []], :slash, ["mysql", []]])
    assert_string(result, "kubectl scale --current-replicas=2 --replicas=3 deployment/mysql")
  end

  def test_kubectl_scale_replicas_5_rc_foo_rc_bar_rc_baz
    result = Kube.ctl { scale.replicas(5).rc/foo.rc/bar.rc/baz }
    assert_buffer(result, [["scale", []], ["replicas", [5]], ["rc", []], :slash, ["foo", []], ["rc", []], :slash, ["bar", []], ["rc", []], :slash, ["baz", []]])
    assert_string(result, "kubectl scale --replicas=5 rc/foo rc/bar rc/baz")
  end

  def test_kubectl_scale_replicas_3_job_cron
    result = Kube.ctl { scale.replicas(3).job/cron }
    assert_buffer(result, [["scale", []], ["replicas", [3]], ["job", []], :slash, ["cron", []]])
    assert_string(result, "kubectl scale --replicas=3 job/cron")
  end

  def test_kubectl_rolling_update_frontend_v1_f_frontend_v2_json
    result = Kube.ctl { rolling-update.frontend-v1.f('frontend-v2.json') }
    assert_buffer(result, [["rolling", []], :dash, ["update", []], ["frontend", []], :dash, ["v1", []], ["f", ["frontend-v2.json"]]])
    assert_string(result, "kubectl rolling-update frontend-v1 -f frontend-v2.json")
  end

  def test_kubectl_rolling_update_frontend_v1_frontend_v2_image_image_v2
    result = Kube.ctl { rolling-update.frontend-v1.frontend-v2.image('image:v2') }
    assert_buffer(result, [["rolling", []], :dash, ["update", []], ["frontend", []], :dash, ["v1", []], ["frontend", []], :dash, ["v2", []], ["image", ["image:v2"]]])
    assert_string(result, "kubectl rolling-update frontend-v1 frontend-v2 --image=image:v2")
  end

  def test_kubectl_rolling_update_frontend_image_image_v2
    result = Kube.ctl { rolling-update.frontend.image('image:v2') }
    assert_buffer(result, [["rolling", []], :dash, ["update", []], ["frontend", []], ["image", ["image:v2"]]])
    assert_string(result, "kubectl rolling-update frontend --image=image:v2")
  end

  def test_kubectl_rolling_update_frontend_v1_frontend_v2_rollback
    result = Kube.ctl { rolling-update.frontend-v1.frontend-v2.rollback(true) }
    assert_buffer(result, [["rolling", []], :dash, ["update", []], ["frontend", []], :dash, ["v1", []], ["frontend", []], :dash, ["v2", []], ["rollback", [true]]])
    assert_string(result, "kubectl rolling-update frontend-v1 frontend-v2 --rollback")
  end

  def test_kubectl_rollout_undo_deployment_abc
    result = Kube.ctl { rollout.undo.deployment/abc }
    assert_buffer(result, [["rollout", []], ["undo", []], ["deployment", []], :slash, ["abc", []]])
    assert_string(result, "kubectl rollout undo deployment/abc")
  end

  def test_kubectl_rollout_status_daemonset_foo
    result = Kube.ctl { rollout.status.daemonset/foo }
    assert_buffer(result, [["rollout", []], ["status", []], ["daemonset", []], :slash, ["foo", []]])
    assert_string(result, "kubectl rollout status daemonset/foo")
  end

  def test_kubectl_rollout_history_deployment_abc
    result = Kube.ctl { rollout.history.deployment/abc }
    assert_buffer(result, [["rollout", []], ["history", []], ["deployment", []], :slash, ["abc", []]])
    assert_string(result, "kubectl rollout history deployment/abc")
  end

  def test_kubectl_rollout_history_daemonset_abc_revision_3
    result = Kube.ctl { rollout.history.daemonset/abc.revision(3) }
    assert_buffer(result, [["rollout", []], ["history", []], ["daemonset", []], :slash, ["abc", []], ["revision", [3]]])
    assert_string(result, "kubectl rollout history daemonset/abc --revision=3")
  end

  def test_kubectl_rollout_pause_deployment_nginx
    result = Kube.ctl { rollout.pause.deployment/nginx }
    assert_buffer(result, [["rollout", []], ["pause", []], ["deployment", []], :slash, ["nginx", []]])
    assert_string(result, "kubectl rollout pause deployment/nginx")
  end

  def test_kubectl_rollout_resume_deployment_nginx
    result = Kube.ctl { rollout.resume.deployment/nginx }
    assert_buffer(result, [["rollout", []], ["resume", []], ["deployment", []], :slash, ["nginx", []]])
    assert_string(result, "kubectl rollout resume deployment/nginx")
  end

  def test_kubectl_rollout_status_deployment_nginx
    result = Kube.ctl { rollout.status.deployment/nginx }
    assert_buffer(result, [["rollout", []], ["status", []], ["deployment", []], :slash, ["nginx", []]])
    assert_string(result, "kubectl rollout status deployment/nginx")
  end

  def test_kubectl_rollout_undo_daemonset_abc_to_revision_3
    result = Kube.ctl { rollout.undo.daemonset/abc.to_revision(3) }
    assert_buffer(result, [["rollout", []], ["undo", []], ["daemonset", []], :slash, ["abc", []], ["to_revision", [3]]])
    assert_string(result, "kubectl rollout undo daemonset/abc --to-revision=3")
  end

  def test_kubectl_rollout_undo_dry_run_true_deployment_abc
    result = Kube.ctl { rollout.undo.dry_run(true).deployment/abc }
    assert_buffer(result, [["rollout", []], ["undo", []], ["dry_run", [true]], ["deployment", []], :slash, ["abc", []]])
    assert_string(result, "kubectl rollout undo --dry-run deployment/abc")
  end

  def test_kubectl_run_nginx_image_nginx
    result = Kube.ctl { run.nginx.image(:nginx) }
    assert_buffer(result, [["run", []], ["nginx", []], ["image", [:nginx]]])
    assert_string(result, "kubectl run nginx --image=nginx")
  end

  def test_kubectl_run_hazelcast_image_hazelcast_port_5701
    result = Kube.ctl { run.hazelcast.image(:hazelcast).port(5701) }
    assert_buffer(result, [["run", []], ["hazelcast", []], ["image", [:hazelcast]], ["port", [5701]]])
    assert_string(result, "kubectl run hazelcast --image=hazelcast --port=5701")
  end

  def test_kubectl_run_hazelcast_image_hazelcast_env_dns_domain_cluster_env_pod_namespace_default
    result = Kube.ctl { run.hazelcast.image(:hazelcast).env('"DNS_DOMAIN=cluster"').env('"POD_NAMESPACE=default"') }
    assert_buffer(result, [["run", []], ["hazelcast", []], ["image", [:hazelcast]], ["env", ["\"DNS_DOMAIN=cluster\""]], ["env", ["\"POD_NAMESPACE=default\""]]])
    assert_string(result, "kubectl run hazelcast --image=hazelcast --env=\"DNS_DOMAIN=cluster\" --env=\"POD_NAMESPACE=default\"")
  end

  def test_kubectl_run_nginx_image_nginx_replicas_5
    result = Kube.ctl { run.nginx.image(:nginx).replicas(5) }
    assert_buffer(result, [["run", []], ["nginx", []], ["image", [:nginx]], ["replicas", [5]]])
    assert_string(result, "kubectl run nginx --image=nginx --replicas=5")
  end

  def test_kubectl_run_nginx_image_nginx_dry_run
    result = Kube.ctl { run.nginx.image(:nginx).dry_run(true) }
    assert_buffer(result, [["run", []], ["nginx", []], ["image", [:nginx]], ["dry_run", [true]]])
    assert_string(result, "kubectl run nginx --image=nginx --dry-run")
  end

  def test_kubectl_run_nginx_image_nginx_overrides_apiversion_v1_spec
    result = Kube.ctl { run.nginx.image(:nginx).overrides("'{ \"apiVersion\": \"v1\", \"spec\": { ... } }'") }
    assert_buffer(result, [["run", []], ["nginx", []], ["image", [:nginx]], ["overrides", ["'{ \"apiVersion\": \"v1\", \"spec\": { ... } }'"]]])
    assert_string(result, "kubectl run nginx --image=nginx --overrides='{ \"apiVersion\": \"v1\", \"spec\": { ... } }'")
  end

  def test_kubectl_run_i_t_busybox_image_busybox_restart_never
    result = Kube.ctl { run.i(true).t(true).busybox.image(:busybox).restart('Never') }
    assert_buffer(result, [["run", []], ["i", [true]], ["t", [true]], ["busybox", []], ["image", [:busybox]], ["restart", ["Never"]]])
    assert_string(result, "kubectl run -i -t busybox --image=busybox --restart=Never")
  end

  def test_kubectl_run_nginx_image_nginx_arg1_arg2_argn
    result = Kube.ctl { run.nginx.image(:nginx).('-- <arg1> <arg2> ... <argN>') }
    assert_buffer(result, [["run", []], ["nginx", []], ["image", [:nginx]], ["-- <arg1> <arg2> ... <argN>", []]])
    assert_string(result, "kubectl run nginx --image=nginx -- <arg1> <arg2> ... <argN>")
  end

  def test_kubectl_run_nginx_image_nginx_command_cmd_arg1_argn
    result = Kube.ctl { run.nginx.image(:nginx).command(true).('-- <cmd> <arg1> ... <argN>') }
    assert_buffer(result, [["run", []], ["nginx", []], ["image", [:nginx]], ["command", [true]], ["-- <cmd> <arg1> ... <argN>", []]])
    assert_string(result, "kubectl run nginx --image=nginx --command -- <cmd> <arg1> ... <argN>")
  end

  def test_kubectl_run_pi_image_perl_restart_onfailure_perl_mbignum_bpi_wle_print_bpi_2000
    result = Kube.ctl { run.pi.image(:perl).restart('OnFailure').("-- perl -Mbignum=bpi -wle 'print bpi(2000)'") }
    assert_buffer(result, [["run", []], ["pi", []], ["image", [:perl]], ["restart", ["OnFailure"]], ["-- perl -Mbignum=bpi -wle 'print bpi(2000)'", []]])
    assert_string(result, "kubectl run pi --image=perl --restart=OnFailure -- perl -Mbignum=bpi -wle 'print bpi(2000)'")
  end

  def test_kubectl_run_pi_schedule_0_5_image_perl_restart_onfailure_perl_mbignum_bpi_wle_print_bpi_2000
    result = Kube.ctl { run.pi.schedule('"0/5 * * * ?"').image(:perl).restart('OnFailure').("-- perl -Mbignum=bpi -wle 'print bpi(2000)'") }
    assert_buffer(result, [["run", []], ["pi", []], ["schedule", ["\"0/5 * * * ?\""]], ["image", [:perl]], ["restart", ["OnFailure"]], ["-- perl -Mbignum=bpi -wle 'print bpi(2000)'", []]])
    assert_string(result, "kubectl run pi --schedule=\"0/5 * * * ?\" --image=perl --restart=OnFailure -- perl -Mbignum=bpi -wle 'print bpi(2000)'")
  end

  def test_kubectl_set_image_deployment_nginx_busybox_busybox_nginx_nginx_1_9_1
    result = Kube.ctl { set.image.deployment/nginx.('busybox=busybox').('nginx=nginx:1.9.1') }
    assert_buffer(result, [["set", []], ["image", []], ["deployment", []], :slash, ["nginx", []], ["busybox=busybox", []], ["nginx=nginx:1.9.1", []]])
    assert_string(result, "kubectl set image deployment/nginx busybox=busybox nginx=nginx:1.9.1")
  end

  def test_kubectl_set_image_deployments_rc_nginx_nginx_1_9_1_all
    result = Kube.ctl { set.image.('deployments,rc').('nginx=nginx:1.9.1').all(true) }
    assert_buffer(result, [["set", []], ["image", []], ["deployments,rc", []], ["nginx=nginx:1.9.1", []], ["all", [true]]])
    assert_string(result, "kubectl set image deployments,rc nginx=nginx:1.9.1 --all")
  end

  def test_kubectl_set_image_daemonset_abc_nginx_1_9_1
    result = Kube.ctl { set.image.daemonset.abc.('*=nginx:1.9.1') }
    assert_buffer(result, [["set", []], ["image", []], ["daemonset", []], ["abc", []], ["*=nginx:1.9.1", []]])
    assert_string(result, "kubectl set image daemonset abc *=nginx:1.9.1")
  end

  def test_kubectl_set_image_f_path_to_file_yaml_nginx_nginx_1_9_1_local_o_yaml
    result = Kube.ctl { set.image.f('path/to/file.yaml').('nginx=nginx:1.9.1').local(true).o(:yaml) }
    assert_buffer(result, [["set", []], ["image", []], ["f", ["path/to/file.yaml"]], ["nginx=nginx:1.9.1", []], ["local", [true]], ["o", [:yaml]]])
    assert_string(result, "kubectl set image -f path/to/file.yaml nginx=nginx:1.9.1 --local -o yaml")
  end

  def test_kubectl_set_resources_deployment_nginx_c_nginx_limits_cpu_200m_memory_512mi
    result = Kube.ctl { set.resources.deployment.nginx.c(:nginx).limits('cpu=200m,memory=512Mi') }
    assert_buffer(result, [["set", []], ["resources", []], ["deployment", []], ["nginx", []], ["c", [:nginx]], ["limits", ["cpu=200m,memory=512Mi"]]])
    assert_string(result, "kubectl set resources deployment nginx -c=nginx --limits=cpu=200m,memory=512Mi")
  end

  def test_kubectl_set_resources_deployment_nginx_limits_cpu_200m_memory_512mi_requests_cpu_100m_memory_256mi
    result = Kube.ctl { set.resources.deployment.nginx.limits('cpu=200m,memory=512Mi').requests('cpu=100m,memory=256Mi') }
    assert_buffer(result, [["set", []], ["resources", []], ["deployment", []], ["nginx", []], ["limits", ["cpu=200m,memory=512Mi"]], ["requests", ["cpu=100m,memory=256Mi"]]])
    assert_string(result, "kubectl set resources deployment nginx --limits=cpu=200m,memory=512Mi --requests=cpu=100m,memory=256Mi")
  end

  def test_kubectl_set_resources_deployment_nginx_limits_cpu_0_memory_0_requests_cpu_0_memory_0
    result = Kube.ctl { set.resources.deployment.nginx.limits('cpu=0,memory=0').requests('cpu=0,memory=0') }
    assert_buffer(result, [["set", []], ["resources", []], ["deployment", []], ["nginx", []], ["limits", ["cpu=0,memory=0"]], ["requests", ["cpu=0,memory=0"]]])
    assert_string(result, "kubectl set resources deployment nginx --limits=cpu=0,memory=0 --requests=cpu=0,memory=0")
  end

  def test_kubectl_set_resources_f_path_to_file_yaml_limits_cpu_200m_memory_512mi_local_o_yaml
    result = Kube.ctl { set.resources.f('path/to/file.yaml').limits('cpu=200m,memory=512Mi').local(true).o(:yaml) }
    assert_buffer(result, [["set", []], ["resources", []], ["f", ["path/to/file.yaml"]], ["limits", ["cpu=200m,memory=512Mi"]], ["local", [true]], ["o", [:yaml]]])
    assert_string(result, "kubectl set resources -f path/to/file.yaml --limits=cpu=200m,memory=512Mi --local -o yaml")
  end



  def test_kubectl_set_subject_clusterrolebinding_admin_serviceaccount_namespace_serviceaccount1
    result = Kube.ctl { set.subject.clusterrolebinding.admin.serviceaccount('namespace:serviceaccount1') }
    assert_buffer(result, [["set", []], ["subject", []], ["clusterrolebinding", []], ["admin", []], ["serviceaccount", ["namespace:serviceaccount1"]]])
    assert_string(result, "kubectl set subject clusterrolebinding admin --serviceaccount=namespace:serviceaccount1")
  end

  def test_kubectl_set_subject_rolebinding_admin_user_user1_user_user2_group_group1
    result = Kube.ctl { set.subject.rolebinding.admin.user('user1').user('user2').group('group1') }
    assert_buffer(result, [["set", []], ["subject", []], ["rolebinding", []], ["admin", []], ["user", ["user1"]], ["user", ["user2"]], ["group", ["group1"]]])
    assert_string(result, "kubectl set subject rolebinding admin --user=user1 --user=user2 --group=group1")
  end


  def test_kubectl_stop_replicationcontroller_foo
    result = Kube.ctl { stop.replicationcontroller.foo }
    assert_buffer(result, [["stop", []], ["replicationcontroller", []], ["foo", []]])
    assert_string(result, "kubectl stop replicationcontroller foo")
  end

  def test_kubectl_stop_pods_services_l_name_mylabel
    result = Kube.ctl { stop.('pods,services').l(name: 'myLabel') }
    assert_buffer(result, [["stop", []], ["pods,services", []], ["l", [{name: "myLabel"}]]])
    assert_string(result, "kubectl stop pods,services -l name=myLabel")
  end

  def test_kubectl_stop_f_service_json
    result = Kube.ctl { stop.f 'service.json' }
    assert_buffer(result, [["stop", []], ["f", ["service.json"]]])
    assert_string(result, "kubectl stop -f service.json")
  end

  def test_kubectl_stop_f_path_to_resources
    result = Kube.ctl { stop.f 'path/to/resources' }
    assert_buffer(result, [["stop", []], ["f", ["path/to/resources"]]])
    assert_string(result, "kubectl stop -f path/to/resources")
  end

  def test_kubectl_taint_nodes_foo_dedicated_special_user_noschedule
    result = Kube.ctl { taint.nodes.foo.(dedicated: 'special-user:NoSchedule') }
    assert_buffer(result, [["taint", []], ["nodes", []], ["foo", []], [{dedicated: "special-user:NoSchedule"}]])
    assert_string(result, "kubectl taint nodes foo dedicated=special-user:NoSchedule")
  end

  def test_kubectl_taint_node_l_mylabel_x_dedicated_foo_prefernoschedule
    result = Kube.ctl { taint.node.l(myLabel: 'X', dedicated: "foo:PreferNoSchedule")}
    assert_buffer(result, [["taint", []], ["node", []], ["l", [{myLabel: "X", dedicated: "foo:PreferNoSchedule"}]]])
    assert_string(result, "kubectl taint node -l myLabel=X dedicated=foo:PreferNoSchedule")
  end

  def test_kubectl_top_node
    result = Kube.ctl { top.node }
    assert_buffer(result, [["top", []], ["node", []]])
    assert_string(result, "kubectl top node")
  end

  def test_kubectl_top_node_node_name
    result = Kube.ctl { top.node.NODE_NAME }
    assert_buffer(result, [["top", []], ["node", []], ["NODE_NAME", []]])
    assert_string(result, "kubectl top node NODE_NAME")
  end

  def test_kubectl_top_pod
    result = Kube.ctl { top.pod }
    assert_buffer(result, [["top", []], ["pod", []]])
    assert_string(result, "kubectl top pod")
  end

  def test_kubectl_top_pod_namespace_namespace
    result = Kube.ctl { top.pod.namespace('NAMESPACE') }
    assert_buffer(result, [["top", []], ["pod", []], ["namespace", ["NAMESPACE"]]])
    assert_string(result, "kubectl top pod --namespace=NAMESPACE")
  end

  def test_kubectl_top_pod_pod_name_containers
    result = Kube.ctl { top.pod.POD_NAME.containers(true) }
    assert_buffer(result, [["top", []], ["pod", []], ["POD_NAME", []], ["containers", [true]]])
    assert_string(result, "kubectl top pod POD_NAME --containers")
  end

  def test_kubectl_top_pod_l_name_mylabel
    result = Kube.ctl { top.pod.l(name: 'myLabel') }
    assert_buffer(result, [["top", []], ["pod", []], ["l", [{name: "myLabel"}]]])
    assert_string(result, "kubectl top pod -l name=myLabel")
  end

  def test_kubectl_uncordon_foo
    result = Kube.ctl { uncordon.foo }
    assert_buffer(result, [["uncordon", []], ["foo", []]])
    assert_string(result, "kubectl uncordon foo")
  end

  def test_kubectl_get_pod_mypod_o_yaml
    result = Kube.ctl { get.pod.mypod.o :yaml }
    assert_buffer(result, [["get", []], ["pod", []], ["mypod", []], ["o", [:yaml]]])
    assert_string(result, "kubectl get pod mypod -o yaml")
  end

  def test_kubectl_version
    result = Kube.ctl { version }
    assert_buffer(result, [["version", []]])
    assert_string(result, "kubectl version")
  end
end
