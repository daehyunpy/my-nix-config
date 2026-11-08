terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}

provider "github" {
  owner = "daehyunpy"
}

resource "github_repository" "config" {
  name       = "my-nix-config"
  visibility = "public"

  has_issues   = true
  has_projects = true
  has_wiki     = true

  delete_branch_on_merge = true

  # This resource adopts an existing repository, not a disposable environment.
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_ruleset" "main" {
  name        = "main-protection"
  repository  = github_repository.config.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  # No bypass actors: these rules apply to administrators too.
  rules {
    # Intentionally omit required_status_checks for this solo-maintainer project:
    # CI still runs, but neither passing checks nor an up-to-date branch gates merging.
    deletion         = true
    non_fast_forward = true

    pull_request {
      # Require a PR without preventing the sole maintainer from merging it.
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = ["squash"]
    }
  }
}
