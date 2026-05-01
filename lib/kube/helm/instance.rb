# frozen_string_literal: true


module Kube
  module Helm
    class Instance
      attr_reader :kubeconfig

      def initialize(kubeconfig: ENV['KUBECONFIG'])
        @kubeconfig = kubeconfig
      end

      def call(&block)
        StringBuilder.new.tap do |builder|
          builder.concat_handler = Kube::Ctl::Concat

          if block_given?
            builder.wrap(&block)
          else
            builder
          end
        end
      end

      def run(string)
        if @kubeconfig
          Kube::Helm.run "#{string} --kubeconfig=#{@kubeconfig}"
        else
          Kube::Helm.run(string.to_s)
        end
      end
    end
  end
end

test do
  require_relative "../../../setup"

  sb = ->(&block) {
    Kube.helm(&block)
  }

  # --- helm completion bash ---

  it "helm completion bash" do
    result = sb.call { completion.bash }
    result.to_s.should == "completion bash"
  end

  it "helm completion bash no descriptions" do
    result = sb.call { completion.bash.no_descriptions(true) }
    result.to_s.should == "completion bash --no-descriptions"
  end

  # --- helm completion zsh ---

  it "helm completion zsh" do
    result = sb.call { completion.zsh }
    result.to_s.should == "completion zsh"
  end

  it "helm completion zsh no descriptions" do
    result = sb.call { completion.zsh.no_descriptions(true) }
    result.to_s.should == "completion zsh --no-descriptions"
  end

  # --- helm completion fish ---

  it "helm completion fish" do
    result = sb.call { completion.fish }
    result.to_s.should == "completion fish"
  end

  it "helm completion fish no descriptions" do
    result = sb.call { completion.fish.no_descriptions(true) }
    result.to_s.should == "completion fish --no-descriptions"
  end

  # --- helm completion powershell ---

  it "helm completion powershell" do
    result = sb.call { completion.powershell }
    result.to_s.should == "completion powershell"
  end

  it "helm completion powershell no descriptions" do
    result = sb.call { completion.powershell.no_descriptions(true) }
    result.to_s.should == "completion powershell --no-descriptions"
  end

  # --- helm create ---

  it "helm create mychart" do
    result = sb.call { create.mychart }
    result.to_s.should == "create mychart"
  end

  it "helm create mychart starter" do
    result = sb.call { create.mychart.p('my-starter') }
    result.to_s.should == "create mychart -p my-starter"
  end

  it "helm create mychart starter long" do
    result = sb.call { create.mychart.starter('my-starter') }
    result.to_s.should == "create mychart --starter=my-starter"
  end

  # --- helm dependency build ---

  it "helm dependency build" do
    result = sb.call { dependency.build.("CHART") }
    result.to_s.should == "dependency build CHART"
  end

  # --- helm dependency list ---

  it "helm dependency list" do
    result = sb.call { dependency.list.("CHART") }
    result.to_s.should == "dependency list CHART"
  end

  # --- helm dependency update ---

  it "helm dependency update" do
    result = sb.call { dependency.update.("CHART") }
    result.to_s.should == "dependency update CHART"
  end

  # --- helm env ---

  it "helm env" do
    result = sb.call { env }
    result.to_s.should == "env"
  end

  # --- helm get all ---

  it "helm get all" do
    result = sb.call { get.all.("RELEASE_NAME") }
    result.to_s.should == "get all RELEASE_NAME"
  end

  # --- helm get hooks ---

  it "helm get hooks" do
    result = sb.call { get.hooks.("RELEASE_NAME") }
    result.to_s.should == "get hooks RELEASE_NAME"
  end

  # --- helm get manifest ---

  it "helm get manifest" do
    result = sb.call { get.manifest.("RELEASE_NAME") }
    result.to_s.should == "get manifest RELEASE_NAME"
  end

  # --- helm get metadata ---

  it "helm get metadata" do
    result = sb.call { get.metadata.("RELEASE_NAME") }
    result.to_s.should == "get metadata RELEASE_NAME"
  end

  # --- helm get notes ---

  it "helm get notes" do
    result = sb.call { get.notes.("RELEASE_NAME") }
    result.to_s.should == "get notes RELEASE_NAME"
  end

  # --- helm get values ---

  it "helm get values" do
    result = sb.call { get.values.("RELEASE_NAME") }
    result.to_s.should == "get values RELEASE_NAME"
  end

  # --- helm history ---

  it "helm history" do
    result = sb.call { history.("RELEASE_NAME") }
    result.to_s.should == "history RELEASE_NAME"
  end

  it "helm history angry bird" do
    result = sb.call { history.angry-bird }
    result.to_s.should == "history angry-bird"
  end

  # --- helm install ---

  it "helm install f myvalues yaml myredis redis" do
    result = sb.call { install.f('myvalues.yaml').myredis.("./redis") }
    result.to_s.should == "install -f myvalues.yaml myredis ./redis"
  end

  it "helm install set name prod myredis redis" do
    result = sb.call { install.set('name=prod').myredis.("./redis") }
    result.to_s.should == "install --set=name=prod myredis ./redis"
  end

  it "helm install set string long int myredis redis" do
    result = sb.call { install.set_string('long_int=1234567890').myredis.("./redis") }
    result.to_s.should == "install --set-string=long_int=1234567890 myredis ./redis"
  end

  it "helm install set file my script myredis redis" do
    result = sb.call { install.set_file('my_script=dothings.sh').myredis.("./redis") }
    result.to_s.should == "install --set-file=my_script=dothings.sh myredis ./redis"
  end

  it "helm install f myvalues yaml f override yaml myredis redis" do
    result = sb.call { install.f('myvalues.yaml').f('override.yaml').myredis.("./redis") }
    result.to_s.should == "install -f myvalues.yaml -f override.yaml myredis ./redis"
  end

  it "helm install set foo bar set foo newbar myredis redis" do
    result = sb.call { install.set('foo=bar').set('foo=newbar').myredis.("./redis") }
    result.to_s.should == "install --set=foo=bar --set=foo=newbar myredis ./redis"
  end

  it "helm install mymaria example mariadb" do
    result = sb.call { install.mymaria.("example/mariadb") }
    result.to_s.should == "install mymaria example/mariadb"
  end

  it "helm install mynginx tgz" do
    result = sb.call { install.mynginx.("./nginx-1.2.3.tgz") }
    result.to_s.should == "install mynginx ./nginx-1.2.3.tgz"
  end

  it "helm install mynginx local dir" do
    result = sb.call { install.mynginx.("./nginx") }
    result.to_s.should == "install mynginx ./nginx"
  end

  it "helm install mynginx url" do
    result = sb.call { install.mynginx.("https://example.com/charts/nginx-1.2.3.tgz") }
    result.to_s.should == "install mynginx https://example.com/charts/nginx-1.2.3.tgz"
  end

  it "helm install repo mynginx nginx" do
    result = sb.call { install.repo('https://example.com/charts/').mynginx.nginx }
    result.to_s.should == "install --repo=https://example.com/charts/ mynginx nginx"
  end

  it "helm install mynginx version oci" do
    result = sb.call { install.mynginx.version('1.2.3').("oci://example.com/charts/nginx") }
    result.to_s.should == "install mynginx --version=1.2.3 oci://example.com/charts/nginx"
  end

  # --- helm lint ---

  it "helm lint" do
    result = sb.call { lint.("PATH") }
    result.to_s.should == "lint PATH"
  end

  # --- helm list ---

  it "helm list" do
    result = sb.call { list }
    result.to_s.should == "list"
  end

  it "helm list filter" do
    result = sb.call { list.filter('ara[a-z]+') }
    result.to_s.should == "list --filter=ara[a-z]+"
  end

  # --- helm package ---

  it "helm package" do
    result = sb.call { package.("./mychart") }
    result.to_s.should == "package ./mychart"
  end

  it "helm package sign" do
    result = sb.call { package.sign(true).("./mychart").key('mykey').keyring('~/.gnupg/secring.gpg') }
    result.to_s.should == "package --sign ./mychart --key=mykey --keyring=~/.gnupg/secring.gpg"
  end

  # --- helm plugin install ---

  it "helm plugin install" do
    result = sb.call { plugin.install.("https://example.com/plugin") }
    result.to_s.should == "plugin install https://example.com/plugin"
  end

  # --- helm plugin list ---

  it "helm plugin list" do
    result = sb.call { plugin.list }
    result.to_s.should == "plugin list"
  end

  # --- helm plugin package ---

  it "helm plugin package" do
    result = sb.call { plugin.package.("PATH") }
    result.to_s.should == "plugin package PATH"
  end

  # --- helm plugin uninstall ---

  it "helm plugin uninstall" do
    result = sb.call { plugin.uninstall.("my-plugin") }
    result.to_s.should == "plugin uninstall my-plugin"
  end

  # --- helm plugin update ---

  it "helm plugin update" do
    result = sb.call { plugin.update.("my-plugin") }
    result.to_s.should == "plugin update my-plugin"
  end

  # --- helm plugin verify ---

  it "helm plugin verify" do
    result = sb.call { plugin.verify.("PATH") }
    result.to_s.should == "plugin verify PATH"
  end

  it "helm plugin verify example" do
    result = sb.call { plugin.verify.("~/.local/share/helm/plugins/example-cli") }
    result.to_s.should == "plugin verify ~/.local/share/helm/plugins/example-cli"
  end

  # --- helm pull ---

  it "helm pull" do
    result = sb.call { pull.("repo/chartname") }
    result.to_s.should == "pull repo/chartname"
  end

  # --- helm push ---

  it "helm push" do
    result = sb.call { push.("mychart-0.1.0.tgz").("oci://localhost:5000/helm-charts") }
    result.to_s.should == "push mychart-0.1.0.tgz oci://localhost:5000/helm-charts"
  end

  # --- helm registry login ---

  it "helm registry login" do
    result = sb.call { registry.login.("localhost:5000") }
    result.to_s.should == "registry login localhost:5000"
  end

  # --- helm registry logout ---

  it "helm registry logout" do
    result = sb.call { registry.logout.("localhost:5000") }
    result.to_s.should == "registry logout localhost:5000"
  end

  # --- helm repo add ---

  it "helm repo add" do
    result = sb.call { repo.add.("bitnami").("https://charts.bitnami.com/bitnami") }
    result.to_s.should == "repo add bitnami https://charts.bitnami.com/bitnami"
  end

  # --- helm repo index ---

  it "helm repo index" do
    result = sb.call { repo.index.("DIR") }
    result.to_s.should == "repo index DIR"
  end

  # --- helm repo list ---

  it "helm repo list" do
    result = sb.call { repo.list }
    result.to_s.should == "repo list"
  end

  # --- helm repo remove ---

  it "helm repo remove" do
    result = sb.call { repo.remove.("bitnami") }
    result.to_s.should == "repo remove bitnami"
  end

  # --- helm repo update ---

  it "helm repo update" do
    result = sb.call { repo.update }
    result.to_s.should == "repo update"
  end

  it "helm repo update with name" do
    result = sb.call { repo.update.("my-repo") }
    result.to_s.should == "repo update my-repo"
  end

  # --- helm rollback ---

  it "helm rollback" do
    result = sb.call { rollback.("my-release").("2") }
    result.to_s.should == "rollback my-release 2"
  end

  # --- helm search hub ---

  it "helm search hub" do
    result = sb.call { search.hub.("nginx") }
    result.to_s.should == "search hub nginx"
  end

  # --- helm search repo ---

  it "helm search repo" do
    result = sb.call { search.repo.("nginx") }
    result.to_s.should == "search repo nginx"
  end

  it "helm search repo devel" do
    result = sb.call { search.repo.("nginx").devel(true) }
    result.to_s.should == "search repo nginx --devel"
  end

  it "helm search repo version" do
    result = sb.call { search.repo.("nginx-ingress").version('^1.0.0') }
    result.to_s.should == "search repo nginx-ingress --version=^1.0.0"
  end

  # --- helm show all ---

  it "helm show all" do
    result = sb.call { show.all.("bitnami/nginx") }
    result.to_s.should == "show all bitnami/nginx"
  end

  # --- helm show chart ---

  it "helm show chart" do
    result = sb.call { show.chart.("bitnami/nginx") }
    result.to_s.should == "show chart bitnami/nginx"
  end

  # --- helm show crds ---

  it "helm show crds" do
    result = sb.call { show.crds.("bitnami/nginx") }
    result.to_s.should == "show crds bitnami/nginx"
  end

  # --- helm show readme ---

  it "helm show readme" do
    result = sb.call { show.readme.("bitnami/nginx") }
    result.to_s.should == "show readme bitnami/nginx"
  end

  # --- helm show values ---

  it "helm show values" do
    result = sb.call { show.values.("bitnami/nginx") }
    result.to_s.should == "show values bitnami/nginx"
  end

  # --- helm status ---

  it "helm status" do
    result = sb.call { status.("RELEASE_NAME") }
    result.to_s.should == "status RELEASE_NAME"
  end

  # --- helm template ---

  it "helm template" do
    result = sb.call { template.my_release.("bitnami/nginx") }
    result.to_s.should == "template my_release bitnami/nginx"
  end

  it "helm template api versions" do
    result = sb.call { template.api_versions('networking.k8s.io/v1').api_versions('cert-manager.io/v1').mychart.("./mychart") }
    result.to_s.should == "template --api-versions=networking.k8s.io/v1 --api-versions=cert-manager.io/v1 mychart ./mychart"
  end

  it "helm template api versions comma" do
    result = sb.call { template.api_versions('networking.k8s.io/v1', 'cert-manager.io/v1').mychart.("./mychart") }
    result.to_s.should == "template --api-versions=networking.k8s.io/v1,cert-manager.io/v1 mychart ./mychart"
  end

  # --- helm test ---

  it "helm test" do
    result = sb.call { test.("RELEASE") }
    result.to_s.should == "test RELEASE"
  end

  # --- helm uninstall ---

  it "helm uninstall" do
    result = sb.call { uninstall.("RELEASE_NAME") }
    result.to_s.should == "uninstall RELEASE_NAME"
  end

  # --- helm upgrade ---

  it "helm upgrade f myvalues yaml f override yaml redis" do
    result = sb.call { upgrade.f('myvalues.yaml').f('override.yaml').redis.("./redis") }
    result.to_s.should == "upgrade -f myvalues.yaml -f override.yaml redis ./redis"
  end

  it "helm upgrade set foo bar set foo newbar redis" do
    result = sb.call { upgrade.set('foo=bar').set('foo=newbar').redis.("./redis") }
    result.to_s.should == "upgrade --set=foo=bar --set=foo=newbar redis ./redis"
  end

  it "helm upgrade reuse values set foo bar set foo newbar redis" do
    result = sb.call { upgrade.reuse_values(true).set('foo=bar').set('foo=newbar').redis.("./redis") }
    result.to_s.should == "upgrade --reuse-values --set=foo=bar --set=foo=newbar redis ./redis"
  end

  # --- helm verify ---

  it "helm verify" do
    result = sb.call { verify.("PATH") }
    result.to_s.should == "verify PATH"
  end

  # --- helm version ---

  it "helm version" do
    result = sb.call { version }
    result.to_s.should == "version"
  end
end
