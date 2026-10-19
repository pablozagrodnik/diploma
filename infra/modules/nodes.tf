resource "google_container_node_pool" "primary_nodes" {
  name       = "thesis-node-pool"
  cluster    = google_container_cluster.primary.id
  location   = "europe-central2-a"
  node_count = 1

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 30
    disk_type    = "pd-standard"

    service_account = data.terraform_remote_state.base.outputs.gke_service_account_email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
