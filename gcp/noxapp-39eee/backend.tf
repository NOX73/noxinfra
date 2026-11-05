terraform {
  backend "gcs" {
    bucket = "noxinfra-tfstate"
    prefix = "gcp/noxapp-39eee"
  }
}
