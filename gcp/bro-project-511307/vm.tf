# fortg: e2-micro Debian 13 VM running MTProxy and a SOCKS5 proxy (3proxy) for Telegram.
# Ephemeral external IP (no reserved address): it changes if the VM is recreated.
# Daily snapshots via default-schedule-1. Plus project-wide ssh-keys metadata.
# Imported as is.

resource "google_compute_instance" "fortg" {
  can_ip_forward             = false
  deletion_policy            = "DELETE"
  deletion_protection        = false
  enable_display             = false
  key_revocation_action_type = "NONE"
  machine_type               = "e2-micro"
  metadata = {
    enable-osconfig = "TRUE"
  }
  name    = "fortg"
  project = local.project_id
  tags    = ["mtproxy"]
  zone    = local.zone
  boot_disk {
    auto_delete       = true
    device_name       = "fortg"
    force_attach      = false
    guest_os_features = ["UEFI_COMPATIBLE", "VIRTIO_SCSI_MULTIQUEUE", "GVNIC", "SEV_CAPABLE", "SEV_SNP_CAPABLE", "SEV_LIVE_MIGRATABLE_V2", "IDPF", "SUSPEND_SAFE_FPR"]
    mode              = "READ_WRITE"
    source            = "https://www.googleapis.com/compute/v1/projects/bro-project-511307/zones/us-central1-a/disks/fortg"
    initialize_params {
      architecture                = "X86_64"
      enable_confidential_compute = false
      image                       = "https://www.googleapis.com/compute/v1/projects/debian-cloud/global/images/debian-13-trixie-v20261006"
      size                        = 10
      type                        = "pd-balanced"
    }
  }
  confidential_instance_config {
    enable_confidential_compute = false
  }
  network_interface {
    enable_vpc_scoped_dns = false
    network               = google_compute_network.default.self_link
    network_ip            = "10.128.0.2"
    stack_type            = "IPV4_ONLY"
    subnetwork            = "https://www.googleapis.com/compute/v1/projects/bro-project-511307/regions/us-central1/subnetworks/default"
    subnetwork_project    = local.project_id
    access_config {
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
    email  = "305470792638-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  lifecycle {
    # Instance-level ssh-keys are written by the console / gcloud on every "SSH" click
    # (short-lived keys with expireOn); managing them here would only produce drift.
    ignore_changes = [metadata["ssh-keys"]]
  }
}

resource "google_compute_resource_policy" "default_schedule_1" {
  deletion_policy = "DELETE"
  name            = "default-schedule-1"
  project         = local.project_id
  region          = local.region
  snapshot_schedule_policy {
    retention_policy {
      max_retention_days    = 14
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "23:00"
      }
    }
    snapshot_properties {
      guest_flush = false
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "fortg_default_schedule_1" {
  deletion_policy = "DELETE"
  disk            = "fortg"
  name            = google_compute_resource_policy.default_schedule_1.name
  project         = local.project_id
  zone            = local.zone
}

# Project-wide SSH keys (OS Login is off in this project).
resource "google_compute_project_metadata_item" "ssh_keys" {
  deletion_policy = "DELETE"
  key             = "ssh-keys"
  project         = local.project_id
  value           = "s-v-rozhnov:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDP0CWaCgBrN2iOqdyfE40vFi6tEX4vTIsTRNrR3R0JqCGGda1B2kG64znCdYhRDZmGgUm0A5GcPTPvgdaggjEw7h77W0tdvKAwfLeumU7wiExZYMRrYdHR2LjW+ak/BbM0pa01x0fFqbC7mGCuwigXvEWeLYAC5HarsXI3+gjvhxRycpmfgXJp4HcChAlVWR2ubqZWfFIufcN4RfAkK/M5jtZh1pv0tM573KznLDIuQ6I0RHt4ZQvgBwKZxuIMGT1WZcW062AY/qt6NDpDvmn6fuKJRKHOQgWYGBf/rt9A9z2RDchbCwJzNR+oxBloZq0vPWcOakaOY6CeY3SJokKYto7AQXJ8ecvk1m8P0OG0aqQ30KfdAtQMBIRIy1M2LFW7EjuWJyAn69ggThp7S3GtiOeEwPMV3d7/V2bV0U678H3U4fa/Y8a6ob04BIKH1oun4naaZHz1DeEnptGJBpU8vQ8O0cKwMLitS4J9yd4iwf6kQ3GAL4JljbBUEKdusHk= s-v-rozhnov@s-v-rozhnov-lin\ns-v-rozhnov:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtZWty20gMrBCfmll1zUeStsB7D7yNk40N8u8wwSv2m claude-temp-1h\ns-v-rozhnov:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNMuXXGlU/tWZMiTKFFUsujdq6PfBmm9aoLrN/uOry4 claude-temp-1h\ns-v-rozhnov:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3BwY+MEC2Gd/+SpdDzWCjgc6B4N4M9OOrZjKUYlBEm claude-temp-1h\n"
}
