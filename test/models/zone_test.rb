require 'test_helper'

class ZoneTest < ActiveSupport::TestCase

  @@zone_id = 1

  test "no permissions" do
    u,p,z,politics = zone_permission_test_vars

    policy_test({
      role: 'User with no permissions',
      policy: politics,
      permit: []
    })
  end

  test "zone manager permissions" do
    u,p,z,politics = zone_permission_test_vars

    u.add_role :zone_manager, p

    policy_test({
      role: 'Zone manager without permissions',
      policy: politics,
      permit: []
    })

    u.zone_permissions.create!(project: p, zone_id: z.id, name: :read)
    policy_test({
      role: 'Zone manager with read permissions',
      policy: politics,
      permit: :show
    })

    u.zone_permissions.destroy_all
    u.zone_permissions.create!(project: p, zone_id: z.id, name: :edit)
    policy_test({
      role: 'Zone manager with edit permissions',
      policy: politics,
      permit: :update
    })

    u.zone_permissions.destroy_all
    u.zone_permissions.create!(project: p, zone_id: z.id, name: :destroy)
    policy_test({
      role: 'Zone manager with destroy permissions',
      policy: politics,
      permit: :destroy
    })
  end

  test "zone creator permissions" do
    u,p,z,politics = zone_permission_test_vars

    u.add_role :zone_manager, p
    u.add_role :zone_creator, p

    policy_test({
      role: 'Zone creator',
      policy: politics,
      permit: :create
    })
  end

  test "admin permissions" do
    u,p,z,politics = zone_permission_test_vars

    u.add_role :admin, p

    policy_test({
      role: 'Project admin',
      policy: politics,
      permit: [:create, :show, :update, :destroy]
    })
  end

  test "import" do
    zone_string = read_fixture('import')
    import = GRemote::Zone.import(zone_string, "zone.com.", "zone.com.")
    zone = import[:zone]
    dns_zone = import[:dns_zone]

    assert_empty import[:errors], "Import had errors"
    assert_equal dns_zone.ttl, "1", "Default TTL was not what was expected"

    soa = dns_zone.records.detect { |r| r.type == "SOA" }
    assert !soa.nil?, "SOA record was not found"
    assert_equal soa.dump, "@ IN SOA ns-cloud-c1.googledomains.com. dns-admin.google.com. ( 1 21600 3600 1209600 300 )", "SOA record was not imported as expected"

    4.times do |n|
      ns = dns_zone.records.detect { |r| r.type == "NS" && r.dump == "@ IN NS ns-cloud-c#{n+1}.googledomains.com." }
      assert !ns.nil?, "#{(n+1).ordinalize} NS record was not found"
    end

    checklist = {
      "NS" => "ns.ns.",
      "A" => "1.1.1.1",
      "AAAA" => "2002:101:101::",
      "CNAME" => "cname.cname.",
      "MX" => "1 mx.mx.",
      "PTR" => "ptr.ptr.",
      "SPF" => "v=spf1-all",
      "SRV" => "1 1 1 srv.srv.",
      "TXT" => "txt",
    }

    import[:additions].each do |record|
      type = record.type
      assert !checklist[type].nil?, "Additions included an unexpected #{type}-record"

      assert_equal record.name, "#{record.type.downcase}.zone.zone.", "Name was imported incorrectly for #{type}-record"
      assert_equal record.ttl, "1", "TTL was imported incorrectly for #{type}-record"

      assert_equal checklist[type], record.rrdatas.join(" "), "RRData was imported incorrectly for #{type}-record"
      checklist.delete(type)
    end

    assert_empty checklist, "Not all records were imported"
  end

  test "export" do
    zone = GRemote::Zone.new
    zone.name = "zone.zone."
    zone.dns_name = "zone.zone."

    rsets = []
    ns_rrdatas = [
      "ns-cloud-c1.googledomains.com.",
      "ns-cloud-c2.googledomains.com.",
      "ns-cloud-c3.googledomains.com.",
      "ns-cloud-c4.googledomains.com."
    ]

    add_record_set(rsets, "NS", ns_rrdatas, "21600", "@")
    add_record_set(rsets, "SOA", ["ns-cloud-c1.googledomains.com. dns-admin.google.com. 1 21600 3600 1209600 300"], "21600", "@")
    add_record_set(rsets, "A", ["1.1.1.1"], "1")
    add_record_set(rsets, "AAAA", ["2002:101:101::"], "1")
    add_record_set(rsets, "CNAME", ["cname.cname."], "1")
    add_record_set(rsets, "MX", ["1 mx.mx."], "1")
    add_record_set(rsets, "NS", ["ns.ns."], "1")
    add_record_set(rsets, "PTR", ["ptr.ptr."], "1")
    add_record_set(rsets, "SPF", ["\"v=spf1\" \"-all\""], "1")
    add_record_set(rsets, "SRV", ["1 1 1 srv.srv."], "1")
    add_record_set(rsets, "TXT", ["\"txt\""], "1")

    export = zone.export("21600", rsets)
    compare = read_fixture('export')

    assert_equal export, compare, "Export data did not match with the template"
  end

  private

    def add_record_set(arr, type, rrdatas, ttl, name=nil)
      name ||= type.downcase
      rec = GRemote::RecordSet.new
      rec.type = type
      rec.rrdatas = rrdatas
      rec.name = name
      rec.ttl = ttl
      arr.push(rec)
    end

    def zone_permission_test_vars
      u = User.first
      p = Project.first
      z = GRemote::Zone.new
      z.id = @@zone_id += 1
      z.project = p
      [u, p, z, ZonePolicy.new(u,z)]
    end
end
