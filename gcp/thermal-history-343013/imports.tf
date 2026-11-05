import {
  to = google_compute_network.default
  id = "projects/thermal-history-343013/global/networks/default"
}
import {
  to = google_compute_firewall.default_allow_icmp
  id = "projects/thermal-history-343013/global/firewalls/default-allow-icmp"
}
import {
  to = google_compute_firewall.default_allow_internal
  id = "projects/thermal-history-343013/global/firewalls/default-allow-internal"
}
import {
  to = google_compute_firewall.default_allow_ssh
  id = "projects/thermal-history-343013/global/firewalls/default-allow-ssh"
}
import {
  to = google_compute_firewall.outline
  id = "projects/thermal-history-343013/global/firewalls/outline"
}
import {
  to = google_compute_firewall.ssh23
  id = "projects/thermal-history-343013/global/firewalls/ssh23"
}
import {
  to = google_compute_address.outline
  id = "projects/thermal-history-343013/regions/europe-west4/addresses/outline-v2-static-standard-tier"
}
import {
  to = google_compute_instance.instance_1
  id = "projects/thermal-history-343013/zones/europe-west4-a/instances/instance-1"
}
import {
  to = google_compute_resource_policy.default_schedule_1
  id = "projects/thermal-history-343013/regions/europe-west4/resourcePolicies/default-schedule-1"
}
import {
  to = google_compute_project_metadata_item.enable_oslogin
  id = "enable-oslogin"
}
import {
  to = google_compute_project_metadata_item.ssh_keys
  id = "ssh-keys"
}
import {
  to = google_os_config_os_policy_assignment.ops_agent
  id = "projects/thermal-history-343013/locations/europe-west4-a/osPolicyAssignments/goog-ops-agent-v2-template-1-5-0-europe-west4-a"
}
import {
  to = google_dns_managed_zone.nox73
  id = "projects/thermal-history-343013/managedZones/nox73"
}
import {
  to = google_dns_record_set.apex_txt
  id = "projects/thermal-history-343013/managedZones/nox73/rrsets/nox73.com./TXT"
}
import {
  to = google_dns_record_set.noxapp_cname
  id = "projects/thermal-history-343013/managedZones/nox73/rrsets/noxapp.nox73.com./CNAME"
}
import {
  to = google_dns_record_set.nl_outline_a
  id = "projects/thermal-history-343013/managedZones/nox73/rrsets/nl.outline.nox73.com./A"
}
import {
  to = google_dns_record_set.v_ns
  id = "projects/thermal-history-343013/managedZones/nox73/rrsets/v.nox73.com./NS"
}
import {
  to = google_cloud_run_v2_service.noxapp
  id = "projects/thermal-history-343013/locations/europe-west4/services/noxapp"
}
import {
  to = google_cloud_run_domain_mapping.noxapp
  id = "locations/europe-west4/namespaces/thermal-history-343013/domainmappings/noxapp.nox73.com"
}
import {
  to = google_cloud_scheduler_job.noxapp_sync_images
  id = "projects/thermal-history-343013/locations/europe-west4/jobs/noxapp-sync-images"
}
import {
  to = google_artifact_registry_repository.cloud_run_source_deploy
  id = "projects/thermal-history-343013/locations/europe-west4/repositories/cloud-run-source-deploy"
}
import {
  to = google_storage_bucket.run_sources
  id = "run-sources-thermal-history-343013-europe-west4"
}
import {
  to = google_service_account.terraform_alex
  id = "projects/thermal-history-343013/serviceAccounts/terraform-alex@thermal-history-343013.iam.gserviceaccount.com"
}
import {
  to = google_service_account.cert_manager_dns01
  id = "projects/thermal-history-343013/serviceAccounts/cert-manager-dns01@thermal-history-343013.iam.gserviceaccount.com"
}
import {
  to = google_service_account.noxapp_play_publisher
  id = "projects/thermal-history-343013/serviceAccounts/noxapp-play-publisher@thermal-history-343013.iam.gserviceaccount.com"
}
