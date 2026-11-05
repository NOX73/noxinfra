# State of this module lives in the bucket it creates (migrated from local state after
# the first apply). Other root modules use the same bucket with their own prefix.
terraform {
  backend "gcs" {
    bucket = "noxinfra-tfstate"
    prefix = "gcp/_bootstrap"
  }
}
