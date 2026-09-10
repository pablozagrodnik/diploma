resource "google_compute_instance" "tools_vm" {
  name = "tools-vm"
  machine_type = "e2-medium"
  zone = "europe-central2-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main_subnet.id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get upgrade
    apt-get install -y docker.io docker-compose-v2
    systemctl enable docker
    systemctl start docker
  EOF
}