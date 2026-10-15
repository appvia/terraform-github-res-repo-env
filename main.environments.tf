resource "github_repository_environment" "this" {
  for_each            = local.environments
  repository          = var.repo_name
  environment         = each.key
  wait_timer          = each.value.wait_timer
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review
  dynamic "reviewers" {
    for_each = length(each.value.required_reviewers.teams) + length(each.value.required_reviewers.users) > 0 ? [each.value.required_reviewers] : []
    content {
      teams = reviewers.value.teams
      users = reviewers.value.users
    }
  }
  # GitHub rejects a policy with both flags false (422), so the block is only
  # emitted when one is set. Omitting it leaves the environment open to any branch.
  dynamic "deployment_branch_policy" {
    for_each = each.value.deployment_branch_policy.protected_branches || each.value.deployment_branch_policy.custom_branch_policies ? [each.value.deployment_branch_policy] : []
    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = deployment_branch_policy.value.custom_branch_policies
    }
  }
}
