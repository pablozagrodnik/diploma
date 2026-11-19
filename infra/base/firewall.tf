resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "allow-ssh-iap"
  network = google_compute_network.main_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "allow_prometheus_scraping" {
  name    = "allow-prometheus-scraping"
  network = google_compute_network.main_vpc.id

  allow {
    protocol = "tcp"
    ports    = [8080, 80]
  }

  source_ranges = ["10.0.0.0/24"]
}
