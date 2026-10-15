variable "terraform_github_environment_config" {
  description = <<-EOT
    OPTIONAL: Terraform configuration for var.environment. When set, creates an opinionated pair of GitHub environments (terraform-plan-<environment> and terraform-apply-<environment>). Defaults to null (no Terraform environments).

    These are set as plain environment variables on both the plan and apply environments (when set), unless overridden by var.configure_terraform_vars_as_secrets:
      - client_id                    -> ARM_CLIENT_ID (may be overridden per stage via plan.client_id / apply.client_id in case of read-only plan credentials.)
      - tenant_id                    -> ARM_TENANT_ID
      - subscription_id              -> ARM_SUBSCRIPTION_ID
      - backend_resource_group       -> BACKEND_RESOURCE_GROUP
      - backend_storage_account_name -> BACKEND_STORAGE_ACCOUNT_NAME

    A random TF_PLAN_ENCRYPTION_KEY secret is also generated and shared by the plan and apply environments.
  EOT
  type = object({
    client_id                    = optional(string)
    tenant_id                    = optional(string)
    subscription_id              = optional(string)
    backend_resource_group       = optional(string)
    backend_storage_account_name = optional(string)

    plan = optional(object({
      client_id           = optional(string)
      wait_timer          = optional(number, 0)
      can_admins_bypass   = optional(bool, true)
      prevent_self_review = optional(bool, false)
      required_reviewers = optional(object({
        existing_team_names = optional(list(string), [])
        existing_user_names = optional(list(string), [])
      }), {})
    }), {})
    apply = optional(object({
      client_id           = optional(string)
      wait_timer          = optional(number, 0)
      can_admins_bypass   = optional(bool, false)
      prevent_self_review = optional(bool, true)
      required_reviewers = optional(object({
        existing_team_names = optional(list(string), [])
        existing_user_names = optional(list(string), [])
      }), {})
    }), {})
  })
  default = null
}

variable "configure_terraform_vars_as_secrets" {
  description = "OPTIONAL: Whether the values set from var.terraform_github_environment_config (ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, BACKEND_RESOURCE_GROUP, BACKEND_STORAGE_ACCOUNT_NAME) are created as environment secrets instead of plain environment variables. TF_PLAN_ENCRYPTION_KEY is always a secret. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "github_environments" {
  description = "OPTIONAL: GitHub environments to create, keyed by environment name. These are fully configurable and independent of the SDLC environment (var.environment), so any number may be defined."
  type = map(object({
    wait_timer          = optional(number, 0)
    can_admins_bypass   = optional(bool, true)
    prevent_self_review = optional(bool, false)
    required_reviewers = optional(object({
      existing_team_names = optional(list(string), [])
      existing_user_names = optional(list(string), [])
    }), {})
    deployment_branch_policy = optional(object({
      protected_branches     = optional(bool, false)
      custom_branch_policies = optional(bool, false)
    }), {})
    variables = optional(map(string), {})
    secrets   = optional(map(object({ value = string })), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for v in var.github_environments : !(v.deployment_branch_policy.protected_branches && v.deployment_branch_policy.custom_branch_policies)])
    error_message = "deployment_branch_policy.protected_branches and custom_branch_policies are mutually exclusive."
  }
  validation {
    condition = length(setintersection(
      keys(var.github_environments),
      ["terraform-plan-${var.environment}", "terraform-apply-${var.environment}"],
    )) == 0
    error_message = "github_environments names must not collide with the terraform-plan-<environment> / terraform-apply-<environment> names derived from var.environment."
  }
}
