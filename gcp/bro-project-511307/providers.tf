provider "google" {
  project = local.project_id
  region  = local.region

  # No user_project_override: Cloud Resource Manager API is off in this project, so quota
  # for project-level calls (IAM, services) goes to the SA's home project instead.
}
