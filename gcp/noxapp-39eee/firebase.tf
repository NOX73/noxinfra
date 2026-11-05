import {
  provider = google-beta
  to       = google_firebase_project.this
  id       = "projects/${local.project_id}"
}

resource "google_firebase_project" "this" {
  provider = google-beta
  project  = local.project_id
}

import {
  provider = google-beta
  to       = google_firebase_android_app.noxapp
  id       = "projects/${local.project_id}/androidApps/1:965139170943:android:0602d8c558cb981501e14a"
}

resource "google_firebase_android_app" "noxapp" {
  provider     = google-beta
  project      = google_firebase_project.this.project
  display_name = "NoxApp"
  package_name = "com.nox73.noxapp"
  api_key_id   = "e47f8606-e2cb-4629-96c5-67acc2806a28"

  deletion_policy = "DELETE"
}
