# Default compute SA of thermal-history-343013 writes /public/daily_info
# (the server-side function mentioned in the Firestore rules).
import {
  to = google_project_iam_member.thermal_compute_datastore
  id = "${local.project_id} roles/datastore.owner serviceAccount:99257183987-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "thermal_compute_datastore" {
  project = local.project_id
  role    = "roles/datastore.owner"
  member  = "serviceAccount:99257183987-compute@developer.gserviceaccount.com"
}
