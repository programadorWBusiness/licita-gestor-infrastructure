output "ecs_cluster_id" {
  description = "The ID of the ECS Cluster"
  value       = module.ecs_cluster.cluster_id
}

output "database_endpoint" {
  description = "The endpoint for the RDS database"
  value       = module.rds.db_instance_endpoint
}
