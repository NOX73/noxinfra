# noxapp-39eee: Firebase project of the NoxApp Android app.
#
# Out of Terraform on purpose:
#   - Firestore security rules and indexes: deployed with Firebase CLI from the app repo.
#   - Firebase-managed service agents and the firebase-adminsdk SA with its roles.
#   - Default Hosting site (created by Firebase, cannot be deleted, nothing deployed).
#   - The project itself, its billing and claude-agent roles: see gcp/_bootstrap.

locals {
  project_id = "noxapp-39eee"
}
