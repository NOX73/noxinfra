provider "google" {
  project = local.project_id
  region  = "europe-west1"

  # API quota and billing for calls go to this project, not to the SA's home project
  # (thermal-history-343013): Firebase APIs are enabled here, not there.
  user_project_override = true
  billing_project       = local.project_id
}

provider "google-beta" {
  project               = local.project_id
  region                = "europe-west1"
  user_project_override = true
  billing_project       = local.project_id
}
