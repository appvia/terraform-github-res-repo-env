output "environment_names" {
  description = "GitHub Actions environment names created, keyed by environment name."
  value       = { for k, v in github_repository_environment.this : k => v.environment }
}

output "environment_ids" {
  description = "Node IDs of the GitHub Actions environments created, keyed by environment name."
  value       = { for k, v in github_repository_environment.this : k => v.id }
}
