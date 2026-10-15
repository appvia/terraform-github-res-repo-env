<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://raw.githubusercontent.com/appvia/__REPO_NAME__/refs/heads/main/docs/banner.jpg" alt="Appvia Banner"/></a><br/><p align="right"> </a> <a href="https://registry.terraform.io/modules/appvia/__MODULE_NAME__/github/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a> <a href="https://github.com/appvia/__REPO_NAME__/releases/latest"><img src="https://img.shields.io/github/release/appvia/__REPO_NAME__.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/__REPO_NAME__/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/__REPO_NAME__.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: Placeholders (__REPO_NAME__, __MODULE_NAME__) are managed by scripts/init-from-template.sh ******
-->

![Github Actions](https://github.com/appvia/__REPO_NAME__/actions/workflows/terraform.yml/badge.svg)

# Terraform GitHub Repository Environments

## Description

Creates the per-environment GitHub Actions environments for a repository vended by [terraform-github-res-repo](https://github.com/appvia/terraform-github-res-repo), along with their deployment protection rules, variables and secrets.

`terraform-github-res-repo` deliberately only creates singleton, repository-scoped resources. This module fills the per-environment gap it leaves open.

Two inputs cover the two use cases:

- `terraform_github_environment_config` - for Terraform repos (default `null`). Each module call represents one SDLC environment, named by `var.environment` (e.g. `dev`, `stg`, `prd`). When set, the module creates `terraform-plan-<environment>` and `terraform-apply-<environment>` with opinionated settings: `apply` restricts deployments to protected branches and is intended to have at least one reviewer (recommended, not enforced - a warning is emitted if none are set); `plan` is open to any branch. Wait timer, admin bypass, self-review prevention and required reviewers can be set independently on each stage. A random `TF_PLAN_ENCRYPTION_KEY` secret is shared by the plan and apply environments, plus these optional values set on both stages: `client_id` (`ARM_CLIENT_ID`, overridable per stage), `tenant_id` (`ARM_TENANT_ID`), `subscription_id` (`ARM_SUBSCRIPTION_ID`), `backend_resource_group` (`BACKEND_RESOURCE_GROUP`) and `backend_storage_account_name` (`BACKEND_STORAGE_ACCOUNT_NAME`). These are environment variables by default; set `configure_terraform_vars_as_secrets = true` to create them as secrets instead.
- `github_environments` - any number of additional GitHub environments, not tied to the SDLC environment. Each entry maps directly onto one GitHub environment with granular control over protection rules, branch policy, variables and secrets.

## Usage

```hcl
module "repo_environments" {
  source  = "appvia/repo-env/github"
  version = "0.0.1"

  repo_name   = "example-repo"
  environment = "dev"

  terraform_github_environment_config = {
    apply = { required_reviewers = { existing_team_names = ["team-123456"] } }
  }

  github_environments = {
    production = {
      required_reviewers       = { existing_team_names = ["team-123456"] }
      deployment_branch_policy = { protected_branches = true }
      variables                = { REGION = "uksouth" }
    }
  }
}
```

## Examples

See the [examples](./examples) directory for working usage examples.

- [Basic](./examples/basic) - A basic example of how to use this module.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.13 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.13 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [github_actions_environment_secret.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_variable.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_repository_environment.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [random_password.plan_encryption_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | REQUIRED: Short name of the environment this module call represents (e.g. 'dev', 'stg', 'prd'). Used to name the Terraform plan/apply GitHub environments (terraform-plan-<environment> / terraform-apply-<environment>). | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | REQUIRED: Name of the GitHub repository to create. | `string` | n/a | yes |
| <a name="input_configure_terraform_vars_as_secrets"></a> [configure\_terraform\_vars\_as\_secrets](#input\_configure\_terraform\_vars\_as\_secrets) | OPTIONAL: Whether the values set from var.terraform\_github\_environment\_config (ARM\_CLIENT\_ID, ARM\_TENANT\_ID, ARM\_SUBSCRIPTION\_ID, BACKEND\_RESOURCE\_GROUP, BACKEND\_STORAGE\_ACCOUNT\_NAME) are created as environment secrets instead of plain environment variables. TF\_PLAN\_ENCRYPTION\_KEY is always a secret. Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_github_environments"></a> [github\_environments](#input\_github\_environments) | OPTIONAL: GitHub environments to create, keyed by environment name. These are fully configurable and independent of the SDLC environment (var.environment), so any number may be defined. | <pre>map(object({<br/>    wait_timer          = optional(number, 0)<br/>    can_admins_bypass   = optional(bool, true)<br/>    prevent_self_review = optional(bool, false)<br/>    required_reviewers = optional(object({<br/>      existing_team_names = optional(list(string), [])<br/>      existing_user_names = optional(list(string), [])<br/>    }), {})<br/>    deployment_branch_policy = optional(object({<br/>      protected_branches     = optional(bool, false)<br/>      custom_branch_policies = optional(bool, false)<br/>    }), {})<br/>    variables = optional(map(string), {})<br/>    secrets   = optional(map(object({ value = string })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_terraform_github_environment_config"></a> [terraform\_github\_environment\_config](#input\_terraform\_github\_environment\_config) | OPTIONAL: Terraform configuration for var.environment. When set, creates an opinionated pair of GitHub environments (terraform-plan-<environment> and terraform-apply-<environment>). Defaults to null (no Terraform environments).<br/><br/>These are set as plain environment variables on both the plan and apply environments (when set), unless overridden by var.configure\_terraform\_vars\_as\_secrets:<br/>  - client\_id                    -> ARM\_CLIENT\_ID (may be overridden per stage via plan.client\_id / apply.client\_id in case of read-only plan credentials.)<br/>  - tenant\_id                    -> ARM\_TENANT\_ID<br/>  - subscription\_id              -> ARM\_SUBSCRIPTION\_ID<br/>  - backend\_resource\_group       -> BACKEND\_RESOURCE\_GROUP<br/>  - backend\_storage\_account\_name -> BACKEND\_STORAGE\_ACCOUNT\_NAME<br/><br/>A random TF\_PLAN\_ENCRYPTION\_KEY secret is also generated and shared by the plan and apply environments. | <pre>object({<br/>    client_id                    = optional(string)<br/>    tenant_id                    = optional(string)<br/>    subscription_id              = optional(string)<br/>    backend_resource_group       = optional(string)<br/>    backend_storage_account_name = optional(string)<br/><br/>    plan = optional(object({<br/>      client_id           = optional(string)<br/>      wait_timer          = optional(number, 0)<br/>      can_admins_bypass   = optional(bool, true)<br/>      prevent_self_review = optional(bool, false)<br/>      required_reviewers = optional(object({<br/>        existing_team_names = optional(list(string), [])<br/>        existing_user_names = optional(list(string), [])<br/>      }), {})<br/>    }), {})<br/>    apply = optional(object({<br/>      client_id           = optional(string)<br/>      wait_timer          = optional(number, 0)<br/>      can_admins_bypass   = optional(bool, false)<br/>      prevent_self_review = optional(bool, true)<br/>      required_reviewers = optional(object({<br/>        existing_team_names = optional(list(string), [])<br/>        existing_user_names = optional(list(string), [])<br/>      }), {})<br/>    }), {})<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_environment_ids"></a> [environment\_ids](#output\_environment\_ids) | Node IDs of the GitHub Actions environments created, keyed by environment name. |
| <a name="output_environment_names"></a> [environment\_names](#output\_environment\_names) | GitHub Actions environment names created, keyed by environment name. |
<!-- END_TF_DOCS -->

## Contributing

Contributions are welcome. Please read the [Code of Conduct](./CODE_OF_CONDUCT.md) before contributing.

## License

This project is licensed under the terms of the [GPL-3.0 license](./LICENSE).
