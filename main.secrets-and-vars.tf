resource "random_password" "plan_encryption_key" {
  count   = var.terraform_github_environment_config == null ? 0 : 1
  length  = 64
  special = false
}

resource "github_actions_environment_secret" "this" {
  for_each    = local.environment_secrets
  repository  = var.repo_name
  environment = github_repository_environment.this[each.value.env].environment
  secret_name = each.value.name
  value       = each.value.value
}

resource "github_actions_environment_variable" "this" {
  for_each      = local.environment_variables
  repository    = var.repo_name
  environment   = github_repository_environment.this[each.value.env].environment
  variable_name = each.value.name
  value         = each.value.value
}
