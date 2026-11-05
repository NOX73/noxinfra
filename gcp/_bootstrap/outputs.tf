output "state_bucket" {
  description = "GCS bucket for Terraform state of all root modules (backend \"gcs\")."
  value       = google_storage_bucket.tfstate.name
}
