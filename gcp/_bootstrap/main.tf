# Bootstrap layer: the admin project and the GCS bucket that holds Terraform state
# for every other root module in this repo.
#
# Chicken and egg: this module is first applied with local state, then its own state is
# migrated into the bucket it created (see docs/README.md, "Remote state").

locals {
  admin_project_id = "thermal-history-343013"
  region           = "europe-west4"
  billing_account  = "01C100-B62CB3-89CCC4" # USD Billing Account
}

# Admin project: existing, created by hand. Hosts the state bucket and the claude-agent SA.
import {
  to = google_project.admin
  id = local.admin_project_id
}

resource "google_project" "admin" {
  project_id      = local.admin_project_id
  name            = "My Project"
  billing_account = local.billing_account

  # The project was created with the default network; it is managed elsewhere.
  auto_create_network = true

  deletion_policy = "PREVENT"
}

resource "google_storage_bucket" "tfstate" {
  name     = "noxinfra-tfstate"
  project  = google_project.admin.project_id
  location = upper(local.region)

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  deletion_policy             = "PREVENT" # stored in state: holds even if this code is removed

  # Every state write is kept as a version, so a broken state can be rolled back.
  versioning {
    enabled = true
  }

  # Old state versions are noise after a while.
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 90
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
