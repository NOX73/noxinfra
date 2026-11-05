# API keys auto-created by Firebase. Key strings end up in state; acceptable here: the
# Android key ships inside the APK anyway, and the state bucket is private.

locals {
  # Firebase's default API allow-list for its auto-created keys (order as returned by the API).
  firebase_key_api_targets = [
    "firebasedatabase.googleapis.com",
    "firebasehosting.googleapis.com",
    "firebaserules.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudconfig.googleapis.com",
    "datastore.googleapis.com",
    "fcmregistrations.googleapis.com",
    "firebase.googleapis.com",
    "firebaseappcheck.googleapis.com",
    "firebaseappdistribution.googleapis.com",
    "firebaseapphosting.googleapis.com",
    "firebaseapptesters.googleapis.com",
    "firebasedataconnect.googleapis.com",
    "firebaseinappmessaging.googleapis.com",
    "firebaseinstallations.googleapis.com",
    "firebaseml.googleapis.com",
    "firebaseremoteconfig.googleapis.com",
    "firebaseremoteconfigrealtime.googleapis.com",
    "firebasestorage.googleapis.com",
    "firebasevertexai.googleapis.com",
    "firestore.googleapis.com",
    "identitytoolkit.googleapis.com",
    "logging.googleapis.com",
    "mlkit.googleapis.com",
    "play.googleapis.com",
    "securetoken.googleapis.com",
    "fpnv.googleapis.com",
  ]
}

import {
  to = google_apikeys_key.android
  id = "projects/${local.project_id}/locations/global/keys/e47f8606-e2cb-4629-96c5-67acc2806a28"
}

# Used by the NoxApp Android app (google_firebase_android_app.noxapp.api_key_id).
resource "google_apikeys_key" "android" {
  project      = local.project_id
  name         = "e47f8606-e2cb-4629-96c5-67acc2806a28"
  display_name = "Android key (auto created by Firebase)"

  restrictions {
    dynamic "api_targets" {
      for_each = local.firebase_key_api_targets
      content {
        service = api_targets.value
      }
    }
  }
}

import {
  to = google_apikeys_key.browser
  id = "projects/${local.project_id}/locations/global/keys/1b599b25-16df-493a-bbb2-888f28642f4f"
}

# Created by Firebase with the project; the project has no web apps.
resource "google_apikeys_key" "browser" {
  project      = local.project_id
  name         = "1b599b25-16df-493a-bbb2-888f28642f4f"
  display_name = "Browser key (auto created by Firebase)"

  restrictions {
    dynamic "api_targets" {
      for_each = local.firebase_key_api_targets
      content {
        service = api_targets.value
      }
    }
  }
}
