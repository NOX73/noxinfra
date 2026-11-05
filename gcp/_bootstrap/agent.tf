# claude-agent: the only identity used inside the devcontainer (key on the volume, never in
# the repo; see docs/README.md). Careful: Terraform runs as this SA, so removing a role
# here can lock it out - change these with a human-run apply in mind.

resource "google_service_account" "claude_agent" {
  project      = local.admin_project_id
  account_id   = "claude-agent"
  display_name = "Claude Code (noxinfra, read-only)"
}

import {
  to = google_service_account.claude_agent
  id = "projects/${local.admin_project_id}/serviceAccounts/claude-agent@${local.admin_project_id}.iam.gserviceaccount.com"
}

locals {
  claude_agent_member = "serviceAccount:${google_service_account.claude_agent.email}"

  read_roles  = ["roles/viewer", "roles/iam.securityReviewer", "roles/cloudasset.viewer"]
  write_roles = ["roles/editor", "roles/iam.securityAdmin"]

  # project => roles. In-scope projects get write access, the rest read-only.
  claude_agent_project_roles = {
    "thermal-history-343013"     = concat(local.read_roles, local.write_roles, ["roles/serviceusage.serviceUsageConsumer"])
    "noxapp-39eee"               = concat(local.read_roles, local.write_roles)
    "gen-lang-client-0948610743" = local.read_roles
    "talktruly"                  = local.read_roles
  }

  claude_agent_project_bindings = {
    for pair in flatten([
      for project, roles in local.claude_agent_project_roles : [
        for role in roles : { project = project, role = role }
      ]
    ]) : "${pair.project}/${pair.role}" => pair
  }

  billing_accounts = {
    usd = "01C100-B62CB3-89CCC4"
    rub = "01F31D-A21EE0-6CD6CC"
  }
}

import {
  for_each = local.claude_agent_project_bindings
  to       = google_project_iam_member.claude_agent[each.key]
  id       = "${each.value.project} ${each.value.role} serviceAccount:claude-agent@${local.admin_project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "claude_agent" {
  for_each = local.claude_agent_project_bindings

  project = each.value.project
  role    = each.value.role
  member  = local.claude_agent_member
}

import {
  for_each = local.billing_accounts
  to       = google_billing_account_iam_member.claude_agent_viewer[each.key]
  id       = "${each.value} roles/billing.viewer serviceAccount:claude-agent@${local.admin_project_id}.iam.gserviceaccount.com"
}

resource "google_billing_account_iam_member" "claude_agent_viewer" {
  for_each = local.billing_accounts

  billing_account_id = each.value
  role               = "roles/billing.viewer"
  member             = local.claude_agent_member
}

# APIs of the admin project that the agent and Terraform itself depend on
# (quota for its calls lands here). Other APIs of this project: gcp/thermal-history-343013.
locals {
  admin_services = toset([
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
  ])
}

import {
  for_each = local.admin_services
  to       = google_project_service.admin[each.key]
  id       = "${local.admin_project_id}/${each.key}"
}

resource "google_project_service" "admin" {
  for_each = local.admin_services

  project         = local.admin_project_id
  service         = each.key
  deletion_policy = "ABANDON"
}
