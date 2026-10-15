# Soft recommendation: warns (never fails) when the apply environment has no reviewers.
check "apply_has_required_reviewers" {
  assert {
    condition = var.terraform_github_environment_config == null || (
      length(var.terraform_github_environment_config.apply.required_reviewers.existing_team_names) +
      length(var.terraform_github_environment_config.apply.required_reviewers.existing_user_names) > 0
    )
    error_message = "Recommended: set at least one team or user under terraform_github_environment_config.apply.required_reviewers so Terraform applies require approval."
  }
}
