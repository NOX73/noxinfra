# NoxApp backend: Cloud Run service "noxapp" (Node.js 22, deployed from source with
# `gcloud run deploy --source` / the console), its domain, the scheduler that pokes it,
# and the two containers that source deploys create on their own.
#
# Split of ownership: Terraform owns the service shell (ingress, scaling, SA, limits);
# deploys own what changes per release (image, build, env). Env holds plaintext secrets
# (OAuth client secret / refresh token, push token), so it is never written here.

resource "google_cloud_run_v2_service" "noxapp" {
  project  = local.project_id
  location = local.region
  name     = "noxapp"

  ingress              = "INGRESS_TRAFFIC_ALL"
  invoker_iam_disabled = true # public, no IAM check on invoke
  default_uri_disabled = false
  launch_stage         = "GA"
  client               = "cloud-console"

  deletion_protection = true
  deletion_policy     = "DELETE"

  build_config {
    base_image               = "europe-west4-docker.pkg.dev/serverless-runtimes/google-22/runtimes/nodejs22"
    enable_automatic_updates = true
    function_target          = "push"
    image_uri                = "europe-west4-docker.pkg.dev/thermal-history-343013/cloud-run-source-deploy/noxapp:latest"
    source_location          = "gs://run-sources-thermal-history-343013-europe-west4/services/noxapp/1786375911.20000.zip#1786375911808043"
  }

  scaling {
    min_instance_count = 0
    max_instance_count = 1
  }

  template {
    service_account                  = "99257183987-compute@developer.gserviceaccount.com"
    max_instance_request_concurrency = 2
    timeout                          = "300s"

    containers {
      name           = "noxapp-1"
      base_image_uri = "europe-west4-docker.pkg.dev/serverless-runtimes/google-22/runtimes/nodejs22"
      image          = "europe-west4-docker.pkg.dev/thermal-history-343013/cloud-run-source-deploy/noxapp:latest@sha256:3608bcf839355afa8f46a53ff9412560ef03e6a94835cd5558db16007d0af18d"

      ports {
        container_port = 8080
        name           = "http1"
      }

      resources {
        cpu_idle          = true
        startup_cpu_boost = true
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      startup_probe {
        failure_threshold     = 1
        initial_delay_seconds = 0
        period_seconds        = 240
        timeout_seconds       = 240
        tcp_socket {
          port = 8080
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      build_config,
      template[0].revision,
      template[0].labels,
      template[0].annotations,
      template[0].containers[0].image,
      template[0].containers[0].base_image_uri,
      template[0].containers[0].env, # secrets, managed by deploys
    ]
  }
}

resource "google_cloud_run_domain_mapping" "noxapp" {
  project  = local.project_id
  location = local.region
  name     = "noxapp.nox73.com"

  metadata {
    namespace = local.project_id
  }

  spec {
    route_name       = google_cloud_run_v2_service.noxapp.name
    certificate_mode = "AUTOMATIC"
    force_override   = false
  }

  deletion_policy = "DELETE"
}

resource "google_cloud_scheduler_job" "noxapp_sync_images" {
  project   = local.project_id
  region    = local.region
  name      = "noxapp-sync-images"
  schedule  = "0 5,11,17,23 * * *"
  time_zone = "Europe/Podgorica"
  paused    = false

  attempt_deadline = "600s"

  http_target {
    http_method = "GET"
    # The real URI carries ?token=<secret>; it is kept out of the repo (see ignore_changes).
    uri = "https://noxapp-99257183987.europe-west4.run.app/sync-images"
  }

  retry_config {
    retry_count          = 0
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
    max_backoff_duration = "3600s"
    max_doublings        = 5
  }

  deletion_policy = "DELETE"

  lifecycle {
    ignore_changes = [http_target[0].uri]
  }
}

# Created automatically by the first `gcloud run deploy --source`: Docker images of builds.
resource "google_artifact_registry_repository" "cloud_run_source_deploy" {
  project       = local.project_id
  location      = local.region
  repository_id = "cloud-run-source-deploy"
  description   = "Cloud Run Source Deployments"
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"

  cleanup_policy_dry_run = false

  deletion_policy = "DELETE"
}

# Created automatically by source deploys: uploaded source archives.
resource "google_storage_bucket" "run_sources" {
  project       = local.project_id
  name          = "run-sources-thermal-history-343013-europe-west4"
  location      = "EUROPE-WEST4"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
  default_event_based_hold    = false
  enable_object_retention     = false
  requester_pays              = false
  force_destroy               = false

  cors {
    max_age_seconds = 0
    method          = ["GET"]
    origin          = ["https://*.cloud.google.com", "https://*.corp.google.com", "https://*.corp.google.com:*", "https://*.cloud.google", "https://*.byoid.goog"]
  }

  hierarchical_namespace {
    enabled = false
  }

  soft_delete_policy {
    retention_duration_seconds = 604800
  }

  deletion_policy = "DELETE"
}
