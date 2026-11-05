# Default VPC (auto mode: 40+ regional subnets and default routes are created by GCP and
# not managed one by one) and its firewall rules. Imported as is.

resource "google_compute_firewall" "default_allow_internal" {
  deletion_policy = "DELETE"
  description     = "Allow internal traffic on the default network"
  direction       = "INGRESS"
  disabled        = false
  name            = "default-allow-internal"
  network         = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/global/networks/default"
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

resource "google_compute_firewall" "default_allow_ssh" {
  deletion_policy = "DELETE"
  description     = "Allow SSH from anywhere"
  direction       = "INGRESS"
  disabled        = false
  name            = "default-allow-ssh"
  network         = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/global/networks/default"
  priority        = 65534
  project         = local.project_id
  source_ranges   = ["34.1.250.211", "35.214.243.249", "35.235.240.0/20"]
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  allow {
    ports    = ["22"]
    protocol = "udp"
  }
}

resource "google_compute_firewall" "ssh23" {
  deletion_policy         = "DELETE"
  direction               = "INGRESS"
  disabled                = false
  name                    = "ssh23"
  network                 = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/global/networks/default"
  priority                = 1000
  project                 = local.project_id
  source_ranges           = ["34.1.250.211", "35.214.143.149/32", "35.214.243.249", "35.235.240.0/20"]
  target_service_accounts = ["99257183987-compute@developer.gserviceaccount.com"]
  allow {
    ports    = ["23"]
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "outline" {
  deletion_policy         = "DELETE"
  direction               = "INGRESS"
  disabled                = false
  name                    = "outline"
  network                 = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/global/networks/default"
  priority                = 1000
  project                 = local.project_id
  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = ["99257183987-compute@developer.gserviceaccount.com"]
  allow {
    ports    = ["38014", "443", "1640"]
    protocol = "tcp"
  }
  allow {
    ports    = ["38014", "443", "1640"]
    protocol = "udp"
  }
}

resource "google_compute_firewall" "default_allow_icmp" {
  deletion_policy = "DELETE"
  description     = "Allow ICMP from anywhere"
  direction       = "INGRESS"
  disabled        = false
  name            = "default-allow-icmp"
  network         = "https://www.googleapis.com/compute/v1/projects/thermal-history-343013/global/networks/default"
  priority        = 65534
  project         = local.project_id
  source_ranges   = ["0.0.0.0/0"]
  allow {
    protocol = "icmp"
  }
}

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
