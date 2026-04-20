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

if __FILE__ == $0
  require "bundler/setup"
  require "minitest/autorun"
  require "kube/ctl"

  module Kube
    module Ctl
      def self.run(args) = args
    end

    module VCluster
      def self.run(args) = args
    end
  end

  class VClusterStringBuilderTest < Minitest::Test
    def sb(&block)
      Kube.vcluster(&block)
    end

    def assert_buffer(result, expected)
      assert_equal expected, result.to_a
    end

    def assert_string(result, expected)
      assert_equal expected, result.to_s
    end

    # ===================================================================
    # Core lifecycle
    # ===================================================================

    # vcluster create test --namespace test
    def test_create_with_namespace
      result = sb { create.test.namespace("test") }
      assert_string(result, "create test --namespace=test")
    end

    # vcluster connect test --namespace test
    def test_connect_with_namespace
      result = sb { connect.test.namespace("test") }
      assert_string(result, "connect test --namespace=test")
    end

    # vcluster connect test -n test -- bash
    def test_connect_with_exec_bash
      result = sb { connect.test.n("test").("-- bash") }
      assert_string(result, "connect test -n test -- bash")
    end

    # vcluster connect test -n test -- kubectl get ns
    def test_connect_with_exec_kubectl
      result = sb { connect.test.n("test").("-- kubectl get ns") }
      assert_string(result, "connect test -n test -- kubectl get ns")
    end

    # vcluster delete test --namespace test
    def test_delete_with_namespace
      result = sb { delete.test.namespace("test") }
      assert_string(result, "delete test --namespace=test")
    end

    # vcluster list
    def test_list
      result = sb { list }
      assert_buffer(result, [["list", []]])
      assert_string(result, "list")
    end

    # vcluster list --output json
    def test_list_output_json
      result = sb { list.output("json") }
      assert_string(result, "list --output=json")
    end

    # vcluster list --namespace test
    def test_list_namespace
      result = sb { list.namespace("test") }
      assert_string(result, "list --namespace=test")
    end

    # vcluster pause test --namespace test
    def test_pause_with_namespace
      result = sb { pause.test.namespace("test") }
      assert_string(result, "pause test --namespace=test")
    end

    # vcluster resume test --namespace test
    def test_resume_with_namespace
      result = sb { resume.test.namespace("test") }
      assert_string(result, "resume test --namespace=test")
    end

    # vcluster disconnect
    def test_disconnect
      result = sb { disconnect }
      assert_buffer(result, [["disconnect", []]])
      assert_string(result, "disconnect")
    end

    # vcluster describe test
    def test_describe
      result = sb { describe.test }
      assert_string(result, "describe test")
    end

    # vcluster describe -o json test
    def test_describe_output_json
      result = sb { describe.o("json").test }
      assert_string(result, "describe -o json test")
    end

    # vcluster ui
    def test_ui
      result = sb { ui }
      assert_buffer(result, [["ui", []]])
      assert_string(result, "ui")
    end

    # vcluster logout
    def test_logout
      result = sb { logout }
      assert_buffer(result, [["logout", []]])
      assert_string(result, "logout")
    end

    # ===================================================================
    # Debug
    # ===================================================================

    # vcluster debug shell my-vcluster --target=syncer
    def test_debug_shell_with_target
      result = sb { debug.shell.my-vcluster.target("syncer") }
      assert_string(result, "debug shell my-vcluster --target=syncer")
    end

    # vcluster debug shell my-vcluster --pod=my-vcluster-pod-0 --target=syncer
    def test_debug_shell_with_pod_and_target
      result = sb { debug.shell.my-vcluster.pod("my-vcluster-pod-0").target("syncer") }
      assert_string(result, "debug shell my-vcluster --pod=my-vcluster-pod-0 --target=syncer")
    end

    # ===================================================================
    # Snapshot
    # ===================================================================

    # vcluster snapshot my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
    def test_snapshot_oci
      result = sb { snapshot.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
      assert_string(result, "snapshot my-vcluster oci://ghcr.io/my-user/my-repo:my-tag")
    end

    # vcluster snapshot my-vcluster s3://my-bucket/my-bucket-key
    def test_snapshot_s3
      result = sb { snapshot.my-vcluster.("s3://my-bucket/my-bucket-key") }
      assert_string(result, "snapshot my-vcluster s3://my-bucket/my-bucket-key")
    end

    # vcluster snapshot my-vcluster container:///data/my-local-snapshot.tar.gz
    def test_snapshot_container
      result = sb { snapshot.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
      assert_string(result, "snapshot my-vcluster container:///data/my-local-snapshot.tar.gz")
    end

    # vcluster snapshot create my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
    def test_snapshot_create_oci
      result = sb { snapshot.create.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
      assert_string(result, "snapshot create my-vcluster oci://ghcr.io/my-user/my-repo:my-tag")
    end

    # vcluster snapshot create my-vcluster s3://my-bucket/my-bucket-key
    def test_snapshot_create_s3
      result = sb { snapshot.create.my-vcluster.("s3://my-bucket/my-bucket-key") }
      assert_string(result, "snapshot create my-vcluster s3://my-bucket/my-bucket-key")
    end

    # vcluster snapshot create my-vcluster container:///data/my-local-snapshot.tar.gz
    def test_snapshot_create_container
      result = sb { snapshot.create.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
      assert_string(result, "snapshot create my-vcluster container:///data/my-local-snapshot.tar.gz")
    end

    # vcluster snapshot get my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
    def test_snapshot_get_oci
      result = sb { snapshot.get.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
      assert_string(result, "snapshot get my-vcluster oci://ghcr.io/my-user/my-repo:my-tag")
    end

    # vcluster snapshot get my-vcluster s3://my-bucket/my-bucket-key
    def test_snapshot_get_s3
      result = sb { snapshot.get.my-vcluster.("s3://my-bucket/my-bucket-key") }
      assert_string(result, "snapshot get my-vcluster s3://my-bucket/my-bucket-key")
    end

    # vcluster snapshot get my-vcluster container:///data/my-local-snapshot.tar.gz
    def test_snapshot_get_container
      result = sb { snapshot.get.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
      assert_string(result, "snapshot get my-vcluster container:///data/my-local-snapshot.tar.gz")
    end

    # ===================================================================
    # Restore
    # ===================================================================

    # vcluster restore my-vcluster oci://ghcr.io/my-user/my-repo:my-tag
    def test_restore_oci
      result = sb { restore.my-vcluster.("oci://ghcr.io/my-user/my-repo:my-tag") }
      assert_string(result, "restore my-vcluster oci://ghcr.io/my-user/my-repo:my-tag")
    end

    # vcluster restore my-vcluster s3://my-bucket/my-bucket-key
    def test_restore_s3
      result = sb { restore.my-vcluster.("s3://my-bucket/my-bucket-key") }
      assert_string(result, "restore my-vcluster s3://my-bucket/my-bucket-key")
    end

    # vcluster restore my-vcluster container:///data/my-local-snapshot.tar.gz
    def test_restore_container
      result = sb { restore.my-vcluster.("container:///data/my-local-snapshot.tar.gz") }
      assert_string(result, "restore my-vcluster container:///data/my-local-snapshot.tar.gz")
    end

    # ===================================================================
    # Platform — login/logout/token
    # ===================================================================

    # vcluster platform login https://my-vcluster-platform.com
    def test_platform_login
      result = sb { platform.login.("https://my-vcluster-platform.com") }
      assert_string(result, "platform login https://my-vcluster-platform.com")
    end

    # vcluster platform login https://my-vcluster-platform.com --access-key myaccesskey
    def test_platform_login_with_access_key
      result = sb { platform.login.("https://my-vcluster-platform.com").access_key("myaccesskey") }
      assert_string(result, "platform login https://my-vcluster-platform.com --access-key=myaccesskey")
    end

    # vcluster platform logout
    def test_platform_logout
      result = sb { platform.logout }
      assert_string(result, "platform logout")
    end

    # vcluster platform token
    def test_platform_token
      result = sb { platform.token }
      assert_string(result, "platform token")
    end

    # ===================================================================
    # Platform — list
    # ===================================================================

    def test_platform_list_clusters
      result = sb { platform.list.clusters }
      assert_string(result, "platform list clusters")
    end

    def test_platform_list_namespaces
      result = sb { platform.list.namespaces }
      assert_string(result, "platform list namespaces")
    end

    def test_platform_list_projects
      result = sb { platform.list.projects }
      assert_string(result, "platform list projects")
    end

    def test_platform_list_secrets
      result = sb { platform.list.secrets }
      assert_string(result, "platform list secrets")
    end

    def test_platform_list_teams
      result = sb { platform.list.teams }
      assert_string(result, "platform list teams")
    end

    def test_platform_list_vclusters
      result = sb { platform.list.vclusters }
      assert_string(result, "platform list vclusters")
    end

    # ===================================================================
    # Platform — get
    # ===================================================================

    def test_platform_get_current_user
      result = sb { platform.get.current-user }
      assert_string(result, "platform get current-user")
    end

    def test_platform_get_secret
      result = sb { platform.get.secret.("test-secret.key") }
      assert_string(result, "platform get secret test-secret.key")
    end

    def test_platform_get_secret_with_project
      result = sb { platform.get.secret.("test-secret.key").project("myproject") }
      assert_string(result, "platform get secret test-secret.key --project=myproject")
    end

    # ===================================================================
    # Platform — create
    # ===================================================================

    def test_platform_create_vcluster
      result = sb { platform.create.vcluster.test.namespace("test") }
      assert_string(result, "platform create vcluster test --namespace=test")
    end

    def test_platform_create_namespace
      result = sb { platform.create.namespace.myspace }
      assert_string(result, "platform create namespace myspace")
    end

    def test_platform_create_namespace_with_project
      result = sb { platform.create.namespace.myspace.project("myproject") }
      assert_string(result, "platform create namespace myspace --project=myproject")
    end

    def test_platform_create_namespace_with_project_and_team
      result = sb { platform.create.namespace.myspace.project("myproject").team("myteam") }
      assert_string(result, "platform create namespace myspace --project=myproject --team=myteam")
    end

    def test_platform_create_accesskey
      result = sb { platform.create.accesskey.test }
      assert_string(result, "platform create accesskey test")
    end

    def test_platform_create_accesskey_vcluster_role
      result = sb { platform.create.accesskey.test.vcluster_role(true) }
      assert_string(result, "platform create accesskey test --vcluster-role")
    end

    def test_platform_create_accesskey_in_cluster
      result = sb { platform.create.accesskey.test.in_cluster(true).user("admin") }
      assert_string(result, "platform create accesskey test --in-cluster --user=admin")
    end

    # ===================================================================
    # Platform — delete
    # ===================================================================

    def test_platform_delete_vcluster
      result = sb { platform.delete.vcluster.namespace("test") }
      assert_string(result, "platform delete vcluster --namespace=test")
    end

    def test_platform_delete_namespace
      result = sb { platform.delete.namespace.myspace }
      assert_string(result, "platform delete namespace myspace")
    end

    def test_platform_delete_namespace_with_project
      result = sb { platform.delete.namespace.myspace.project("myproject") }
      assert_string(result, "platform delete namespace myspace --project=myproject")
    end

    # ===================================================================
    # Platform — connect
    # ===================================================================

    def test_platform_connect_cluster
      result = sb { platform.connect.cluster.mycluster }
      assert_string(result, "platform connect cluster mycluster")
    end

    def test_platform_connect_management
      result = sb { platform.connect.management }
      assert_string(result, "platform connect management")
    end

    def test_platform_connect_namespace
      result = sb { platform.connect.namespace.myspace }
      assert_string(result, "platform connect namespace myspace")
    end

    def test_platform_connect_namespace_with_project
      result = sb { platform.connect.namespace.myspace.project("myproject") }
      assert_string(result, "platform connect namespace myspace --project=myproject")
    end

    def test_platform_connect_vcluster
      result = sb { platform.connect.vcluster.test.namespace("test") }
      assert_string(result, "platform connect vcluster test --namespace=test")
    end

    def test_platform_connect_vcluster_exec_bash
      result = sb { platform.connect.vcluster.test.n("test").("-- bash") }
      assert_string(result, "platform connect vcluster test -n test -- bash")
    end

    def test_platform_connect_vcluster_exec_kubectl
      result = sb { platform.connect.vcluster.test.n("test").("-- kubectl get ns") }
      assert_string(result, "platform connect vcluster test -n test -- kubectl get ns")
    end

    # ===================================================================
    # Platform — share
    # ===================================================================

    def test_platform_share_namespace
      result = sb { platform.share.namespace.myspace }
      assert_string(result, "platform share namespace myspace")
    end

    def test_platform_share_namespace_with_project
      result = sb { platform.share.namespace.myspace.project("myproject") }
      assert_string(result, "platform share namespace myspace --project=myproject")
    end

    def test_platform_share_namespace_with_project_and_user
      result = sb { platform.share.namespace.myspace.project("myproject").user("admin") }
      assert_string(result, "platform share namespace myspace --project=myproject --user=admin")
    end

    def test_platform_share_vcluster
      result = sb { platform.share.vcluster.myvcluster }
      assert_string(result, "platform share vcluster myvcluster")
    end

    def test_platform_share_vcluster_with_project
      result = sb { platform.share.vcluster.myvcluster.project("myproject") }
      assert_string(result, "platform share vcluster myvcluster --project=myproject")
    end

    def test_platform_share_vcluster_with_project_and_user
      result = sb { platform.share.vcluster.myvcluster.project("myproject").user("admin") }
      assert_string(result, "platform share vcluster myvcluster --project=myproject --user=admin")
    end

    # ===================================================================
    # Platform — sleep/wakeup
    # ===================================================================

    def test_platform_sleep_namespace
      result = sb { platform.sleep.namespace.myspace }
      assert_string(result, "platform sleep namespace myspace")
    end

    def test_platform_sleep_namespace_with_project
      result = sb { platform.sleep.namespace.myspace.project("myproject") }
      assert_string(result, "platform sleep namespace myspace --project=myproject")
    end

    def test_platform_sleep_vcluster
      result = sb { platform.sleep.vcluster.test.namespace("test") }
      assert_string(result, "platform sleep vcluster test --namespace=test")
    end

    def test_platform_wakeup_namespace
      result = sb { platform.wakeup.namespace.myspace }
      assert_string(result, "platform wakeup namespace myspace")
    end

    def test_platform_wakeup_namespace_with_project
      result = sb { platform.wakeup.namespace.myspace.project("myproject") }
      assert_string(result, "platform wakeup namespace myspace --project=myproject")
    end

    def test_platform_wakeup_vcluster
      result = sb { platform.wakeup.vcluster.test.namespace("test") }
      assert_string(result, "platform wakeup vcluster test --namespace=test")
    end

    # ===================================================================
    # Platform — backup/reset/set/add
    # ===================================================================

    def test_platform_backup_management
      result = sb { platform.backup.management }
      assert_string(result, "platform backup management")
    end

    def test_platform_reset_password
      result = sb { platform.reset.password }
      assert_string(result, "platform reset password")
    end

    def test_platform_reset_password_with_user
      result = sb { platform.reset.password.user("admin") }
      assert_string(result, "platform reset password --user=admin")
    end

    def test_platform_set_secret
      result = sb { platform.set.secret.("test-secret.key").("value") }
      assert_string(result, "platform set secret test-secret.key value")
    end

    def test_platform_set_secret_with_project
      result = sb { platform.set.secret.("test-secret.key").("value").project("myproject") }
      assert_string(result, "platform set secret test-secret.key value --project=myproject")
    end

    def test_platform_add_cluster
      result = sb { platform.add.cluster.my-cluster }
      assert_string(result, "platform add cluster my-cluster")
    end

    def test_platform_add_vcluster_full
      result = sb { platform.add.vcluster.my-vcluster.namespace("vcluster-my-vcluster").project("my-project").import_name("my-vcluster") }
      assert_string(result, "platform add vcluster my-vcluster --namespace=vcluster-my-vcluster --project=my-project --import-name=my-vcluster")
    end

    def test_platform_add_vcluster_all
      result = sb { platform.add.vcluster.project("my-project").all(true) }
      assert_string(result, "platform add vcluster --project=my-project --all")
    end

    def test_platform_add_standalone
      result = sb { platform.add.standalone.my-cluster.project("my-project").access_key("my-access-key").host("https://my-vcluster-platform.com") }
      assert_string(result, "platform add standalone my-cluster --project=my-project --access-key=my-access-key --host=https://my-vcluster-platform.com")
    end
  end
end
