locals {
  tf = var.terraform_github_environment_config

  # Environment variables shared by both stages of the terraform environments (plan and apply).
  # Unset (null) values are dropped so no empty variable is created.
  terraform_shared_variables = local.tf == null ? {} : {
    for k, v in {
      ARM_TENANT_ID                = local.tf.tenant_id
      ARM_SUBSCRIPTION_ID          = local.tf.subscription_id
      BACKEND_RESOURCE_GROUP       = local.tf.backend_resource_group
      BACKEND_STORAGE_ACCOUNT_NAME = local.tf.backend_storage_account_name
    } : k => v if v != null
  }

  # client_id is set at the top-level by default, with an optional per-stage override (i.e. for differnet plan/apply credentials).
  terraform_client_ids = local.tf == null ? {} : {
    plan  = try(coalesce(local.tf.plan.client_id, local.tf.client_id), null)
    apply = try(coalesce(local.tf.apply.client_id, local.tf.client_id), null)
  }

  # Everything set per stage from terraform_github_environment_config (plain strings, nulls dropped).
  terraform_stage_values = local.tf == null ? {} : {
    for stage in ["plan", "apply"] : stage => merge(
      local.terraform_shared_variables,
      local.terraform_client_ids[stage] == null ? {} : { ARM_CLIENT_ID = local.terraform_client_ids[stage] },
    )
  }

  # The terraform environment expands to an opinionated plan/apply pair:
  # plan is open to any branch, apply is restricted to protected branches.
  # The values above are environment variables, or secrets when
  # var.configure_terraform_vars_as_secrets is set. Both stages share the same
  # TF_PLAN_ENCRYPTION_KEY (always a secret) so apply can decrypt the saved plan.
  terraform_stages = local.tf == null ? {} : {
    for stage, settings in { plan = local.tf.plan, apply = local.tf.apply } : "terraform-${stage}-${var.environment}" => merge(settings, {
      deployment_branch_policy = { protected_branches = stage == "apply", custom_branch_policies = false }
      variables                = { for k, v in local.terraform_stage_values[stage] : k => v if !var.configure_terraform_vars_as_secrets }
      secrets = merge(
        { for k, v in local.terraform_stage_values[stage] : k => { value = v } if var.configure_terraform_vars_as_secrets },
        { TF_PLAN_ENCRYPTION_KEY = { value = random_password.plan_encryption_key[0].result } },
      )
    })
  }

  # Single normalised map, keyed by final GitHub environment name.
  environments_by_name = merge(local.terraform_stages, var.github_environments)

  # Reviewer names to look up, keyed by "<env>:<index>" rather than by name so
  # the keys are known at plan time even when a name comes from a resource
  # created in the same run (e.g. a team slug output).
  reviewer_team_lookups = merge([
    for env, v in local.environments_by_name : {
      for i, name in v.required_reviewers.existing_team_names : "${env}_${i}" => name
    }
  ]...)
  reviewer_user_lookups = merge([
    for env, v in local.environments_by_name : {
      for i, name in v.required_reviewers.existing_user_names : "${env}_${i}" => name
    }
  ]...)

  # Same map with reviewer names resolved to the numeric IDs the GitHub API requires.
  environments = {
    for env, v in local.environments_by_name : env => merge(v, {
      required_reviewers = {
        teams = [for i, _ in v.required_reviewers.existing_team_names : tonumber(data.github_team.reviewers["${env}_${i}"].id)]
        users = [for i, _ in v.required_reviewers.existing_user_names : tonumber(data.github_user.reviewers["${env}_${i}"].id)]
      }
    })
  }

  # Flattened "<env>:<name>" maps driving one for_each per child resource.
  environment_variables = merge([
    for env, v in local.environments : {
      for name, value in v.variables : "${env}:${name}" => { env = env, name = name, value = value }
    }
  ]...)

  environment_secrets = merge([
    for env, v in local.environments : {
      for name, secret in v.secrets : "${env}:${name}" => { env = env, name = name, value = secret.value }
    }
  ]...)
}
