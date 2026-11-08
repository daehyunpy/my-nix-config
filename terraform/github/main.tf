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

resource "github_repository_ruleset" "main" {
  name        = "main-protection"
  repository  = "my-nix-config"
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

    required_status_checks {
      strict_required_status_checks_policy = true

      required_check {
        context        = "Formatting and Linux evaluation"
        integration_id = 15368
      }

      required_check {
        context        = "Darwin evaluations"
        integration_id = 15368
      }
    }
  }
}
