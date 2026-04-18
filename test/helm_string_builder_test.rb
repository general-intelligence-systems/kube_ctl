# frozen_string_literal: true

require "test_helper"

class HelmStringBuilderTest < Minitest::Test
  def sb(&block)
    Kube.helm(&block)
  end

  def assert_buffer(result, expected)
    assert_equal expected, result.to_a
  end

  def assert_string(result, expected)
    assert_equal expected, result.to_s
  end

  # --- helm completion bash ---

  def test_helm_completion_bash
    result = sb { completion.bash }
    assert_buffer(result, [["completion", []], ["bash", []]])
    assert_string(result, "completion bash")
  end

  def test_helm_completion_bash_no_descriptions
    result = sb { completion.bash.no_descriptions(true) }
    assert_buffer(result, [["completion", []], ["bash", []], ["no_descriptions", [true]]])
    assert_string(result, "completion bash --no-descriptions")
  end

  # --- helm completion zsh ---

  def test_helm_completion_zsh
    result = sb { completion.zsh }
    assert_buffer(result, [["completion", []], ["zsh", []]])
    assert_string(result, "completion zsh")
  end

  def test_helm_completion_zsh_no_descriptions
    result = sb { completion.zsh.no_descriptions(true) }
    assert_buffer(result, [["completion", []], ["zsh", []], ["no_descriptions", [true]]])
    assert_string(result, "completion zsh --no-descriptions")
  end

  # --- helm completion fish ---

  def test_helm_completion_fish
    result = sb { completion.fish }
    assert_buffer(result, [["completion", []], ["fish", []]])
    assert_string(result, "completion fish")
  end

  def test_helm_completion_fish_no_descriptions
    result = sb { completion.fish.no_descriptions(true) }
    assert_buffer(result, [["completion", []], ["fish", []], ["no_descriptions", [true]]])
    assert_string(result, "completion fish --no-descriptions")
  end

  # --- helm completion powershell ---

  def test_helm_completion_powershell
    result = sb { completion.powershell }
    assert_buffer(result, [["completion", []], ["powershell", []]])
    assert_string(result, "completion powershell")
  end

  def test_helm_completion_powershell_no_descriptions
    result = sb { completion.powershell.no_descriptions(true) }
    assert_buffer(result, [["completion", []], ["powershell", []], ["no_descriptions", [true]]])
    assert_string(result, "completion powershell --no-descriptions")
  end

  # --- helm create ---

  def test_helm_create_mychart
    result = sb { create.mychart }
    assert_buffer(result, [["create", []], ["mychart", []]])
    assert_string(result, "create mychart")
  end

  def test_helm_create_mychart_starter
    result = sb { create.mychart.p('my-starter') }
    assert_buffer(result, [["create", []], ["mychart", []], ["p", ["my-starter"]]])
    assert_string(result, "create mychart -p my-starter")
  end

  def test_helm_create_mychart_starter_long
    result = sb { create.mychart.starter('my-starter') }
    assert_buffer(result, [["create", []], ["mychart", []], ["starter", ["my-starter"]]])
    assert_string(result, "create mychart --starter=my-starter")
  end

  # --- helm dependency build ---

  def test_helm_dependency_build
    result = sb { dependency.build.("CHART") }
    assert_buffer(result, [["dependency", []], ["build", []], ["CHART", []]])
    assert_string(result, "dependency build CHART")
  end

  # --- helm dependency list ---

  def test_helm_dependency_list
    result = sb { dependency.list.("CHART") }
    assert_buffer(result, [["dependency", []], ["list", []], ["CHART", []]])
    assert_string(result, "dependency list CHART")
  end

  # --- helm dependency update ---

  def test_helm_dependency_update
    result = sb { dependency.update.("CHART") }
    assert_buffer(result, [["dependency", []], ["update", []], ["CHART", []]])
    assert_string(result, "dependency update CHART")
  end

  # --- helm env ---

  def test_helm_env
    result = sb { env }
    assert_buffer(result, [["env", []]])
    assert_string(result, "env")
  end

  # --- helm get all ---

  def test_helm_get_all
    result = sb { get.all.("RELEASE_NAME") }
    assert_buffer(result, [["get", []], ["all", []], ["RELEASE_NAME", []]])
    assert_string(result, "get all RELEASE_NAME")
  end

  # --- helm get hooks ---

  def test_helm_get_hooks
    result = sb { get.hooks.("RELEASE_NAME") }
    assert_buffer(result, [["get", []], ["hooks", []], ["RELEASE_NAME", []]])
    assert_string(result, "get hooks RELEASE_NAME")
  end

  # --- helm get manifest ---

  def test_helm_get_manifest
    result = sb { get.manifest.("RELEASE_NAME") }
    assert_buffer(result, [["get", []], ["manifest", []], ["RELEASE_NAME", []]])
    assert_string(result, "get manifest RELEASE_NAME")
  end

  # --- helm get metadata ---

  def test_helm_get_metadata
    result = sb { get.metadata.("RELEASE_NAME") }
    assert_buffer(result, [["get", []], ["metadata", []], ["RELEASE_NAME", []]])
    assert_string(result, "get metadata RELEASE_NAME")
  end

  # --- helm get notes ---

  def test_helm_get_notes
    result = sb { get.notes.("RELEASE_NAME") }
    assert_buffer(result, [["get", []], ["notes", []], ["RELEASE_NAME", []]])
    assert_string(result, "get notes RELEASE_NAME")
  end

  # --- helm get values ---

  def test_helm_get_values
    result = sb { get.values.("RELEASE_NAME") }
    assert_buffer(result, [["get", []], ["values", []], ["RELEASE_NAME", []]])
    assert_string(result, "get values RELEASE_NAME")
  end

  # --- helm history ---

  def test_helm_history
    result = sb { history.("RELEASE_NAME") }
    assert_buffer(result, [["history", []], ["RELEASE_NAME", []]])
    assert_string(result, "history RELEASE_NAME")
  end

  def test_helm_history_angry_bird
    result = sb { history.angry-bird }
    assert_buffer(result, [["history", []], ["angry", []], :dash, ["bird", []]])
    assert_string(result, "history angry-bird")
  end

  # --- helm install ---

  def test_helm_install_f_myvalues_yaml_myredis_redis
    result = sb { install.f('myvalues.yaml').myredis.("./redis") }
    assert_buffer(result, [["install", []], ["f", ["myvalues.yaml"]], ["myredis", []], ["./redis", []]])
    assert_string(result, "install -f myvalues.yaml myredis ./redis")
  end

  def test_helm_install_set_name_prod_myredis_redis
    result = sb { install.set('name=prod').myredis.("./redis") }
    assert_buffer(result, [["install", []], ["set", ["name=prod"]], ["myredis", []], ["./redis", []]])
    assert_string(result, "install --set=name=prod myredis ./redis")
  end

  def test_helm_install_set_string_long_int_myredis_redis
    result = sb { install.set_string('long_int=1234567890').myredis.("./redis") }
    assert_buffer(result, [["install", []], ["set_string", ["long_int=1234567890"]], ["myredis", []], ["./redis", []]])
    assert_string(result, "install --set-string=long_int=1234567890 myredis ./redis")
  end

  def test_helm_install_set_file_my_script_myredis_redis
    result = sb { install.set_file('my_script=dothings.sh').myredis.("./redis") }
    assert_buffer(result, [["install", []], ["set_file", ["my_script=dothings.sh"]], ["myredis", []], ["./redis", []]])
    assert_string(result, "install --set-file=my_script=dothings.sh myredis ./redis")
  end

  def test_helm_install_f_myvalues_yaml_f_override_yaml_myredis_redis
    result = sb { install.f('myvalues.yaml').f('override.yaml').myredis.("./redis") }
    assert_buffer(result, [["install", []], ["f", ["myvalues.yaml"]], ["f", ["override.yaml"]], ["myredis", []], ["./redis", []]])
    assert_string(result, "install -f myvalues.yaml -f override.yaml myredis ./redis")
  end

  def test_helm_install_set_foo_bar_set_foo_newbar_myredis_redis
    result = sb { install.set('foo=bar').set('foo=newbar').myredis.("./redis") }
    assert_buffer(result, [["install", []], ["set", ["foo=bar"]], ["set", ["foo=newbar"]], ["myredis", []], ["./redis", []]])
    assert_string(result, "install --set=foo=bar --set=foo=newbar myredis ./redis")
  end

  def test_helm_install_mymaria_example_mariadb
    result = sb { install.mymaria.("example/mariadb") }
    assert_buffer(result, [["install", []], ["mymaria", []], ["example/mariadb", []]])
    assert_string(result, "install mymaria example/mariadb")
  end

  def test_helm_install_mynginx_tgz
    result = sb { install.mynginx.("./nginx-1.2.3.tgz") }
    assert_buffer(result, [["install", []], ["mynginx", []], ["./nginx-1.2.3.tgz", []]])
    assert_string(result, "install mynginx ./nginx-1.2.3.tgz")
  end

  def test_helm_install_mynginx_local_dir
    result = sb { install.mynginx.("./nginx") }
    assert_buffer(result, [["install", []], ["mynginx", []], ["./nginx", []]])
    assert_string(result, "install mynginx ./nginx")
  end

  def test_helm_install_mynginx_url
    result = sb { install.mynginx.("https://example.com/charts/nginx-1.2.3.tgz") }
    assert_buffer(result, [["install", []], ["mynginx", []], ["https://example.com/charts/nginx-1.2.3.tgz", []]])
    assert_string(result, "install mynginx https://example.com/charts/nginx-1.2.3.tgz")
  end

  def test_helm_install_repo_mynginx_nginx
    result = sb { install.repo('https://example.com/charts/').mynginx.nginx }
    assert_buffer(result, [["install", []], ["repo", ["https://example.com/charts/"]], ["mynginx", []], ["nginx", []]])
    assert_string(result, "install --repo=https://example.com/charts/ mynginx nginx")
  end

  def test_helm_install_mynginx_version_oci
    result = sb { install.mynginx.version('1.2.3').("oci://example.com/charts/nginx") }
    assert_buffer(result, [["install", []], ["mynginx", []], ["version", ["1.2.3"]], ["oci://example.com/charts/nginx", []]])
    assert_string(result, "install mynginx --version=1.2.3 oci://example.com/charts/nginx")
  end

  # --- helm lint ---

  def test_helm_lint
    result = sb { lint.("PATH") }
    assert_buffer(result, [["lint", []], ["PATH", []]])
    assert_string(result, "lint PATH")
  end

  # --- helm list ---

  def test_helm_list
    result = sb { list }
    assert_buffer(result, [["list", []]])
    assert_string(result, "list")
  end

  def test_helm_list_filter
    result = sb { list.filter('ara[a-z]+') }
    assert_buffer(result, [["list", []], ["filter", ["ara[a-z]+"]]])
    assert_string(result, "list --filter=ara[a-z]+")
  end

  # --- helm package ---

  def test_helm_package
    result = sb { package.("./mychart") }
    assert_buffer(result, [["package", []], ["./mychart", []]])
    assert_string(result, "package ./mychart")
  end

  def test_helm_package_sign
    result = sb { package.sign(true).("./mychart").key('mykey').keyring('~/.gnupg/secring.gpg') }
    assert_buffer(result, [["package", []], ["sign", [true]], ["./mychart", []], ["key", ["mykey"]], ["keyring", ["~/.gnupg/secring.gpg"]]])
    assert_string(result, "package --sign ./mychart --key=mykey --keyring=~/.gnupg/secring.gpg")
  end

  # --- helm plugin install ---

  def test_helm_plugin_install
    result = sb { plugin.install.("https://example.com/plugin") }
    assert_buffer(result, [["plugin", []], ["install", []], ["https://example.com/plugin", []]])
    assert_string(result, "plugin install https://example.com/plugin")
  end

  # --- helm plugin list ---

  def test_helm_plugin_list
    result = sb { plugin.list }
    assert_buffer(result, [["plugin", []], ["list", []]])
    assert_string(result, "plugin list")
  end

  # --- helm plugin package ---

  def test_helm_plugin_package
    result = sb { plugin.package.("PATH") }
    assert_buffer(result, [["plugin", []], ["package", []], ["PATH", []]])
    assert_string(result, "plugin package PATH")
  end

  # --- helm plugin uninstall ---

  def test_helm_plugin_uninstall
    result = sb { plugin.uninstall.("my-plugin") }
    assert_buffer(result, [["plugin", []], ["uninstall", []], ["my-plugin", []]])
    assert_string(result, "plugin uninstall my-plugin")
  end

  # --- helm plugin update ---

  def test_helm_plugin_update
    result = sb { plugin.update.("my-plugin") }
    assert_buffer(result, [["plugin", []], ["update", []], ["my-plugin", []]])
    assert_string(result, "plugin update my-plugin")
  end

  # --- helm plugin verify ---

  def test_helm_plugin_verify
    result = sb { plugin.verify.("PATH") }
    assert_buffer(result, [["plugin", []], ["verify", []], ["PATH", []]])
    assert_string(result, "plugin verify PATH")
  end

  def test_helm_plugin_verify_example
    result = sb { plugin.verify.("~/.local/share/helm/plugins/example-cli") }
    assert_buffer(result, [["plugin", []], ["verify", []], ["~/.local/share/helm/plugins/example-cli", []]])
    assert_string(result, "plugin verify ~/.local/share/helm/plugins/example-cli")
  end

  # --- helm pull ---

  def test_helm_pull
    result = sb { pull.("repo/chartname") }
    assert_buffer(result, [["pull", []], ["repo/chartname", []]])
    assert_string(result, "pull repo/chartname")
  end

  # --- helm push ---

  def test_helm_push
    result = sb { push.("mychart-0.1.0.tgz").("oci://localhost:5000/helm-charts") }
    assert_buffer(result, [["push", []], ["mychart-0.1.0.tgz", []], ["oci://localhost:5000/helm-charts", []]])
    assert_string(result, "push mychart-0.1.0.tgz oci://localhost:5000/helm-charts")
  end

  # --- helm registry login ---

  def test_helm_registry_login
    result = sb { registry.login.("localhost:5000") }
    assert_buffer(result, [["registry", []], ["login", []], ["localhost:5000", []]])
    assert_string(result, "registry login localhost:5000")
  end

  # --- helm registry logout ---

  def test_helm_registry_logout
    result = sb { registry.logout.("localhost:5000") }
    assert_buffer(result, [["registry", []], ["logout", []], ["localhost:5000", []]])
    assert_string(result, "registry logout localhost:5000")
  end

  # --- helm repo add ---

  def test_helm_repo_add
    result = sb { repo.add.("bitnami").("https://charts.bitnami.com/bitnami") }
    assert_buffer(result, [["repo", []], ["add", []], ["bitnami", []], ["https://charts.bitnami.com/bitnami", []]])
    assert_string(result, "repo add bitnami https://charts.bitnami.com/bitnami")
  end

  # --- helm repo index ---

  def test_helm_repo_index
    result = sb { repo.index.("DIR") }
    assert_buffer(result, [["repo", []], ["index", []], ["DIR", []]])
    assert_string(result, "repo index DIR")
  end

  # --- helm repo list ---

  def test_helm_repo_list
    result = sb { repo.list }
    assert_buffer(result, [["repo", []], ["list", []]])
    assert_string(result, "repo list")
  end

  # --- helm repo remove ---

  def test_helm_repo_remove
    result = sb { repo.remove.("bitnami") }
    assert_buffer(result, [["repo", []], ["remove", []], ["bitnami", []]])
    assert_string(result, "repo remove bitnami")
  end

  # --- helm repo update ---

  def test_helm_repo_update
    result = sb { repo.update }
    assert_buffer(result, [["repo", []], ["update", []]])
    assert_string(result, "repo update")
  end

  def test_helm_repo_update_with_name
    result = sb { repo.update.("my-repo") }
    assert_buffer(result, [["repo", []], ["update", []], ["my-repo", []]])
    assert_string(result, "repo update my-repo")
  end

  # --- helm rollback ---

  def test_helm_rollback
    result = sb { rollback.("my-release").("2") }
    assert_buffer(result, [["rollback", []], ["my-release", []], ["2", []]])
    assert_string(result, "rollback my-release 2")
  end

  # --- helm search hub ---

  def test_helm_search_hub
    result = sb { search.hub.("nginx") }
    assert_buffer(result, [["search", []], ["hub", []], ["nginx", []]])
    assert_string(result, "search hub nginx")
  end

  # --- helm search repo ---

  def test_helm_search_repo
    result = sb { search.repo.("nginx") }
    assert_buffer(result, [["search", []], ["repo", []], ["nginx", []]])
    assert_string(result, "search repo nginx")
  end

  def test_helm_search_repo_devel
    result = sb { search.repo.("nginx").devel(true) }
    assert_buffer(result, [["search", []], ["repo", []], ["nginx", []], ["devel", [true]]])
    assert_string(result, "search repo nginx --devel")
  end

  def test_helm_search_repo_version
    result = sb { search.repo.("nginx-ingress").version('^1.0.0') }
    assert_buffer(result, [["search", []], ["repo", []], ["nginx-ingress", []], ["version", ["^1.0.0"]]])
    assert_string(result, "search repo nginx-ingress --version=^1.0.0")
  end

  # --- helm show all ---

  def test_helm_show_all
    result = sb { show.all.("bitnami/nginx") }
    assert_buffer(result, [["show", []], ["all", []], ["bitnami/nginx", []]])
    assert_string(result, "show all bitnami/nginx")
  end

  # --- helm show chart ---

  def test_helm_show_chart
    result = sb { show.chart.("bitnami/nginx") }
    assert_buffer(result, [["show", []], ["chart", []], ["bitnami/nginx", []]])
    assert_string(result, "show chart bitnami/nginx")
  end

  # --- helm show crds ---

  def test_helm_show_crds
    result = sb { show.crds.("bitnami/nginx") }
    assert_buffer(result, [["show", []], ["crds", []], ["bitnami/nginx", []]])
    assert_string(result, "show crds bitnami/nginx")
  end

  # --- helm show readme ---

  def test_helm_show_readme
    result = sb { show.readme.("bitnami/nginx") }
    assert_buffer(result, [["show", []], ["readme", []], ["bitnami/nginx", []]])
    assert_string(result, "show readme bitnami/nginx")
  end

  # --- helm show values ---

  def test_helm_show_values
    result = sb { show.values.("bitnami/nginx") }
    assert_buffer(result, [["show", []], ["values", []], ["bitnami/nginx", []]])
    assert_string(result, "show values bitnami/nginx")
  end

  # --- helm status ---

  def test_helm_status
    result = sb { status.("RELEASE_NAME") }
    assert_buffer(result, [["status", []], ["RELEASE_NAME", []]])
    assert_string(result, "status RELEASE_NAME")
  end

  # --- helm template ---

  def test_helm_template
    result = sb { template.my_release.("bitnami/nginx") }
    assert_buffer(result, [["template", []], ["my_release", []], ["bitnami/nginx", []]])
    assert_string(result, "template my_release bitnami/nginx")
  end

  def test_helm_template_api_versions
    result = sb { template.api_versions('networking.k8s.io/v1').api_versions('cert-manager.io/v1').mychart.("./mychart") }
    assert_buffer(result, [["template", []], ["api_versions", ["networking.k8s.io/v1"]], ["api_versions", ["cert-manager.io/v1"]], ["mychart", []], ["./mychart", []]])
    assert_string(result, "template --api-versions=networking.k8s.io/v1 --api-versions=cert-manager.io/v1 mychart ./mychart")
  end

  def test_helm_template_api_versions_comma
    result = sb { template.api_versions('networking.k8s.io/v1', 'cert-manager.io/v1').mychart.("./mychart") }
    assert_buffer(result, [["template", []], ["api_versions", ["networking.k8s.io/v1", "cert-manager.io/v1"]], ["mychart", []], ["./mychart", []]])
    assert_string(result, "template --api-versions=networking.k8s.io/v1,cert-manager.io/v1 mychart ./mychart")
  end

  # --- helm test ---

  def test_helm_test
    result = sb { test.("RELEASE") }
    assert_buffer(result, [["test", []], ["RELEASE", []]])
    assert_string(result, "test RELEASE")
  end

  # --- helm uninstall ---

  def test_helm_uninstall
    result = sb { uninstall.("RELEASE_NAME") }
    assert_buffer(result, [["uninstall", []], ["RELEASE_NAME", []]])
    assert_string(result, "uninstall RELEASE_NAME")
  end

  # --- helm upgrade ---

  def test_helm_upgrade_f_myvalues_yaml_f_override_yaml_redis
    result = sb { upgrade.f('myvalues.yaml').f('override.yaml').redis.("./redis") }
    assert_buffer(result, [["upgrade", []], ["f", ["myvalues.yaml"]], ["f", ["override.yaml"]], ["redis", []], ["./redis", []]])
    assert_string(result, "upgrade -f myvalues.yaml -f override.yaml redis ./redis")
  end

  def test_helm_upgrade_set_foo_bar_set_foo_newbar_redis
    result = sb { upgrade.set('foo=bar').set('foo=newbar').redis.("./redis") }
    assert_buffer(result, [["upgrade", []], ["set", ["foo=bar"]], ["set", ["foo=newbar"]], ["redis", []], ["./redis", []]])
    assert_string(result, "upgrade --set=foo=bar --set=foo=newbar redis ./redis")
  end

  def test_helm_upgrade_reuse_values_set_foo_bar_set_foo_newbar_redis
    result = sb { upgrade.reuse_values(true).set('foo=bar').set('foo=newbar').redis.("./redis") }
    assert_buffer(result, [["upgrade", []], ["reuse_values", [true]], ["set", ["foo=bar"]], ["set", ["foo=newbar"]], ["redis", []], ["./redis", []]])
    assert_string(result, "upgrade --reuse-values --set=foo=bar --set=foo=newbar redis ./redis")
  end

  # --- helm verify ---

  def test_helm_verify
    result = sb { verify.("PATH") }
    assert_buffer(result, [["verify", []], ["PATH", []]])
    assert_string(result, "verify PATH")
  end

  # --- helm version ---

  def test_helm_version
    result = sb { version }
    assert_buffer(result, [["version", []]])
    assert_string(result, "version")
  end
end
