resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  deletion_policy = "ABANDON"
}

resource "google_sql_database_instance" "postgres" {
  name             = "thesis-db"
  database_version = "POSTGRES_16"
  region           = "europe-central2"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-custom-2-4096"
    availability_type = "ZONAL"
    disk_size         = 10

    database_flags {
      name  = "max_connections"
      value = "1000"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main_vpc.id
    }
  }

  deletion_protection = false
}

resource "google_sql_user" "default" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}

# resource "google_redis_instance" "cache" {
#   memory_size_gb     = 1
#   name               = "thesis-redis"
#   tier               = "BASIC"
#   region             = "europe-central2"
#   authorized_network = google_compute_network.main_vpc.id
#
#   depends_on = [google_service_networking_connection.private_vpc_connection]
# }
