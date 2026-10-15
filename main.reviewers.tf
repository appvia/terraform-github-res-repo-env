data "github_team" "reviewers" {
  for_each = local.reviewer_team_lookups
  slug     = each.value
}

data "github_user" "reviewers" {
  for_each = local.reviewer_user_lookups
  username = each.value
}
