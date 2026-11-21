# bro-project-511307 ("Bro Project"): VM fortg with MTProxy + SOCKS5 for Telegram.
# Billing: USD account. Shared project: a second owner (bazilio073@gmail.com) can change
# things in the console, so drift here may come from them.
#
# Out of Terraform on purpose:
#   - Snapshots of the fortg disk (created daily by default-schedule-1, kept 14 days).
#   - Auto-mode subnets and routes of the default VPC, per-zone InstanceSettings.
#   - Default compute SA and Google service agents, roles/owner of the humans.
#   - _Default / _Required log buckets and sinks.
#   - APIs that are on but unused (BigQuery, Dataplex, ...).
#   - The project itself, its billing and claude-agent roles: see gcp/_bootstrap.

locals {
  project_id = "bro-project-511307"
  region     = "us-central1"
  zone       = "us-central1-a"
}
