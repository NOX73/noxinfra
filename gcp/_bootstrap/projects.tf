# Projects that are tracked as objects only: no resources inside them are managed here.
#
# Out of Terraform on purpose:
#   - talktruly: empty project (default APIs only, no billing), left as is by decision.

# Created by Google AI Studio. Holds the Gemini API keys ("Gemini API Key",
# "Aixle staging"); the keys and their service accounts are managed in AI Studio,
# because importing a key would put the key string into state.
import {
  to = google_project.gemini
  id = "gen-lang-client-0948610743"
}

resource "google_project" "gemini" {
  project_id = "gen-lang-client-0948610743"
  name       = "Default Gemini Project"

  auto_create_network = true

  deletion_policy = "PREVENT"
}

import {
  to = google_project_service.gemini_generativelanguage
  id = "gen-lang-client-0948610743/generativelanguage.googleapis.com"
}

resource "google_project_service" "gemini_generativelanguage" {
  project = google_project.gemini.project_id
  service = "generativelanguage.googleapis.com"

  # Removing this resource from code must not switch the API off under live keys:
  # ABANDON only drops it from state.
  deletion_policy = "ABANDON"
}
