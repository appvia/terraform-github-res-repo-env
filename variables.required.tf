variable "repo_name" {
  description = "REQUIRED: Name of the GitHub repository to create."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{1,100}$", var.repo_name))
    error_message = "name must be 1-100 characters and contain only letters, numbers, hyphens, underscores and periods."
  }
}

variable "environment" {
  description = "REQUIRED: Short name of the environment this module call represents (e.g. 'dev', 'stg', 'prd'). Used to name the Terraform plan/apply GitHub environments (terraform-plan-<environment> / terraform-apply-<environment>)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,30}$", var.environment))
    error_message = "environment must be 1-31 characters of lowercase letters, numbers and hyphens, starting with a letter or number."
  }
}
