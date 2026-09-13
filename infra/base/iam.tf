resource "google_service_account" "gke_sa" {
  account_id   = "thesis-gke-sa"
  display_name = "GKE Nodes Service Account"
}

locals {
  gke_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader"
  ]
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset(local.gke_roles)

  project = "analysis-infrastructure"
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}
