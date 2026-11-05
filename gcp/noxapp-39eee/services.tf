# Only the APIs this project actually relies on. Firebase and BigQuery switched on ~30 more
# by default; those are left alone. ABANDON: dropping a line here never disables an API.
locals {
  services = toset([
    "apikeys.googleapis.com",
    "fcm.googleapis.com",
    "firebase.googleapis.com",
    "firebaseinstallations.googleapis.com",
    "firebaserules.googleapis.com",
    "firestore.googleapis.com",
  ])

  # Already enabled when this module was written (apikeys was added by it).
  imported_services = setsubtract(local.services, ["apikeys.googleapis.com"])
}

import {
  for_each = local.imported_services
  to       = google_project_service.this[each.key]
  id       = "${local.project_id}/${each.key}"
}

resource "google_project_service" "this" {
  for_each = local.services

  project         = local.project_id
  service         = each.key
  deletion_policy = "ABANDON"
}
