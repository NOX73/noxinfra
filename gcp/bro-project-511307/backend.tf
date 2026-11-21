terraform {
  backend "gcs" {
    bucket = "noxinfra-tfstate"
    prefix = "gcp/bro-project-511307"
  }
}
