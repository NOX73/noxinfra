# Default VPC (auto mode: 40+ regional subnets and default routes are created by GCP and
# not managed one by one) and its firewall rules. Imported as is.

resource "google_compute_network" "default" {
  auto_create_subnetworks                   = true
  bgp_always_compare_med                    = false
  bgp_best_path_selection_mode              = "LEGACY"
  delete_bgp_always_compare_med             = false
  delete_default_routes_on_create           = false
  deletion_policy                           = "DELETE"
  description                               = "Default network for the project"
  enable_ula_internal_ipv6                  = false
  mtu                                       = 0
  name                                      = "default"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = local.project_id
  routing_mode                              = "REGIONAL"
}

# MTProxy (Telegram) on fortg.
resource "google_compute_firewall" "allow_mtproxy" {
  deletion_policy = "DELETE"
  direction       = "INGRESS"
  disabled        = false
  name            = "allow-mtproxy"
  network         = google_compute_network.default.self_link
  priority        = 1000
  project         = local.project_id
  source_ranges   = ["0.0.0.0/0"]
  target_tags     = ["mtproxy"]
  allow {
    ports    = ["443"]
    protocol = "tcp"
  }
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "allow_socks5" {
  deletion_policy = "DELETE"
  description     = "SOCKS5 (3proxy) for Telegram on fortg"
  direction       = "INGRESS"
  disabled        = false
  name            = "allow-socks5"
  network         = google_compute_network.default.self_link
  priority        = 1000
  project         = local.project_id
  source_ranges   = ["0.0.0.0/0"]
  target_tags     = ["mtproxy"]
  allow {
    ports    = ["1080"]
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "default_allow_internal" {
  deletion_policy = "DELETE"
  description     = "Allow internal traffic on the default network"
  direction       = "INGRESS"
  disabled        = false
  name            = "default-allow-internal"
  network         = google_compute_network.default.self_link
  priority        = 65534
  project         = local.project_id
  source_ranges   = ["10.128.0.0/9"]
  allow {
    ports    = ["0-65535"]
    protocol = "tcp"
  }
  allow {
    ports    = ["0-65535"]
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "default_allow_icmp" {
  deletion_policy = "DELETE"
  description     = "Allow ICMP from anywhere"
  direction       = "INGRESS"
  disabled        = false
  name            = "default-allow-icmp"
  network         = google_compute_network.default.self_link
  priority        = 65534
  project         = local.project_id
  source_ranges   = ["0.0.0.0/0"]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "default_allow_ssh" {
  deletion_policy = "DELETE"
  description     = "Allow SSH from anywhere"
  direction       = "INGRESS"
  disabled        = false
  name            = "default-allow-ssh"
  network         = google_compute_network.default.self_link
  priority        = 65534
  project         = local.project_id
  source_ranges   = ["0.0.0.0/0"]
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "default_allow_rdp" {
  deletion_policy = "DELETE"
  description     = "Allow RDP from anywhere"
  direction       = "INGRESS"
  disabled        = false
  name            = "default-allow-rdp"
  network         = google_compute_network.default.self_link
  priority        = 65534
  project         = local.project_id
  source_ranges   = ["0.0.0.0/0"]
  allow {
    ports    = ["3389"]
    protocol = "tcp"
  }
}
