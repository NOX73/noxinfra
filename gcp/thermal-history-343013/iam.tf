# Service accounts of this project (their keys are created by hand and are not
# importable into Terraform) and project-level roles.

resource "google_service_account" "noxapp_play_publisher" {
  account_id      = "noxapp-play-publisher"
  deletion_policy = "DELETE"
  description     = "Uploads NoxApp builds to Google Play closed testing"
  disabled        = false
  display_name    = "noxapp-play-publisher"
  project         = local.project_id
}

resource "google_service_account" "terraform_alex" {
  account_id      = "terraform-alex"
  deletion_policy = "DELETE"
  description     = "For using to apply terraform for alex"
  disabled        = false
  display_name    = "Terraform Alex"
  project         = local.project_id
}

resource "google_service_account" "cert_manager_dns01" {
  account_id      = "cert-manager-dns01"
  deletion_policy = "DELETE"
  disabled        = false
  display_name    = "cert-manager-dns01"
  project         = local.project_id
}

# Project-level roles of non-Google principals. Not managed here on purpose:
#   - roles/owner of the human account (managed by hand, never by Terraform);
#   - Google service agents (*.gserviceaccount.com under gcp-sa-*, cloudservices,
#     cloudbuild) - granted and owned by Google;
#   - claude-agent roles - see gcp/_bootstrap.
locals {
  iam_members = {
    compute_editor = {
      role   = "roles/editor"
      member = "serviceAccount:99257183987-compute@developer.gserviceaccount.com"
    }
    terraform_alex_editor = {
      role   = "roles/editor"
      member = "serviceAccount:terraform-alex@thermal-history-343013.iam.gserviceaccount.com"
    }
    cert_manager_dns_admin = {
      role   = "roles/dns.admin"
      member = "serviceAccount:cert-manager-dns01@thermal-history-343013.iam.gserviceaccount.com"
    }
  }
}

import {
  for_each = local.iam_members
  to       = google_project_iam_member.this[each.key]
  id       = "${local.project_id} ${each.value.role} ${each.value.member}"
}

resource "google_project_iam_member" "this" {
  for_each = local.iam_members

  project = local.project_id
  role    = each.value.role
  member  = each.value.member
}
