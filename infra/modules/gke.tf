resource "google_container_cluster" "primary" {
  name     = "thesis-test-cluster"
  location = "europe-central2-a"

  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    disk_size_gb = 30
    disk_type    = "pd-standard"
  }

  network    = data.terraform_remote_state.base.outputs.network_id
  subnetwork = data.terraform_remote_state.base.outputs.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods-range"
    services_secondary_range_name = "gke-services-range"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  deletion_protection = false
}
