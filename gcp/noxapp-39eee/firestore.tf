import {
  to = google_firestore_database.default
  id = "projects/${local.project_id}/databases/(default)"
}

resource "google_firestore_database" "default" {
  project     = local.project_id
  name        = "(default)"
  location_id = "eur3"
  type        = "FIRESTORE_NATIVE"

  database_edition                  = "STANDARD"
  concurrency_mode                  = "PESSIMISTIC"
  app_engine_integration_mode       = "DISABLED"
  realtime_updates_mode             = "REALTIME_UPDATES_MODE_ENABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_DISABLED"
  delete_protection_state           = "DELETE_PROTECTION_DISABLED"

  deletion_policy = "ABANDON"
}
