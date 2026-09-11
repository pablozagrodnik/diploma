output "postgres_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "redis_private_ip" {
  value = google_redis_instance.cache.host
}
