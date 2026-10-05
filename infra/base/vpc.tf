resource "google_compute_network" "main_vpc" {
  name                    = "thesis-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main_subnet" {
  name                     = "thesis-subnet"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = "europe-central2"
  network                  = google_compute_network.main_vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods-range"
    ip_cidr_range = "10.10.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services-range"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_compute_router" "router" {
  name    = "thesis-router"
  network = google_compute_network.main_vpc.id
  region  = "europe-central2"
}

resource "google_compute_router_nat" "nat" {
  name                               = "thesis-nat"
  router                             = google_compute_router.router.name
  region                             = "europe-central2"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
