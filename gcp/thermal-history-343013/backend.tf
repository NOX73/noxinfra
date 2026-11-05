terraform {
  backend "gcs" {
    bucket = "noxinfra-tfstate"
    prefix = "gcp/thermal-history-343013"
  }
}
