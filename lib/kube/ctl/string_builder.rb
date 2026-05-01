# frozen_string_literal: true


# Monkey-patches for string_builder gem to support kubectl DSL patterns.

# Methods that are defined on Object/Kernel/Enumerable and shadow method_missing.
# These need explicit overrides so they work in the DSL.
SHADOWED_METHODS = %i[describe display filter freeze min max select sort format test clone p].freeze

class StringBuilder
  # Provide a safe, concise representation for REPL/debug output.
  def inspect
    if $stdout.tty?
      Kube::Ctl.run(self.to_s)
    else
      parts = @buffer.respond_to?(:size) ? @buffer.size : 0
      %(#<#{self.class} command=#{command.inspect} parts=#{parts}>)
    end
  end

  # Override call to handle kwargs: .(description: 'my frontend')
  # stores [{description: "my frontend"}] in the buffer.
  def call(token = nil, **kwargs)
    tap do
      if token
        @buffer << [token.to_s, []]
      elsif kwargs.any?
        @buffer << [kwargs]
      end
    end
  end

  SHADOWED_METHODS.each do |name|
    define_method(name) do |*args, **kwargs|
      tap do
        if kwargs.empty?
          @buffer << [name.to_s, args]
        else
          @buffer << [name.to_s, [*args, kwargs]]
        end
      end
    end
  end
end

class InnerStringBuilder
  # Override call to handle kwargs on InnerStringBuilder too.
  def call(token = nil, **kwargs)
    tap do
      if token
        @buffer << [token.to_s, []]
      elsif kwargs.any?
        @buffer << [kwargs]
      end
    end
  end

  # Override / and - operators to handle non-builder operands (e.g. integers, strings).
  # The gem's operators call other.each, which fails for plain values like `1`.
  InnerStringBuilder::OPERATOR_MAP.keys.each do |operator|
    define_method(operator) do |other|
      tap do
        @buffer << InnerStringBuilder::OPERATOR_MAP[operator]
        if other.respond_to?(:each) && !other.is_a?(String) && !other.is_a?(Numeric)
          other.each { |token| @buffer << token }
        else
          @buffer << [other.to_s, []]
        end
      end
    end
  end

  SHADOWED_METHODS.each do |name|
    define_method(name) do |*args, **kwargs|
      tap do
        if kwargs.empty?
          @buffer << [name.to_s, args]
        else
          @buffer << [name.to_s, [*args, kwargs]]
        end
      end
    end
  end
end

class ScopedStringBuilder
  SHADOWED_METHODS.each do |name|
    define_method(name) do |*args, **kwargs|
      InnerStringBuilder.new.send(name, *args, **kwargs)
    end
  end
end

test do
  require_relative "../../../setup"

  it "kubectl_annotate_pods_foo_description_my_frontend" do
    Kube.ctl { annotate.pods.foo.(description: 'my frontend') }.to_s.should == "annotate pods foo description='my frontend'"
  end

  it "kubectl_annotate_f_pod_json_description_my_frontend" do
    Kube.ctl { annotate.f('pod.json').(description: 'my frontend') }.to_s.should == "annotate -f pod.json description='my frontend'"
  end

  it "kubectl_annotate_overwrite_pods_foo_description_my_frontend_running_nginx" do
    Kube.ctl { annotate.overwrite(true).pods.foo.(description: 'my frontend running nginx')}.to_s.should == "annotate --overwrite pods foo description='my frontend running nginx'"
  end

  it "kubectl_annotate_pods_all_description_my_frontend_running_nginx" do
    Kube.ctl { annotate.pods.all(true).(description: 'my frontend running nginx')}.to_s.should == "annotate pods --all description='my frontend running nginx'"
  end

  it "kubectl_annotate_pods_foo_description_my_frontend_running_nginx_resource_version_1" do
    Kube.ctl { annotate.pods.foo.(description: 'my frontend running nginx').resource_version(1)}.to_s.should == "annotate pods foo description='my frontend running nginx' --resource-version=1"
  end

      # Skipped: trailing dash (description-) is not valid Ruby syntax
      # def test_kubectl_annotate_pods_foo_description
      #   result = Kube.ctl { annotate.pods.foo.description- }
      #   assert_buffer(result, [["annotate", []], ["pods", []], ["foo", []], ["description", []], :dash])
      #   assert_string(result, "annotate pods foo description-")
      # end

  it "kubectl_api_versions" do
    Kube.ctl { api-versions }.to_s.should == "api-versions"
  end

  it "kubectl_apply_f_pod_json" do
    Kube.ctl { apply.f './pod.json' }.to_s.should == "apply -f ./pod.json"
  end

  it "kubectl_apply_prune_f_manifest_yaml_l_app_nginx" do
    Kube.ctl { apply.prune(true).f('manifest.yaml').l(app: :nginx) }.to_s.should == "apply --prune -f manifest.yaml -l app=nginx"
  end

  it "kubectl_apply_prune_f_manifest_yaml_all_prune_whitelist_core_v1_configmap" do
    Kube.ctl { apply.prune(true).f('manifest.yaml').all(true).prune_whitelist('core/v1/ConfigMap') }.to_s.should == "apply --prune -f manifest.yaml --all --prune-whitelist=core/v1/ConfigMap"
  end

  it "kubectl_apply_edit_last_applied_deployment_nginx" do
    Kube.ctl { apply.edit-last-applied.deployment/nginx }.to_s.should == "apply edit-last-applied deployment/nginx"
  end

  it "kubectl_apply_edit_last_applied_f_deploy_yaml_o_json" do
    Kube.ctl { apply.edit-last-applied.f('deploy.yaml').o('json') }.to_s.should == "apply edit-last-applied -f deploy.yaml -o json"
  end

  it "kubectl_apply_set_last_applied_f_deploy_yaml" do
    Kube.ctl { apply.set-last-applied.f('deploy.yaml') }.to_s.should == "apply set-last-applied -f deploy.yaml"
  end

  it "kubectl_apply_set_last_applied_f_path" do
    Kube.ctl { apply.set-last-applied.f('path/') }.to_s.should == "apply set-last-applied -f path/"
  end

  it "kubectl_apply_set_last_applied_f_deploy_yaml_create_annotation_true" do
    Kube.ctl { apply.set-last-applied.f('deploy.yaml').create_annotation(true) }.to_s.should == "apply set-last-applied -f deploy.yaml --create-annotation"
  end

  it "kubectl_apply_view_last_applied_deployment_nginx" do
    Kube.ctl { apply.view-last-applied.deployment/nginx }.to_s.should == "apply view-last-applied deployment/nginx"
  end

  it "kubectl_apply_view_last_applied_f_deploy_yaml_o_json" do
    Kube.ctl { apply.view-last-applied.f('deploy.yaml').o('json') }.to_s.should == "apply view-last-applied -f deploy.yaml -o json"
  end

      # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
      # def test_kubectl_attach_123456_7890
      #   result = Kube.ctl { attach.123456-7890 }
      #   assert_buffer(result, [["attach", []], ["123456", []], :dash, ["7890", []]])
      #   assert_string(result, "attach 123456-7890")
      # end
      # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
      # def test_kubectl_attach_123456_7890_c_ruby_container
      #   result = Kube.ctl { attach.123456-7890.c 'ruby-container' }
      #   assert_buffer(result, [["attach", []], ["123456", []], :dash, ["7890", []], ["c", ["ruby-container"]]])
      #   assert_string(result, "attach 123456-7890 -c ruby-container")
      # end
      # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
      # def test_kubectl_attach_123456_7890_c_ruby_container_i_t
      #   result = Kube.ctl { attach.123456-7890.c('ruby-container').i(true).t(true) }
      #   assert_buffer(result, [["attach", []], ["123456", []], :dash, ["7890", []], ["c", ["ruby-container"]], ["i", [true]], ["t", [true]]])
      #   assert_string(result, "attach 123456-7890 -c ruby-container -i -t")
      # end

  it "kubectl_attach_rs_nginx" do
    Kube.ctl { attach.rs/nginx }.to_s.should == "attach rs/nginx"
  end

  it "kubectl_auth_can_i_create_pods_all_namespaces" do
    Kube.ctl { auth.can-i.create.pods.all_namespaces(true) }.to_s.should == "auth can-i create pods --all-namespaces"
  end

  it "kubectl_auth_can_i_list_deployments_extensions" do
    Kube.ctl { auth.can-i.list.deployments.extensions }.to_s.should == "auth can-i list deployments extensions"
  end

  it "kubectl_auth_can_i" do
    Kube.ctl { auth.can-i.('*').('*') }.to_s.should == "auth can-i * *"
  end

  it "kubectl_auth_can_i_list_jobs_batch_bar_n_foo" do
    Kube.ctl { auth.can-i.list.jobs.batch/bar.n('foo') }.to_s.should == "auth can-i list jobs batch/bar -n foo"
  end

  it "kubectl_auth_can_i_get_pods_subresource_log" do
    Kube.ctl { auth.can-i.get.pods.subresource('log') }.to_s.should == "auth can-i get pods --subresource=log"
  end

  it "kubectl_auth_can_i_get_logs" do
    Kube.ctl { auth.can-i.get.('/logs/') }.to_s.should == "auth can-i get /logs/"
  end

  it "kubectl_autoscale_deployment_foo_min_2_max_10" do
    Kube.ctl { autoscale.deployment.foo.min(2).max(10) }.to_s.should == "autoscale deployment foo --min=2 --max=10"
  end

  it "kubectl_autoscale_rc_foo_max_5_cpu_percent_80" do
    Kube.ctl { autoscale.rc.foo.max(5).cpu_percent(80) }.to_s.should == "autoscale rc foo --max=5 --cpu-percent=80"
  end

  it "kubectl_cluster_info" do
    Kube.ctl { cluster-info }.to_s.should == "cluster-info"
  end

  it "kubectl_cluster_info_dump" do
    Kube.ctl { cluster-info.dump }.to_s.should == "cluster-info dump"
  end

  it "kubectl_cluster_info_dump_output_directory_path_to_cluster_state" do
    Kube.ctl { cluster-info.dump.output_directory('/path/to/cluster-state') }.to_s.should == "cluster-info dump --output-directory=/path/to/cluster-state"
  end

  it "kubectl_cluster_info_dump_all_namespaces" do
    Kube.ctl { cluster-info.dump.all_namespaces(true) }.to_s.should == "cluster-info dump --all-namespaces"
  end

  it "kubectl_cluster_info_dump_namespaces_default_kube_system_output_directory_path_to_cluster_state" do
    Kube.ctl { cluster-info.dump.namespaces('default', 'kube-system').output_directory('/path/to/cluster-state')}.to_s.should == "cluster-info dump --namespaces=default,kube-system --output-directory=/path/to/cluster-state"
  end

  it "kubectl_config_current_context" do
    Kube.ctl { config.current-context }.to_s.should == "config current-context"
  end

  it "kubectl_config_delete_cluster_minikube" do
    Kube.ctl { config.delete-cluster.minikube }.to_s.should == "config delete-cluster minikube"
  end

  it "kubectl_config_delete_context_minikube" do
    Kube.ctl { config.delete-context.minikube }.to_s.should == "config delete-context minikube"
  end

  it "kubectl_config_get_clusters" do
    Kube.ctl { config.get-clusters }.to_s.should == "config get-clusters"
  end

  it "kubectl_config_get_contexts" do
    Kube.ctl { config.get-contexts }.to_s.should == "config get-contexts"
  end

  it "kubectl_config_get_contexts_my_context" do
    Kube.ctl { config.get-contexts.my-context }.to_s.should == "config get-contexts my-context"
  end

  it "kubectl_config_rename_context_old_name_new_name" do
    Kube.ctl { config.rename-context.old-name.new-name }.to_s.should == "config rename-context old-name new-name"
  end

  it "kubectl_config_set_cluster_e2e_server_https_1_2_3_4" do
    Kube.ctl { config.set-cluster.e2e.server('https://1.2.3.4') }.to_s.should == "config set-cluster e2e --server=https://1.2.3.4"
  end

  it "kubectl_config_set_cluster_e2e_certificate_authority_kube_e2e_kubernetes_ca_crt" do
    Kube.ctl { config.set-cluster.e2e.cluster_authority('~/.kube/e2e/kubernetes.ca.crt')}.to_s.should == "config set-cluster e2e --cluster-authority=~/.kube/e2e/kubernetes.ca.crt"
  end

  it "kubectl_config_set_cluster_e2e_insecure_skip_tls_verify_true" do
    Kube.ctl { config.set-cluster.e2e.insecure_skip_tls_verify(true) }.to_s.should == "config set-cluster e2e --insecure-skip-tls-verify"
  end

  it "kubectl_config_set_context_gce_user_cluster_admin" do
    Kube.ctl { config.set-context.gce.user('cluster-admin') }.to_s.should == "config set-context gce --user=cluster-admin"
  end

  it "kubectl_config_set_credentials_cluster_admin_client_key_kube_admin_key" do
    Kube.ctl { config.set-credentials.cluster-admin.client_key('~/.kube/admin.key') }.to_s.should == "config set-credentials cluster-admin --client-key=~/.kube/admin.key"
  end

  it "kubectl_config_set_credentials_cluster_admin_username_admin_password_uxfgweu9l35qcif" do
    Kube.ctl { config.set-credentials.cluster-admin.username('admin').password('uXFGweU9l35qcif') }.to_s.should == "config set-credentials cluster-admin --username=admin --password=uXFGweU9l35qcif"
  end

  it "kubectl_config_set_credentials_cluster_admin_client_certificate_kube_admin_crt_embed_certs_true" do
    Kube.ctl { config.set-credentials.cluster-admin.client_certificate('~/.kube/admin.crt').embed_certs(true) }.to_s.should == "config set-credentials cluster-admin --client-certificate=~/.kube/admin.crt --embed-certs"
  end

  it "kubectl_config_set_credentials_cluster_admin_auth_provider_gcp" do
    Kube.ctl { config.set-credentials.cluster-admin.auth_provider('gcp') }.to_s.should == "config set-credentials cluster-admin --auth-provider=gcp"
  end

  it "kubectl_config_set_credentials_cluster_admin_auth_provider_oidc_auth_provider_arg_client_id_foo_auth_provider_arg_client_secret_bar" do
    Kube.ctl { config.set-credentials.cluster-admin.auth_provider('oidc').auth_provider_arg('client-id=foo').auth_provider_arg('client-secret=bar') }.to_s.should == "config set-credentials cluster-admin --auth-provider=oidc --auth-provider-arg=client-id=foo --auth-provider-arg=client-secret=bar"
  end

  it "kubectl_config_set_credentials_cluster_admin_auth_provider_oidc_auth_provider_arg_client_secret" do
    Kube.ctl { config.set-credentials.cluster-admin.auth_provider('oidc').auth_provider_arg('client-secret-') }.to_s.should == "config set-credentials cluster-admin --auth-provider=oidc --auth-provider-arg=client-secret-"
  end

  it "kubectl_config_use_context_minikube" do
    Kube.ctl { config.use-context.minikube }.to_s.should == "config use-context minikube"
  end

  it "kubectl_config_view" do
    Kube.ctl { config.view }.to_s.should == "config view"
  end

  it "kubectl_config_view_o_jsonpath_users_name_e2e_user_password" do
    Kube.ctl { config.view.o("jsonpath": "'{.users[?(@.name == \"e2e\")].user.password}'")}.to_s.should == "config view -o jsonpath='{.users[?(@.name == \"e2e\")].user.password}'"
  end

  it "kubectl_convert_f_pod_yaml" do
    Kube.ctl { convert.f('pod.yaml') }.to_s.should == "convert -f pod.yaml"
  end

  it "kubectl_convert_f_pod_yaml_local_o_json" do
    Kube.ctl { convert.f('pod.yaml').local(true).o('json') }.to_s.should == "convert -f pod.yaml --local -o json"
  end

  it "kubectl_cordon_foo" do
    Kube.ctl { cordon.foo }.to_s.should == "cordon foo"
  end

  it "kubectl_cp_tmp_foo_some_pod_tmp_bar_c_specific_container" do
    Kube.ctl { cp.('/tmp/foo').('<some-pod>:/tmp/bar').c('<specific-container>')}.to_s.should == "cp /tmp/foo <some-pod>:/tmp/bar -c <specific-container>"
  end

  it "kubectl_cp_tmp_foo_some_namespace_some_pod_tmp_bar" do
    Kube.ctl { cp.('/tmp/foo').('<some-namespace>/<some-pod>:/tmp/bar')}.to_s.should == "cp /tmp/foo <some-namespace>/<some-pod>:/tmp/bar"
  end

  it "kubectl_cp_some_namespace_some_pod_tmp_foo_tmp_bar" do
    Kube.ctl { cp.('<some-namespace>/<some-pod>:/tmp/foo').('/tmp/bar')}.to_s.should == "cp <some-namespace>/<some-pod>:/tmp/foo /tmp/bar"
  end

  it "kubectl_create_f_pod_json" do
    Kube.ctl { create.f './pod.json' }.to_s.should == "create -f ./pod.json"
  end

  it "kubectl_create_f_docker_registry_yaml_edit_output_version_v1_o_json" do
    Kube.ctl { create.f('docker-registry.yaml').edit(true).output_version('v1').o('json') }.to_s.should == "create -f docker-registry.yaml --edit --output-version=v1 -o json"
  end

  it "kubectl_create_clusterrole_pod_reader_verb_get_list_watch_resource_pods" do
    Kube.ctl { create.clusterrole.pod-reader.verb(:get, :list, :watch).resource(:pods)}.to_s.should == "create clusterrole pod-reader --verb=get,list,watch --resource=pods"
  end

  it "kubectl_create_clusterrole_pod_reader_verb_get_list_watch_resource_pods_resource_name_readablepod_resource_name_anotherpod" do
    Kube.ctl { create.clusterrole.pod-reader.verb(:get, :list, :watch).resource(:pods).resource_name(:readablepod).resource_name(:anotherpod) }.to_s.should == "create clusterrole pod-reader --verb=get,list,watch --resource=pods --resource-name=readablepod --resource-name=anotherpod"
  end

  it "kubectl_create_clusterrole_foo_verb_get_list_watch_resource_rs_extensions" do
    Kube.ctl { create.clusterrole.foo.verb(:get, :list, :watch).resource('rs.extensions') }.to_s.should == "create clusterrole foo --verb=get,list,watch --resource=rs.extensions"
  end

  it "kubectl_create_clusterrole_foo_verb_get_list_watch_resource_pods_pods_status" do
    Kube.ctl { create.clusterrole.foo.verb(:get, :list, :watch).resource(:pods, 'pods/status') }.to_s.should == "create clusterrole foo --verb=get,list,watch --resource=pods,pods/status"
  end

  it "kubectl_create_clusterrole_foo_verb_get_non_resource_url_logs" do
    Kube.ctl { create.clusterrole.('"foo"').verb(:get).non_resource_url('/logs/*') }.to_s.should == "create clusterrole \"foo\" --verb=get --non-resource-url=/logs/*"
  end

  it "kubectl_create_clusterrolebinding_cluster_admin_clusterrole_cluster_admin_user_user1_user_user2_group_group1" do
    Kube.ctl { create.clusterrolebinding.cluster-admin.clusterrole('cluster-admin').user('user1').user('user2').group('group1') }.to_s.should == "create clusterrolebinding cluster-admin --clusterrole=cluster-admin --user=user1 --user=user2 --group=group1"
  end

  it "kubectl_create_configmap_my_config_from_file_path_to_bar" do
    Kube.ctl { create.configmap.my-config.from_file('path/to/bar') }.to_s.should == "create configmap my-config --from-file=path/to/bar"
  end

  it "kubectl_create_configmap_my_config_from_file_key1_path_to_bar_file1_txt_from_file_key2_path_to_bar_file2_txt" do
    Kube.ctl { create.configmap.my-config.from_file('key1=/path/to/bar/file1.txt').from_file('key2=/path/to/bar/file2.txt') }.to_s.should == "create configmap my-config --from-file=key1=/path/to/bar/file1.txt --from-file=key2=/path/to/bar/file2.txt"
  end

  it "kubectl_create_configmap_my_config_from_literal_key1_config1_from_literal_key2_config2" do
    Kube.ctl { create.configmap.my-config.from_literal('key1=config1').from_literal('key2=config2') }.to_s.should == "create configmap my-config --from-literal=key1=config1 --from-literal=key2=config2"
  end

  it "kubectl_create_configmap_my_config_from_env_file_path_to_bar_env" do
    Kube.ctl { create.configmap.my-config.from_env_file('path/to/bar.env') }.to_s.should == "create configmap my-config --from-env-file=path/to/bar.env"
  end

  it "kubectl_create_deployment_my_dep_image_busybox" do
    Kube.ctl { create.deployment.my-dep.image(:busybox) }.to_s.should == "create deployment my-dep --image=busybox"
  end

  it "kubectl_create_namespace_my_namespace" do
    Kube.ctl { create.namespace.my-namespace }.to_s.should == "create namespace my-namespace"
  end

  it "kubectl_create_poddisruptionbudget_my_pdb_selector_app_rails_min_available_1" do
    Kube.ctl { create.poddisruptionbudget.my-pdb.selector('app=rails').min_available(1) }.to_s.should == "create poddisruptionbudget my-pdb --selector=app=rails --min-available=1"
  end

  it "kubectl_create_pdb_my_pdb_selector_app_nginx_min_available_50" do
    Kube.ctl { create.pdb.my-pdb.selector('app=nginx').min_available('50%') }.to_s.should == "create pdb my-pdb --selector=app=nginx --min-available=50%"
  end

  it "kubectl_create_quota_my_quota_hard_cpu_1_memory_1g_pods_2_services_3_replicationcontrollers_2_resourcequotas_1_secrets_5_persistentvolumeclaims_10" do
    Kube.ctl { create.quota.my-quota.hard('cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10') }.to_s.should == "create quota my-quota --hard=cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10"
  end

  it "kubectl_create_quota_best_effort_hard_pods_100_scopes_besteffort" do
    Kube.ctl { create.quota.best-effort.hard('pods=100').scopes('BestEffort') }.to_s.should == "create quota best-effort --hard=pods=100 --scopes=BestEffort"
  end

  it "kubectl_create_role_pod_reader_verb_get_verb_list_verb_watch_resource_pods" do
    Kube.ctl { create.role.pod-reader.verb(:get).verb(:list).verb(:watch).resource(:pods) }.to_s.should == "create role pod-reader --verb=get --verb=list --verb=watch --resource=pods"
  end

  it "kubectl_create_role_pod_reader_verb_get_list_watch_resource_pods_resource_name_readablepod_resource_name_anotherpod" do
    Kube.ctl { create.role.pod-reader.verb(:get, :list, :watch).resource(:pods).resource_name(:readablepod).resource_name(:anotherpod) }.to_s.should == "create role pod-reader --verb=get,list,watch --resource=pods --resource-name=readablepod --resource-name=anotherpod"
  end

  it "kubectl_create_role_foo_verb_get_list_watch_resource_rs_extensions" do
    Kube.ctl { create.role.foo.verb(:get, :list, :watch).resource('rs.extensions') }.to_s.should == "create role foo --verb=get,list,watch --resource=rs.extensions"
  end

  it "kubectl_create_role_foo_verb_get_list_watch_resource_pods_pods_status" do
    Kube.ctl { create.role.foo.verb(:get, :list, :watch).resource(:pods, 'pods/status') }.to_s.should == "create role foo --verb=get,list,watch --resource=pods,pods/status"
  end

  it "kubectl_create_rolebinding_admin_clusterrole_admin_user_user1_user_user2_group_group1" do
    Kube.ctl { create.rolebinding.admin.clusterrole(:admin).user('user1').user('user2').group('group1') }.to_s.should == "create rolebinding admin --clusterrole=admin --user=user1 --user=user2 --group=group1"
  end

  it "kubectl_create_secret_docker_registry_my_secret_docker_server_docker_registry_server_docker_username_docker_user_docker_password_docker_password_docker_email_docker_email" do
    Kube.ctl { create.secret.docker-registry.my-secret.docker_server('DOCKER_REGISTRY_SERVER').docker_username('DOCKER_USER').docker_password('DOCKER_PASSWORD').docker_email('DOCKER_EMAIL') }.to_s.should == "create secret docker-registry my-secret --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL"
  end

  it "kubectl_create_secret_generic_my_secret_from_file_path_to_bar" do
    Kube.ctl { create.secret.generic.my-secret.from_file('path/to/bar') }.to_s.should == "create secret generic my-secret --from-file=path/to/bar"
  end

  it "kubectl_create_secret_generic_my_secret_from_file_ssh_privatekey_ssh_id_rsa_from_file_ssh_publickey_ssh_id_rsa_pub" do
    Kube.ctl { create.secret.generic.my-secret.from_file('ssh-privatekey=~/.ssh/id_rsa').from_file('ssh-publickey=~/.ssh/id_rsa.pub') }.to_s.should == "create secret generic my-secret --from-file=ssh-privatekey=~/.ssh/id_rsa --from-file=ssh-publickey=~/.ssh/id_rsa.pub"
  end

  it "kubectl_create_secret_generic_my_secret_from_literal_key1_supersecret_from_literal_key2_topsecret" do
    Kube.ctl { create.secret.generic.my-secret.from_literal('key1=supersecret').from_literal('key2=topsecret') }.to_s.should == "create secret generic my-secret --from-literal=key1=supersecret --from-literal=key2=topsecret"
  end

  it "kubectl_create_secret_generic_my_secret_from_env_file_path_to_bar_env" do
    Kube.ctl { create.secret.generic.my-secret.from_env_file('path/to/bar.env') }.to_s.should == "create secret generic my-secret --from-env-file=path/to/bar.env"
  end

  it "kubectl_create_secret_tls_tls_secret_cert_path_to_tls_cert_key_path_to_tls_key" do
    Kube.ctl { create.secret.tls.tls-secret.cert('path/to/tls.cert').key('path/to/tls.key') }.to_s.should == "create secret tls tls-secret --cert=path/to/tls.cert --key=path/to/tls.key"
  end

  it "kubectl_create_service_clusterip_my_cs_tcp_5678_8080" do
    Kube.ctl { create.service.clusterip.my-cs.tcp('5678:8080') }.to_s.should == "create service clusterip my-cs --tcp=5678:8080"
  end

  it "kubectl_create_service_clusterip_my_cs_clusterip_none" do
    Kube.ctl { create.service.clusterip.my-cs.clusterip('"None"') }.to_s.should == "create service clusterip my-cs --clusterip=\"None\""
  end

  it "kubectl_create_service_externalname_my_ns_external_name_bar_com" do
    Kube.ctl { create.service.externalname.my-ns.external_name('bar.com') }.to_s.should == "create service externalname my-ns --external-name=bar.com"
  end

  it "kubectl_create_service_loadbalancer_my_lbs_tcp_5678_8080" do
    Kube.ctl { create.service.loadbalancer.my-lbs.tcp('5678:8080') }.to_s.should == "create service loadbalancer my-lbs --tcp=5678:8080"
  end

  it "kubectl_create_service_nodeport_my_ns_tcp_5678_8080" do
    Kube.ctl { create.service.nodeport.my-ns.tcp('5678:8080') }.to_s.should == "create service nodeport my-ns --tcp=5678:8080"
  end

  it "kubectl_create_serviceaccount_my_service_account" do
    Kube.ctl { create.serviceaccount.my-service-account }.to_s.should == "create serviceaccount my-service-account"
  end

  it "kubectl_delete_f_pod_json" do
    Kube.ctl { delete.f './pod.json' }.to_s.should == "delete -f ./pod.json"
  end

  it "kubectl_delete_pod_service_baz_foo" do
    Kube.ctl { delete.('pod,service').baz.foo }.to_s.should == "delete pod,service baz foo"
  end

  it "kubectl_delete_pods_services_l_name_mylabel" do
    Kube.ctl { delete.('pods,services').l(name: 'myLabel') }.to_s.should == "delete pods,services -l name=myLabel"
  end

  it "kubectl_delete_pod_foo_now" do
    Kube.ctl { delete.pod.foo.now(true) }.to_s.should == "delete pod foo --now"
  end

  it "kubectl_delete_pod_foo_grace_period_0_force" do
    Kube.ctl { delete.pod.foo.grace_period(0).force(true) }.to_s.should == "delete pod foo --grace-period=0 --force"
  end

  it "kubectl_delete_pods_all" do
    Kube.ctl { delete.pods.all(true) }.to_s.should == "delete pods --all"
  end

  it "kubectl_describe_nodes_kubernetes_node_emt8_c_myproject_internal" do
    Kube.ctl { describe.nodes.('kubernetes-node-emt8.c.myproject.internal') }.to_s.should == "describe nodes kubernetes-node-emt8.c.myproject.internal"
  end

  it "kubectl_describe_pods_nginx" do
    Kube.ctl { describe.pods/nginx }.to_s.should == "describe pods/nginx"
  end

  it "kubectl_describe_f_pod_json" do
    Kube.ctl { describe.f 'pod.json' }.to_s.should == "describe -f pod.json"
  end

  it "kubectl_describe_pods" do
    Kube.ctl { describe.pods }.to_s.should == "describe pods"
  end

  it "kubectl_describe_po_l_name_mylabel" do
    Kube.ctl { describe.po.l(name: 'myLabel') }.to_s.should == "describe po -l name=myLabel"
  end

  it "kubectl_describe_pods_frontend" do
    Kube.ctl { describe.pods.frontend }.to_s.should == "describe pods frontend"
  end

  it "kubectl_drain_foo_force" do
    Kube.ctl { drain.foo.force(true) }.to_s.should == "drain foo --force"
  end

  it "kubectl_drain_foo_grace_period_900" do
    Kube.ctl { drain.foo.grace_period(900) }.to_s.should == "drain foo --grace-period=900"
  end

  it "kubectl_edit_svc_docker_registry" do
    Kube.ctl { edit.svc/docker-registry }.to_s.should == "edit svc/docker-registry"
  end

  it "kubectl_edit_job_v1_batch_myjob_o_json" do
    Kube.ctl { edit.job.v1.batch/myjob.o('json') }.to_s.should == "edit job v1 batch/myjob -o json"
  end

  it "kubectl_edit_deployment_mydeployment_o_yaml_save_config" do
    Kube.ctl { edit.deployment/mydeployment.o(:yaml).save_config(true) }.to_s.should == "edit deployment/mydeployment -o yaml --save-config"
  end

      # Skipped: numeric literal 123456-7890 is not valid Ruby syntax
      # def test_kubectl_exec_123456_7890_date
      # def test_kubectl_exec_123456_7890_c_ruby_container_date
      # def test_kubectl_exec_123456_7890_c_ruby_container_i_t_bash_il
      # def test_kubectl_exec_123456_7890_i_t_ls_t_usr

  it "kubectl_explain_pods" do
    Kube.ctl { explain.pods }.to_s.should == "explain pods"
  end

  it "kubectl_explain_pods_spec_containers" do
    Kube.ctl { explain.pods.spec.containers }.to_s.should == "explain pods spec containers"
  end

  it "kubectl_expose_rc_nginx_port_80_target_port_8000" do
    Kube.ctl { expose.rc.nginx.port(80).target_port(8000) }.to_s.should == "expose rc nginx --port=80 --target-port=8000"
  end

  it "kubectl_expose_f_nginx_controller_yaml_port_80_target_port_8000" do
    Kube.ctl { expose.f('nginx-controller.yaml').port(80).target_port(8000) }.to_s.should == "expose -f nginx-controller.yaml --port=80 --target-port=8000"
  end

  it "kubectl_expose_pod_valid_pod_port_444_name_frontend" do
    Kube.ctl { expose.pod.valid-pod.port(444).name(:frontend) }.to_s.should == "expose pod valid-pod --port=444 --name=frontend"
  end

  it "kubectl_expose_service_nginx_port_443_target_port_8443_name_nginx_https" do
    Kube.ctl { expose.service.nginx.port(443).target_port(8443).name('nginx-https') }.to_s.should == "expose service nginx --port=443 --target-port=8443 --name=nginx-https"
  end

  it "kubectl_expose_rc_streamer_port_4100_protocol_udp_name_video_stream" do
    Kube.ctl { expose.rc.streamer.port(4100).protocol(:udp).name('video-stream') }.to_s.should == "expose rc streamer --port=4100 --protocol=udp --name=video-stream"
  end

  it "kubectl_expose_rs_nginx_port_80_target_port_8000" do
    Kube.ctl { expose.rs.nginx.port(80).target_port(8000) }.to_s.should == "expose rs nginx --port=80 --target-port=8000"
  end

  it "kubectl_expose_deployment_nginx_port_80_target_port_8000" do
    Kube.ctl { expose.deployment.nginx.port(80).target_port(8000) }.to_s.should == "expose deployment nginx --port=80 --target-port=8000"
  end

  it "kubectl_get_pods" do
    Kube.ctl { get.pods }.to_s.should == "get pods"
  end

  it "kubectl_get_pods_o_wide" do
    Kube.ctl { get.pods.o(:wide) }.to_s.should == "get pods -o wide"
  end

  it "kubectl_get_replicationcontroller_web" do
    Kube.ctl { get.replicationcontroller.web }.to_s.should == "get replicationcontroller web"
  end

  it "kubectl_get_f_pod_yaml_o_json" do
    Kube.ctl { get.f('pod.yaml').o(:json) }.to_s.should == "get -f pod.yaml -o json"
  end

  it "kubectl_get_rc_services" do
    Kube.ctl { get.('rc,services') }.to_s.should == "get rc,services"
  end

  it "kubectl_get_all" do
    Kube.ctl { get.all }.to_s.should == "get all"
  end

  it "kubectl_label_pods_foo_unhealthy_true" do
    Kube.ctl { label.pods.foo.(unhealthy: 'true') }.to_s.should == "label pods foo unhealthy=true"
  end

  it "kubectl_label_overwrite_pods_foo_status_unhealthy" do
    Kube.ctl { label.overwrite(true).pods.foo.(status: 'unhealthy') }.to_s.should == "label --overwrite pods foo status=unhealthy"
  end

  it "kubectl_label_pods_all_status_unhealthy" do
    Kube.ctl { label.pods.all(true).(status: 'unhealthy') }.to_s.should == "label pods --all status=unhealthy"
  end

  it "kubectl_label_f_pod_json_status_unhealthy" do
    Kube.ctl { label.f('pod.json').(status: 'unhealthy') }.to_s.should == "label -f pod.json status=unhealthy"
  end

  it "kubectl_label_pods_foo_status_unhealthy_resource_version_1" do
    Kube.ctl { label.pods.foo.(status: 'unhealthy').resource_version(1) }.to_s.should == "label pods foo status=unhealthy --resource-version=1"
  end

  it "kubectl_logs_nginx" do
    Kube.ctl { logs.nginx }.to_s.should == "logs nginx"
  end

  it "kubectl_logs_l_app_nginx" do
    Kube.ctl { logs.l(app: :nginx) }.to_s.should == "logs -l app=nginx"
  end

  it "kubectl_logs_p_c_ruby_web_1" do
    Kube.ctl { logs.p(true).c(:ruby).web-1 }.to_s.should == "logs -p -c ruby web-1"
  end

  it "kubectl_logs_f_c_ruby_web_1" do
    Kube.ctl { logs.f(true).c(:ruby).web-1 }.to_s.should == "logs -f -c ruby web-1"
  end

  it "kubectl_logs_tail_20_nginx" do
    Kube.ctl { logs.tail(20).nginx }.to_s.should == "logs --tail=20 nginx"
  end

  it "kubectl_logs_since_1h_nginx" do
    Kube.ctl { logs.since('1h').nginx }.to_s.should == "logs --since=1h nginx"
  end

  it "kubectl_logs_job_hello" do
    Kube.ctl { logs.job/hello }.to_s.should == "logs job/hello"
  end

  it "kubectl_logs_deployment_nginx_c_nginx_1" do
    Kube.ctl { logs.deployment/nginx.c('nginx-1') }.to_s.should == "logs deployment/nginx -c nginx-1"
  end

  it "kubectl_options" do
    Kube.ctl { options }.to_s.should == "options"
  end

  it "kubectl_patch_node_k8s_node_1_p_spec_unschedulable_true" do
    Kube.ctl { patch.node.k8s-node-1.p('\'{"spec":{"unschedulable":true}}\'') }.to_s.should == "patch node k8s-node-1 -p '{\"spec\":{\"unschedulable\":true}}'"
  end

  it "kubectl_patch_f_node_json_p_spec_unschedulable_true" do
    Kube.ctl { patch.f('node.json').p('\'{"spec":{"unschedulable":true}}\'') }.to_s.should == "patch -f node.json -p '{\"spec\":{\"unschedulable\":true}}'"
  end

  it "kubectl_patch_pod_valid_pod_p_spec_containers_name_kubernetes_serve_hostname_image_new_image" do
    Kube.ctl { patch.pod.valid-pod.p('\'{"spec":{"containers":[{"name":"kubernetes-serve-hostname","image":"new image"}]}}\'') }.to_s.should == "patch pod valid-pod -p '{\"spec\":{\"containers\":[{\"name\":\"kubernetes-serve-hostname\",\"image\":\"new image\"}]}}'"
  end

  it "kubectl_patch_pod_valid_pod_type_json_p_op_replace_path_spec_containers_0_image_value_new_image" do
    Kube.ctl { patch.pod.valid-pod.type("'json'").p("'[{\"op\": \"replace\", \"path\": \"/spec/containers/0/image\", \"value\":\"new image\"}]'") }.to_s.should == "patch pod valid-pod --type='json' -p '[{\"op\": \"replace\", \"path\": \"/spec/containers/0/image\", \"value\":\"new image\"}]'"
  end

  it "kubectl_port_forward_mypod_5000_6000" do
    Kube.ctl { port-forward.mypod.('5000').('6000') }.to_s.should == "port-forward mypod 5000 6000"
  end

  it "kubectl_port_forward_mypod_8888_5000" do
    Kube.ctl { port-forward.mypod.('8888:5000') }.to_s.should == "port-forward mypod 8888:5000"
  end

  it "kubectl_port_forward_mypod_5000" do
    Kube.ctl { port-forward.mypod.(':5000') }.to_s.should == "port-forward mypod :5000"
  end

  it "kubectl_port_forward_mypod_0_5000" do
    Kube.ctl { port-forward.mypod.('0:5000') }.to_s.should == "port-forward mypod 0:5000"
  end

  it "kubectl_proxy_api_prefix" do
    Kube.ctl { proxy.api_prefix('/') }.to_s.should == "proxy --api-prefix=/"
  end

  it "kubectl_proxy_www_my_files_www_prefix_static_api_prefix_api" do
    Kube.ctl { proxy.www('/my/files').www_prefix('/static/').api_prefix('/api/') }.to_s.should == "proxy --www=/my/files --www-prefix=/static/ --api-prefix=/api/"
  end

  it "kubectl_proxy_api_prefix_custom" do
    Kube.ctl { proxy.api_prefix('/custom/') }.to_s.should == "proxy --api-prefix=/custom/"
  end

  it "kubectl_proxy_port_8011_www_local_www" do
    Kube.ctl { proxy.port(8011).www('./local/www/') }.to_s.should == "proxy --port=8011 --www=./local/www/"
  end

  it "kubectl_proxy_port_0" do
    Kube.ctl { proxy.port(0) }.to_s.should == "proxy --port=0"
  end

  it "kubectl_proxy_api_prefix_k8s_api" do
    Kube.ctl { proxy.api_prefix('/k8s-api') }.to_s.should == "proxy --api-prefix=/k8s-api"
  end

  it "kubectl_replace_f_pod_json" do
    Kube.ctl { replace.f './pod.json' }.to_s.should == "replace -f ./pod.json"
  end

  it "kubectl_replace_force_f_pod_json" do
    Kube.ctl { replace.force(true).f './pod.json' }.to_s.should == "replace --force -f ./pod.json"
  end

  it "kubectl_scale_replicas_3_rs_foo" do
    Kube.ctl { scale.replicas(3).rs/foo }.to_s.should == "scale --replicas=3 rs/foo"
  end

  it "kubectl_scale_replicas_3_f_foo_yaml" do
    Kube.ctl { scale.replicas(3).f 'foo.yaml' }.to_s.should == "scale --replicas=3 -f foo.yaml"
  end

  it "kubectl_scale_current_replicas_2_replicas_3_deployment_mysql" do
    Kube.ctl { scale.current_replicas(2).replicas(3).deployment/mysql }.to_s.should == "scale --current-replicas=2 --replicas=3 deployment/mysql"
  end

  it "kubectl_scale_replicas_5_rc_foo_rc_bar_rc_baz" do
    Kube.ctl { scale.replicas(5).rc/foo.rc/bar.rc/baz }.to_s.should == "scale --replicas=5 rc/foo rc/bar rc/baz"
  end

  it "kubectl_scale_replicas_3_job_cron" do
    Kube.ctl { scale.replicas(3).job/cron }.to_s.should == "scale --replicas=3 job/cron"
  end

  it "kubectl_rolling_update_frontend_v1_f_frontend_v2_json" do
    Kube.ctl { rolling-update.frontend-v1.f('frontend-v2.json') }.to_s.should == "rolling-update frontend-v1 -f frontend-v2.json"
  end

  it "kubectl_rolling_update_frontend_v1_frontend_v2_image_image_v2" do
    Kube.ctl { rolling-update.frontend-v1.frontend-v2.image('image:v2') }.to_s.should == "rolling-update frontend-v1 frontend-v2 --image=image:v2"
  end

  it "kubectl_rolling_update_frontend_image_image_v2" do
    Kube.ctl { rolling-update.frontend.image('image:v2') }.to_s.should == "rolling-update frontend --image=image:v2"
  end

  it "kubectl_rolling_update_frontend_v1_frontend_v2_rollback" do
    Kube.ctl { rolling-update.frontend-v1.frontend-v2.rollback(true) }.to_s.should == "rolling-update frontend-v1 frontend-v2 --rollback"
  end

  it "kubectl_rollout_undo_deployment_abc" do
    Kube.ctl { rollout.undo.deployment/abc }.to_s.should == "rollout undo deployment/abc"
  end

  it "kubectl_rollout_status_daemonset_foo" do
    Kube.ctl { rollout.status.daemonset/foo }.to_s.should == "rollout status daemonset/foo"
  end

  it "kubectl_rollout_history_deployment_abc" do
    Kube.ctl { rollout.history.deployment/abc }.to_s.should == "rollout history deployment/abc"
  end

  it "kubectl_rollout_history_daemonset_abc_revision_3" do
    Kube.ctl { rollout.history.daemonset/abc.revision(3) }.to_s.should == "rollout history daemonset/abc --revision=3"
  end

  it "kubectl_rollout_pause_deployment_nginx" do
    Kube.ctl { rollout.pause.deployment/nginx }.to_s.should == "rollout pause deployment/nginx"
  end

  it "kubectl_rollout_resume_deployment_nginx" do
    Kube.ctl { rollout.resume.deployment/nginx }.to_s.should == "rollout resume deployment/nginx"
  end

  it "kubectl_rollout_status_deployment_nginx" do
    Kube.ctl { rollout.status.deployment/nginx }.to_s.should == "rollout status deployment/nginx"
  end

  it "kubectl_rollout_undo_daemonset_abc_to_revision_3" do
    Kube.ctl { rollout.undo.daemonset/abc.to_revision(3) }.to_s.should == "rollout undo daemonset/abc --to-revision=3"
  end

  it "kubectl_rollout_undo_dry_run_true_deployment_abc" do
    Kube.ctl { rollout.undo.dry_run(true).deployment/abc }.to_s.should == "rollout undo --dry-run deployment/abc"
  end

  it "kubectl_run_nginx_image_nginx" do
    Kube.ctl { run.nginx.image(:nginx) }.to_s.should == "run nginx --image=nginx"
  end

  it "kubectl_run_hazelcast_image_hazelcast_port_5701" do
    Kube.ctl { run.hazelcast.image(:hazelcast).port(5701) }.to_s.should == "run hazelcast --image=hazelcast --port=5701"
  end

  it "kubectl_run_hazelcast_image_hazelcast_env_dns_domain_cluster_env_pod_namespace_default" do
    Kube.ctl { run.hazelcast.image(:hazelcast).env('"DNS_DOMAIN=cluster"').env('"POD_NAMESPACE=default"') }.to_s.should == "run hazelcast --image=hazelcast --env=\"DNS_DOMAIN=cluster\" --env=\"POD_NAMESPACE=default\""
  end

  it "kubectl_run_nginx_image_nginx_replicas_5" do
    Kube.ctl { run.nginx.image(:nginx).replicas(5) }.to_s.should == "run nginx --image=nginx --replicas=5"
  end

  it "kubectl_run_nginx_image_nginx_dry_run" do
    Kube.ctl { run.nginx.image(:nginx).dry_run(true) }.to_s.should == "run nginx --image=nginx --dry-run"
  end

  it "kubectl_run_nginx_image_nginx_overrides_apiversion_v1_spec" do
    Kube.ctl { run.nginx.image(:nginx).overrides("'{ \"apiVersion\": \"v1\", \"spec\": { ... } }'") }.to_s.should == "run nginx --image=nginx --overrides='{ \"apiVersion\": \"v1\", \"spec\": { ... } }'"
  end

  it "kubectl_run_i_t_busybox_image_busybox_restart_never" do
    Kube.ctl { run.i(true).t(true).busybox.image(:busybox).restart('Never') }.to_s.should == "run -i -t busybox --image=busybox --restart=Never"
  end

  it "kubectl_run_nginx_image_nginx_arg1_arg2_argn" do
    Kube.ctl { run.nginx.image(:nginx).('-- <arg1> <arg2> ... <argN>') }.to_s.should == "run nginx --image=nginx -- <arg1> <arg2> ... <argN>"
  end

  it "kubectl_run_nginx_image_nginx_command_cmd_arg1_argn" do
    Kube.ctl { run.nginx.image(:nginx).command(true).('-- <cmd> <arg1> ... <argN>') }.to_s.should == "run nginx --image=nginx --command -- <cmd> <arg1> ... <argN>"
  end

  it "kubectl_run_pi_image_perl_restart_onfailure_perl_mbignum_bpi_wle_print_bpi_2000" do
    Kube.ctl { run.pi.image(:perl).restart('OnFailure').("-- perl -Mbignum=bpi -wle 'print bpi(2000)'") }.to_s.should == "run pi --image=perl --restart=OnFailure -- perl -Mbignum=bpi -wle 'print bpi(2000)'"
  end

  it "kubectl_run_pi_schedule_0_5_image_perl_restart_onfailure_perl_mbignum_bpi_wle_print_bpi_2000" do
    Kube.ctl { run.pi.schedule('"0/5 * * * ?"').image(:perl).restart('OnFailure').("-- perl -Mbignum=bpi -wle 'print bpi(2000)'") }.to_s.should == "run pi --schedule=\"0/5 * * * ?\" --image=perl --restart=OnFailure -- perl -Mbignum=bpi -wle 'print bpi(2000)'"
  end

  it "kubectl_set_image_deployment_nginx_busybox_busybox_nginx_nginx_1_9_1" do
    Kube.ctl { set.image.deployment/nginx.('busybox=busybox').('nginx=nginx:1.9.1') }.to_s.should == "set image deployment/nginx busybox=busybox nginx=nginx:1.9.1"
  end

  it "kubectl_set_image_deployments_rc_nginx_nginx_1_9_1_all" do
    Kube.ctl { set.image.('deployments,rc').('nginx=nginx:1.9.1').all(true) }.to_s.should == "set image deployments,rc nginx=nginx:1.9.1 --all"
  end

  it "kubectl_set_image_daemonset_abc_nginx_1_9_1" do
    Kube.ctl { set.image.daemonset.abc.('*=nginx:1.9.1') }.to_s.should == "set image daemonset abc *=nginx:1.9.1"
  end

  it "kubectl_set_image_f_path_to_file_yaml_nginx_nginx_1_9_1_local_o_yaml" do
    Kube.ctl { set.image.f('path/to/file.yaml').('nginx=nginx:1.9.1').local(true).o(:yaml) }.to_s.should == "set image -f path/to/file.yaml nginx=nginx:1.9.1 --local -o yaml"
  end

  it "kubectl_set_resources_deployment_nginx_c_nginx_limits_cpu_200m_memory_512mi" do
    Kube.ctl { set.resources.deployment.nginx.c(:nginx).limits('cpu=200m,memory=512Mi') }.to_s.should == "set resources deployment nginx -c nginx --limits=cpu=200m,memory=512Mi"
  end

  it "kubectl_set_resources_deployment_nginx_limits_cpu_200m_memory_512mi_requests_cpu_100m_memory_256mi" do
    Kube.ctl { set.resources.deployment.nginx.limits('cpu=200m,memory=512Mi').requests('cpu=100m,memory=256Mi') }.to_s.should == "set resources deployment nginx --limits=cpu=200m,memory=512Mi --requests=cpu=100m,memory=256Mi"
  end

  it "kubectl_set_resources_deployment_nginx_limits_cpu_0_memory_0_requests_cpu_0_memory_0" do
    Kube.ctl { set.resources.deployment.nginx.limits('cpu=0,memory=0').requests('cpu=0,memory=0') }.to_s.should == "set resources deployment nginx --limits=cpu=0,memory=0 --requests=cpu=0,memory=0"
  end

  it "kubectl_set_resources_f_path_to_file_yaml_limits_cpu_200m_memory_512mi_local_o_yaml" do
    Kube.ctl { set.resources.f('path/to/file.yaml').limits('cpu=200m,memory=512Mi').local(true).o(:yaml) }.to_s.should == "set resources -f path/to/file.yaml --limits=cpu=200m,memory=512Mi --local -o yaml"
  end

  it "kubectl_set_subject_clusterrolebinding_admin_serviceaccount_namespace_serviceaccount1" do
    Kube.ctl { set.subject.clusterrolebinding.admin.serviceaccount('namespace:serviceaccount1') }.to_s.should == "set subject clusterrolebinding admin --serviceaccount=namespace:serviceaccount1"
  end

  it "kubectl_set_subject_rolebinding_admin_user_user1_user_user2_group_group1" do
    Kube.ctl { set.subject.rolebinding.admin.user('user1').user('user2').group('group1') }.to_s.should == "set subject rolebinding admin --user=user1 --user=user2 --group=group1"
  end

  it "kubectl_stop_replicationcontroller_foo" do
    Kube.ctl { stop.replicationcontroller.foo }.to_s.should == "stop replicationcontroller foo"
  end

  it "kubectl_stop_pods_services_l_name_mylabel" do
    Kube.ctl { stop.('pods,services').l(name: 'myLabel') }.to_s.should == "stop pods,services -l name=myLabel"
  end

  it "kubectl_stop_f_service_json" do
    Kube.ctl { stop.f 'service.json' }.to_s.should == "stop -f service.json"
  end

  it "kubectl_stop_f_path_to_resources" do
    Kube.ctl { stop.f 'path/to/resources' }.to_s.should == "stop -f path/to/resources"
  end

  it "kubectl_taint_nodes_foo_dedicated_special_user_noschedule" do
    Kube.ctl { taint.nodes.foo.(dedicated: 'special-user:NoSchedule') }.to_s.should == "taint nodes foo dedicated=special-user:NoSchedule"
  end

  it "kubectl_taint_node_l_mylabel_x_dedicated_foo_prefernoschedule" do
    Kube.ctl { taint.node.l(myLabel: 'X', dedicated: "foo:PreferNoSchedule")}.to_s.should == "taint node -l myLabel=X dedicated=foo:PreferNoSchedule"
  end

  it "kubectl_top_node" do
    Kube.ctl { top.node }.to_s.should == "top node"
  end

  it "kubectl_top_node_node_name" do
    Kube.ctl { top.node.NODE_NAME }.to_s.should == "top node NODE_NAME"
  end

  it "kubectl_top_pod" do
    Kube.ctl { top.pod }.to_s.should == "top pod"
  end

  it "kubectl_top_pod_namespace_namespace" do
    Kube.ctl { top.pod.namespace('NAMESPACE') }.to_s.should == "top pod --namespace=NAMESPACE"
  end

  it "kubectl_top_pod_pod_name_containers" do
    Kube.ctl { top.pod.POD_NAME.containers(true) }.to_s.should == "top pod POD_NAME --containers"
  end

  it "kubectl_top_pod_l_name_mylabel" do
    Kube.ctl { top.pod.l(name: 'myLabel') }.to_s.should == "top pod -l name=myLabel"
  end

  it "kubectl_uncordon_foo" do
    Kube.ctl { uncordon.foo }.to_s.should == "uncordon foo"
  end

  it "kubectl_get_pod_mypod_o_yaml" do
    Kube.ctl { get.pod.mypod.o :yaml }.to_s.should == "get pod mypod -o yaml"
  end

  it "kubectl_version" do
    Kube.ctl { version }.to_s.should == "version"
  end

end
