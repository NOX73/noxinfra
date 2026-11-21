# Cost data of the USD billing account (all its projects, including noxvpn-skv384, which
# is otherwise managed in the noxvpn repo).
#
# 1. BigQuery dataset for the Cloud Billing export (Standard + Detailed usage cost).
#    The export itself can only be switched on in the console: Billing -> Billing export
#    -> BigQuery export -> pick project thermal-history-343013, dataset billing_export.
#    Data flows from the moment it is enabled; there is no backfill to rely on.
#    Cost: the export is free; storage and queries stay inside the BigQuery free tier
#    (10 GB storage, 1 TB queries per month) at this scale.
# 2. Pub/Sub topic that every budget publishes to (see billing.tf): Google sends the
#    current month's actual spend per budget there several times a day. Read it with
#    gcloud pubsub subscriptions pull billing-budgets-pull --project thermal-history-343013

# The billing export runs as a BigQuery Data Transfer Service job.
resource "google_project_service" "bigquerydatatransfer" {
  project         = local.admin_project_id
  service         = "bigquerydatatransfer.googleapis.com"
  deletion_policy = "ABANDON"
}

resource "google_bigquery_dataset" "billing_export" {
  project     = local.admin_project_id
  dataset_id  = "billing_export"
  location    = "EU"
  description = "Cloud Billing export (Standard + Detailed) of the USD billing account 01C100-B62CB3-89CCC4"

  delete_contents_on_destroy = false
  deletion_policy            = "PREVENT"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.bigquerydatatransfer]
}

resource "google_pubsub_topic" "billing_budgets" {
  project = local.admin_project_id
  name    = "billing-budgets"
}

# Budgets publish as this Google-owned account.
resource "google_pubsub_topic_iam_member" "billing_budgets_publisher" {
  project = local.admin_project_id
  topic   = google_pubsub_topic.billing_budgets.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:billing-budget-alert@system.gserviceaccount.com"
}

# Pull subscription to read the latest spend by hand. Messages are kept for 7 days;
# the subscription never expires.
resource "google_pubsub_subscription" "billing_budgets_pull" {
  project                    = local.admin_project_id
  name                       = "billing-budgets-pull"
  topic                      = google_pubsub_topic.billing_budgets.id
  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"

  expiration_policy {
    ttl = ""
  }
}
