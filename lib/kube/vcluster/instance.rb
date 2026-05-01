# frozen_string_literal: true


module Kube
  module VCluster
    class Instance
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
        Kube::VCluster.run(string.to_s)
      end
    end
  end
end

test do
  require_relative "../../../setup"

  sb = ->(&block) {
    Kube.vcluster(&block)
  }

  # ===================================================================
  # Core lifecycle
  # ===================================================================

  # vcluster create test --namespace test
  it "create with namespace" do
    result = sb.call { create.test.namespace("test") }
    result.to_s.should == "create test --namespace=test"
  end

  # vcluster connect test --namespace test
  it "connect with namespace" do
    result = sb.call { connect.test.namespace("test") }
    result.to_s.should == "connect test --namespace=test"
  end

  # vcluster connect test -n test -- bash
  it "connect with exec bash" do
    result = sb.call { connect.test.n("test").("-- bash") }
    result.to_s.should == "connect test -n test -- bash"
  end

  # vcluster connect test -n test -- kubectl get ns
  it "connect with exec kubectl" do
    result = sb.call { connect.test.n("test").("-- kubectl get ns") }
    result.to_s.should == "connect test -n test -- kubectl get ns"
  end

  # vcluster delete test --namespace test
  it "delete with namespace" do
    result = sb.call { delete.test.namespace("test") }
    result.to_s.should == "delete test --namespace=test"
  end

  # vcluster list
  it "list" do
    result = sb.call { list }
    result.to_s.should == "list"
  end

  # vcluster list --output json
  it "list output json" do
    result = sb.call { list.output("json") }
    result.to_s.should == "list --output=json"
  end

  # vcluster list --namespace test
  it "list namespace" do
    result = sb.call { list.namespace("test") }
    result.to_s.should == "list --namespace=test"
  end

  # vcluster pause test --namespace test
  it "pause with namespace" do
    result = sb.call { pause.test.namespace("test") }
    result.to_s.should == "pause test --namespace=test"
  end

  # vcluster resume test --namespace test
  it "resume with namespace" do
    result = sb.call { resume.test.namespace("test") }
    result.to_s.should == "resume test --namespace=test"
  end

  # vcluster disconnect
  it "disconnect" do
    result = sb.call { disconnect }
    result.to_s.should == "disconnect"
  end

  # vcluster describe test
  it "describe" do
    result = sb.call { describe.test }
    result.to_s.should == "describe test"
  end

  # vcluster describe -o json test
  it "describe output json" do
    result = sb.call { describe.o("json").test }
    result.to_s.should == "describe -o json test"
  end

  # vcluster ui
  it "ui" do
    result = sb.call { ui }
    result.to_s.should == "ui"
  end

  # vcluster logout
  it "logout" do
    result = sb.call { logout }
    result.to_s.should == "logout"
  end

  # ===================================================================
  # Debug
  # ===================================================================

  # vcluster debug shell my-vcluster --target=syncer
  it "debug shell with target" do
    result = sb.call { debug.shell.my-vcluster.target("syncer") }
    result.to_s.should == "debug shell my-vcluster --target=syncer"
  end

  # vcluster debug shell my-vcluster --pod=my-vcluster-pod-0 --target=syncer
  it "debug shell with pod and target" do
    result = sb.call { debug.shell.my-vcluster.pod("my-vcluster-pod-0").target("syncer") }
    result.to_s.should == "debug shell my-vcluster --pod=my-vcluster-pod-0 --target=syncer"
  end

  # ===================================================================
  # Snapshot
  # ===================================================================

  # vcluster snapshot my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
  it "snapshot oci" do
    result = sb.call { snapshot.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
    result.to_s.should == "snapshot my-vcluster oci://ghcr.io/my-user/my-repo:my-tag"
  end

  # vcluster snapshot my-vcluster s3://my-bucket/my-bucket-key
  it "snapshot s3" do
    result = sb.call { snapshot.my-vcluster.("s3://my-bucket/my-bucket-key") }
    result.to_s.should == "snapshot my-vcluster s3://my-bucket/my-bucket-key"
  end

  # vcluster snapshot my-vcluster container:///data/my-local-snapshot.tar.gz
  it "snapshot container" do
    result = sb.call { snapshot.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
    result.to_s.should == "snapshot my-vcluster container:///data/my-local-snapshot.tar.gz"
  end

  # vcluster snapshot create my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
  it "snapshot create oci" do
    result = sb.call { snapshot.create.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
    result.to_s.should == "snapshot create my-vcluster oci://ghcr.io/my-user/my-repo:my-tag"
  end

  # vcluster snapshot create my-vcluster s3://my-bucket/my-bucket-key
  it "snapshot create s3" do
    result = sb.call { snapshot.create.my-vcluster.("s3://my-bucket/my-bucket-key") }
    result.to_s.should == "snapshot create my-vcluster s3://my-bucket/my-bucket-key"
  end

  # vcluster snapshot create my-vcluster container:///data/my-local-snapshot.tar.gz
  it "snapshot create container" do
    result = sb.call { snapshot.create.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
    result.to_s.should == "snapshot create my-vcluster container:///data/my-local-snapshot.tar.gz"
  end

  # vcluster snapshot get my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
  it "snapshot get oci" do
    result = sb.call { snapshot.get.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
    result.to_s.should == "snapshot get my-vcluster oci://ghcr.io/my-user/my-repo:my-tag"
  end

  # vcluster snapshot get my-vcluster s3://my-bucket/my-bucket-key
  it "snapshot get s3" do
    result = sb.call { snapshot.get.my-vcluster.("s3://my-bucket/my-bucket-key") }
    result.to_s.should == "snapshot get my-vcluster s3://my-bucket/my-bucket-key"
  end

  # vcluster snapshot get my-vcluster container:///data/my-local-snapshot.tar.gz
  it "snapshot get container" do
    result = sb.call { snapshot.get.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
    result.to_s.should == "snapshot get my-vcluster container:///data/my-local-snapshot.tar.gz"
  end

  # ===================================================================
  # Restore
  # ===================================================================

  # vcluster restore my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
  it "restore oci" do
    result = sb.call { restore.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
    result.to_s.should == "restore my-vcluster oci://ghcr.io/my-user/my-repo:my-tag"
  end

  # vcluster restore my-vcluster s3://my-bucket/my-bucket-key
  it "restore s3" do
    result = sb.call { restore.my-vcluster.("s3://my-bucket/my-bucket-key") }
    result.to_s.should == "restore my-vcluster s3://my-bucket/my-bucket-key"
  end

  # vcluster restore my-vcluster container:///data/my-local-snapshot.tar.gz
  it "restore container" do
    result = sb.call { restore.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
    result.to_s.should == "restore my-vcluster container:///data/my-local-snapshot.tar.gz"
  end

  # ===================================================================
  # Platform — login/logout/token
  # ===================================================================

  # vcluster platform login https://my-vcluster-platform.com
  it "platform login" do
    result = sb.call { platform.login.("https://my-vcluster-platform.com") }
    result.to_s.should == "platform login https://my-vcluster-platform.com"
  end

  # vcluster platform login https://my-vcluster-platform.com --access-key myaccesskey
  it "platform login with access key" do
    result = sb.call { platform.login.("https://my-vcluster-platform.com").access_key("myaccesskey") }
    result.to_s.should == "platform login https://my-vcluster-platform.com --access-key=myaccesskey"
  end

  # vcluster platform logout
  it "platform logout" do
    result = sb.call { platform.logout }
    result.to_s.should == "platform logout"
  end

  # vcluster platform token
  it "platform token" do
    result = sb.call { platform.token }
    result.to_s.should == "platform token"
  end

  # ===================================================================
  # Platform — list
  # ===================================================================

  it "platform list clusters" do
    result = sb.call { platform.list.clusters }
    result.to_s.should == "platform list clusters"
  end

  it "platform list namespaces" do
    result = sb.call { platform.list.namespaces }
    result.to_s.should == "platform list namespaces"
  end

  it "platform list projects" do
    result = sb.call { platform.list.projects }
    result.to_s.should == "platform list projects"
  end

  it "platform list secrets" do
    result = sb.call { platform.list.secrets }
    result.to_s.should == "platform list secrets"
  end

  it "platform list teams" do
    result = sb.call { platform.list.teams }
    result.to_s.should == "platform list teams"
  end

  it "platform list vclusters" do
    result = sb.call { platform.list.vclusters }
    result.to_s.should == "platform list vclusters"
  end

  # ===================================================================
  # Platform — get
  # ===================================================================

  it "platform get current user" do
    result = sb.call { platform.get.current-user }
    result.to_s.should == "platform get current-user"
  end

  it "platform get secret" do
    result = sb.call { platform.get.secret.("test-secret.key") }
    result.to_s.should == "platform get secret test-secret.key"
  end

  it "platform get secret with project" do
    result = sb.call { platform.get.secret.("test-secret.key").project("myproject") }
    result.to_s.should == "platform get secret test-secret.key --project=myproject"
  end

  # ===================================================================
  # Platform — create
  # ===================================================================

  it "platform create vcluster" do
    result = sb.call { platform.create.vcluster.test.namespace("test") }
    result.to_s.should == "platform create vcluster test --namespace=test"
  end

  it "platform create namespace" do
    result = sb.call { platform.create.namespace.myspace }
    result.to_s.should == "platform create namespace myspace"
  end

  it "platform create namespace with project" do
    result = sb.call { platform.create.namespace.myspace.project("myproject") }
    result.to_s.should == "platform create namespace myspace --project=myproject"
  end

  it "platform create namespace with project and team" do
    result = sb.call { platform.create.namespace.myspace.project("myproject").team("myteam") }
    result.to_s.should == "platform create namespace myspace --project=myproject --team=myteam"
  end

  it "platform create accesskey" do
    result = sb.call { platform.create.accesskey.test }
    result.to_s.should == "platform create accesskey test"
  end

  it "platform create accesskey vcluster role" do
    result = sb.call { platform.create.accesskey.test.vcluster_role(true) }
    result.to_s.should == "platform create accesskey test --vcluster-role"
  end

  it "platform create accesskey in cluster" do
    result = sb.call { platform.create.accesskey.test.in_cluster(true).user("admin") }
    result.to_s.should == "platform create accesskey test --in-cluster --user=admin"
  end

  # ===================================================================
  # Platform — delete
  # ===================================================================

  it "platform delete vcluster" do
    result = sb.call { platform.delete.vcluster.namespace("test") }
    result.to_s.should == "platform delete vcluster --namespace=test"
  end

  it "platform delete namespace" do
    result = sb.call { platform.delete.namespace.myspace }
    result.to_s.should == "platform delete namespace myspace"
  end

  it "platform delete namespace with project" do
    result = sb.call { platform.delete.namespace.myspace.project("myproject") }
    result.to_s.should == "platform delete namespace myspace --project=myproject"
  end

  # ===================================================================
  # Platform — connect
  # ===================================================================

  it "platform connect cluster" do
    result = sb.call { platform.connect.cluster.mycluster }
    result.to_s.should == "platform connect cluster mycluster"
  end

  it "platform connect management" do
    result = sb.call { platform.connect.management }
    result.to_s.should == "platform connect management"
  end

  it "platform connect namespace" do
    result = sb.call { platform.connect.namespace.myspace }
    result.to_s.should == "platform connect namespace myspace"
  end

  it "platform connect namespace with project" do
    result = sb.call { platform.connect.namespace.myspace.project("myproject") }
    result.to_s.should == "platform connect namespace myspace --project=myproject"
  end

  it "platform connect vcluster" do
    result = sb.call { platform.connect.vcluster.test.namespace("test") }
    result.to_s.should == "platform connect vcluster test --namespace=test"
  end

  it "platform connect vcluster exec bash" do
    result = sb.call { platform.connect.vcluster.test.n("test").("-- bash") }
    result.to_s.should == "platform connect vcluster test -n test -- bash"
  end

  it "platform connect vcluster exec kubectl" do
    result = sb.call { platform.connect.vcluster.test.n("test").("-- kubectl get ns") }
    result.to_s.should == "platform connect vcluster test -n test -- kubectl get ns"
  end

  # ===================================================================
  # Platform — share
  # ===================================================================

  it "platform share namespace" do
    result = sb.call { platform.share.namespace.myspace }
    result.to_s.should == "platform share namespace myspace"
  end

  it "platform share namespace with project" do
    result = sb.call { platform.share.namespace.myspace.project("myproject") }
    result.to_s.should == "platform share namespace myspace --project=myproject"
  end

  it "platform share namespace with project and user" do
    result = sb.call { platform.share.namespace.myspace.project("myproject").user("admin") }
    result.to_s.should == "platform share namespace myspace --project=myproject --user=admin"
  end

  it "platform share vcluster" do
    result = sb.call { platform.share.vcluster.myvcluster }
    result.to_s.should == "platform share vcluster myvcluster"
  end

  it "platform share vcluster with project" do
    result = sb.call { platform.share.vcluster.myvcluster.project("myproject") }
    result.to_s.should == "platform share vcluster myvcluster --project=myproject"
  end

  it "platform share vcluster with project and user" do
    result = sb.call { platform.share.vcluster.myvcluster.project("myproject").user("admin") }
    result.to_s.should == "platform share vcluster myvcluster --project=myproject --user=admin"
  end

  # ===================================================================
  # Platform — sleep/wakeup
  # ===================================================================

  it "platform sleep namespace" do
    result = sb.call { platform.sleep.namespace.myspace }
    result.to_s.should == "platform sleep namespace myspace"
  end

  it "platform sleep namespace with project" do
    result = sb.call { platform.sleep.namespace.myspace.project("myproject") }
    result.to_s.should == "platform sleep namespace myspace --project=myproject"
  end

  it "platform sleep vcluster" do
    result = sb.call { platform.sleep.vcluster.test.namespace("test") }
    result.to_s.should == "platform sleep vcluster test --namespace=test"
  end

  it "platform wakeup namespace" do
    result = sb.call { platform.wakeup.namespace.myspace }
    result.to_s.should == "platform wakeup namespace myspace"
  end

  it "platform wakeup namespace with project" do
    result = sb.call { platform.wakeup.namespace.myspace.project("myproject") }
    result.to_s.should == "platform wakeup namespace myspace --project=myproject"
  end

  it "platform wakeup vcluster" do
    result = sb.call { platform.wakeup.vcluster.test.namespace("test") }
    result.to_s.should == "platform wakeup vcluster test --namespace=test"
  end

  # ===================================================================
  # Platform — backup/reset/set/add
  # ===================================================================

  it "platform backup management" do
    result = sb.call { platform.backup.management }
    result.to_s.should == "platform backup management"
  end

  it "platform reset password" do
    result = sb.call { platform.reset.password }
    result.to_s.should == "platform reset password"
  end

  it "platform reset password with user" do
    result = sb.call { platform.reset.password.user("admin") }
    result.to_s.should == "platform reset password --user=admin"
  end

  it "platform set secret" do
    result = sb.call { platform.set.secret.("test-secret.key").("value") }
    result.to_s.should == "platform set secret test-secret.key value"
  end

  it "platform set secret with project" do
    result = sb.call { platform.set.secret.("test-secret.key").("value").project("myproject") }
    result.to_s.should == "platform set secret test-secret.key value --project=myproject"
  end

  it "platform add cluster" do
    result = sb.call { platform.add.cluster.my-cluster }
    result.to_s.should == "platform add cluster my-cluster"
  end

  it "platform add vcluster full" do
    result = sb.call { platform.add.vcluster.my-vcluster.namespace("vcluster-my-vcluster").project("my-project").import_name("my-vcluster") }
    result.to_s.should == "platform add vcluster my-vcluster --namespace=vcluster-my-vcluster --project=my-project --import-name=my-vcluster"
  end

  it "platform add vcluster all" do
    result = sb.call { platform.add.vcluster.project("my-project").all(true) }
    result.to_s.should == "platform add vcluster --project=my-project --all"
  end

  it "platform add standalone" do
    result = sb.call { platform.add.standalone.my-cluster.project("my-project").access_key("my-access-key").host("https://my-vcluster-platform.com") }
    result.to_s.should == "platform add standalone my-cluster --project=my-project --access-key=my-access-key --host=https://my-vcluster-platform.com"
  end
end
