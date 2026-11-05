# Public zone nox73.com. Apex NS/SOA are Google-managed and not tracked.

resource "google_dns_record_set" "v_ns" {
  deletion_policy = "DELETE"
  managed_zone    = "nox73"
  name            = "v.nox73.com."
  project         = local.project_id
  rrdatas         = ["ns-cloud-b1.googledomains.com.", "ns-cloud-b2.googledomains.com.", "ns-cloud-b3.googledomains.com.", "ns-cloud-b4.googledomains.com."]
  ttl             = 3600
  type            = "NS"
}

resource "google_dns_record_set" "apex_txt" {
  deletion_policy = "DELETE"
  managed_zone    = "nox73"
  name            = "nox73.com."
  project         = local.project_id
  rrdatas         = ["\"google-site-verification=FARhMSimIKVwcsHVS_GbanIYQJCIFmTGq0qg4NbPHVg\""]
  ttl             = 300
  type            = "TXT"
}

resource "google_dns_record_set" "nl_outline_a" {
  deletion_policy = "DELETE"
  managed_zone    = "nox73"
  name            = "nl.outline.nox73.com."
  project         = local.project_id
  rrdatas         = ["35.214.243.249"]
  ttl             = 300
  type            = "A"
}

resource "google_dns_record_set" "noxapp_cname" {
  deletion_policy = "DELETE"
  managed_zone    = "nox73"
  name            = "noxapp.nox73.com."
  project         = local.project_id
  rrdatas         = ["ghs.googlehosted.com."]
  ttl             = 300
  type            = "CNAME"
}

resource "google_dns_managed_zone" "nox73" {
  deletion_policy = "DELETE"
  description     = "Public zone for nox73.com"
  dns_name        = "nox73.com."
  force_destroy   = false
  name            = "nox73"
  project         = local.project_id
  visibility      = "public"
  cloud_logging_config {
    enable_logging = false
  }
  dnssec_config {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "off"
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
  }
}
