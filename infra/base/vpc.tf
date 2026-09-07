resource "google_compute_network" "main_vpc" {
  name                    = "thesis-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main_subnet" {
  name          = "thesis-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "europe-central2"
  network        = google_compute_network.main_vpc.id
}
