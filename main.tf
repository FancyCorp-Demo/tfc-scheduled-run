terraform {
  cloud {
    organization = "fancycorp"

    workspaces {
      name = "tfc-scheduled-run"
    }
  }
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "< 1.0.0"
    }
  }
}

provider "tfe" {
  organization = "fancycorp"
}

resource "tfe_team" "gh-actions-autoplan" {
  name = "gh-actions-autoplan"
}

locals {
  workspaces = toset([
    "workspace-ages",
  ])
}

resource "local_file" "workflow" {
  content = templatefile(
    "workflow.tmpl.yml",
    {
      workspaces = local.workspaces,
    }
  )

  filename = ".github/workflows/terraform-cloud.apply.workflow.yml"
}

data "tfe_workspace" "ws" {
  for_each = local.workspaces
  name     = each.key
}

resource "tfe_team_access" "access" {
  for_each = local.workspaces

  permissions {
    run_tasks         = false
    runs              = "apply"
    sentinel_mocks    = "none"
    state_versions    = "none"
    variables         = "none"
    workspace_locking = false
  }

  team_id      = tfe_team.gh-actions-autoplan.id
  workspace_id = data.tfe_workspace.ws[each.key].id
}
