# instance-1 (e2-micro, Ubuntu 20.04, Outline VPN server behind nl.outline.nox73.com ->
# 35.214.243.249) was deleted on 2026-11-20 together with its static IP and DNS record.
# Only an ARCHIVE snapshot of its boot disk is kept (cheapest storage; billed for at
# least 90 days, small per-GB fee on restore). To bring it back, create a pd-balanced
# disk from the snapshot in europe-west4 and boot a VM from it.
# Plus project-wide metadata and an orphaned snapshot schedule. Imported as is.

resource "google_compute_resource_policy" "default_schedule_1" {
  deletion_policy = "DELETE"
  name            = "default-schedule-1"
  project         = local.project_id
  region          = "europe-west4"
  snapshot_schedule_policy {
    retention_policy {
      max_retention_days    = 20
      on_source_disk_delete = "APPLY_RETENTION_POLICY"
    }
    schedule {
      weekly_schedule {
        day_of_weeks {
          day        = "SUNDAY"
          start_time = "04:00"
        }
      }
    }
    snapshot_properties {
      guest_flush = false
    }
  }
}

resource "google_compute_project_metadata_item" "enable_oslogin" {
  deletion_policy = "DELETE"
  key             = "enable-oslogin"
  project         = local.project_id
  value           = "TRUE"
}

resource "google_compute_project_metadata_item" "ssh_keys" {
  deletion_policy = "DELETE"
  key             = "ssh-keys"
  project         = local.project_id
  value           = "root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNYCHyVQp5VQE4964vKlAhjiYA+0fwP0hl6sTvumCJTqFzytAx7NnBDdgN9tkyR7MLAyxjZSUsyjN86JN9hWt5ITU+jP1OXniUzxBoXHBRiql9WO8hdKrZtx00doi1xRl1a+GKHM0bHbh3ss2AVnK2HxA2WxOk5hgMWkvdKRiirjNT+LnvI3GEPlimjshdF/sNqbxd3vDAyMyjVKZzxckc1eMUSu+yMjtE3HpbafMklWm85y6xTt0tt32HTLceJKCFxzlm7xGUGHCdpogpcEb0UFEq1UvAPLr4fwk/MvIhLjnTcfajPhMLU/3fWOVvOj555Oaz6EAT1JXMhwU9uATJ root@0fb141054fd5"
}

resource "google_compute_snapshot" "instance_1_final" {
  name              = "instance-1-final-20261120"
  project           = local.project_id
  description       = "Final backup of instance-1 (Outline VPN, Ubuntu 20.04) before deleting the VM"
  source_disk       = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/zones/europe-west4-a/disks/instance-1"
  zone              = "europe-west4-a"
  snapshot_type     = "ARCHIVE"
  storage_locations = ["europe-west4"]

  lifecycle {
    # The source disk no longer exists; never try to recreate the snapshot.
    prevent_destroy = true
    ignore_changes  = [source_disk, zone]
  }
}
