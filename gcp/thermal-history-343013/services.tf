# APIs this project relies on. Others that are on (BigQuery, backupdr, ...) are left alone.
# APIs needed by the admin SA itself (cloudasset, cloudbilling, ...) live in gcp/_bootstrap.
# ABANDON: dropping a line here never disables an API.
locals {
  services = toset([
    "androidpublisher.googleapis.com", # noxapp-play-publisher uploads to Google Play
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "drive.googleapis.com", # noxapp backend
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
    "run.googleapis.com",
    "sheets.googleapis.com", # noxapp backend
    "storage.googleapis.com",
  ])
}

import {
  for_each = local.services
  to       = google_project_service.this[each.key]
  id       = "${local.project_id}/${each.key}"
}

resource "google_project_service" "this" {
  for_each = local.services

  project         = local.project_id
  service         = each.key
  deletion_policy = "ABANDON"
}
