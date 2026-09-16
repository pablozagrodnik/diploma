output "postgres_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "redis_private_ip" {
  value = google_redis_instance.cache.host
}

output "gke_service_account_email" {
  value = google_service_account.gke_sa.email
}

output "network_id" {
  value = google_compute_network.main_vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.main_subnet.id
}

output "tools_vm_name" {
  value = google_compute_instance.tools_vm.name
}

output "tools_vm_zone" {
  value = google_compute_instance.tools_vm.zone
}
