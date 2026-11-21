# APIs this project relies on. Others that are on (BigQuery, Dataplex, ...) are left alone.
# ABANDON: dropping a line here never disables an API.
locals {
  services = toset([
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
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
