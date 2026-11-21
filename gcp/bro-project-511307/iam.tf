# Project-level roles of non-Google principals. Not managed here on purpose:
#   - roles/owner of the two human accounts (gNOX73@gmail.com, bazilio073@gmail.com):
#     managed by hand, never by Terraform;
#   - Google service agents (compute-system, gcp-sa-osconfig, cloudservices) - granted and
#     owned by Google;
#   - claude-agent roles - see gcp/_bootstrap.

import {
  to = google_project_iam_member.compute_editor
  id = "${local.project_id} roles/editor serviceAccount:305470792638-compute@developer.gserviceaccount.com"
}

# Default compute SA (used by fortg).
resource "google_project_iam_member" "compute_editor" {
  project = local.project_id
  role    = "roles/editor"
  member  = "serviceAccount:305470792638-compute@developer.gserviceaccount.com"
}
