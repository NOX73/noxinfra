# instance-1: e2-micro Ubuntu 20.04 VM running the Outline VPN server
# (nl.outline.nox73.com -> static IP below). Plus project-wide metadata and an
# orphaned snapshot schedule. Imported as is.

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

resource "google_compute_instance" "instance_1" {
  can_ip_forward      = false
  deletion_policy     = "DELETE"
  deletion_protection = false
  enable_display      = false
  machine_type        = "e2-micro"
  metadata = {
    enable-osconfig = "TRUE"
    enable-oslogin  = "true"
  }
  name    = "instance-1"
  project = local.project_id
  zone    = "europe-west4-a"
  boot_disk {
    auto_delete       = true
    device_name       = "instance-1"
    force_attach      = false
    guest_os_features = ["VIRTIO_SCSI_MULTIQUEUE", "SEV_CAPABLE", "UEFI_COMPATIBLE", "GVNIC"]
    mode              = "READ_WRITE"
    source            = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/zones/europe-west4-a/disks/instance-1"
    initialize_params {
      enable_confidential_compute = false
      image                       = "https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2004-focal-v20220331"
      size                        = 10
      type                        = "pd-balanced"
    }
  }
  confidential_instance_config {
    enable_confidential_compute = false
  }
  network_interface {
    enable_vpc_scoped_dns = false
    network               = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/global/networks/default"
    network_ip            = "10.164.0.4"
    stack_type            = "IPV4_ONLY"
    subnetwork            = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/regions/europe-west4/subnetworks/default"
    subnetwork_project    = "thermal-history-343013"
    access_config {
      nat_ip       = "35.214.243.249"
      network_tier = "STANDARD"
    }
  }
  reservation_affinity {
    type = "ANY_RESERVATION"
  }
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }
  service_account {
    email  = "99257183987-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }
}

resource "google_compute_address" "outline" {
  address         = "35.214.243.249"
  address_type    = "EXTERNAL"
  deletion_policy = "DELETE"
  name            = "outline-v2-static-standard-tier"
  network_tier    = "STANDARD"
  prefix_length   = 0
  project         = local.project_id
  region          = "europe-west4"
}

resource "google_compute_project_metadata_item" "ssh_keys" {
  deletion_policy = "DELETE"
  key             = "ssh-keys"
  project         = local.project_id
  value           = "root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNYCHyVQp5VQE4964vKlAhjiYA+0fwP0hl6sTvumCJTqFzytAx7NnBDdgN9tkyR7MLAyxjZSUsyjN86JN9hWt5ITU+jP1OXniUzxBoXHBRiql9WO8hdKrZtx00doi1xRl1a+GKHM0bHbh3ss2AVnK2HxA2WxOk5hgMWkvdKRiirjNT+LnvI3GEPlimjshdF/sNqbxd3vDAyMyjVKZzxckc1eMUSu+yMjtE3HpbafMklWm85y6xTt0tt32HTLceJKCFxzlm7xGUGHCdpogpcEb0UFEq1UvAPLr4fwk/MvIhLjnTcfajPhMLU/3fWOVvOj555Oaz6EAT1JXMhwU9uATJ root@0fb141054fd5"
}
