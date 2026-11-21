# Budgets on the USD billing account. Budgets belong to the billing account, not to a
# project, so they live here even when they watch a project managed elsewhere.
#
# claude-agent has roles/billing.costsManager on the USD account (see agent.tf), so it can
# apply changes here.

import {
  to = google_billing_budget.noxvpn
  id = "billingAccounts/01C100-B62CB3-89CCC4/budgets/43740a40-564e-4e34-90ac-5c6d43cbb5ba"
}

# Watches noxvpn-skv384 (project number 136547520670). That project itself is managed in
# the noxvpn repo, not here. No notificationsRule: alerts go by email to billing account
# admins and users (the default).
resource "google_billing_budget" "noxvpn" {
  billing_account = local.billing_account
  display_name    = "noxvpn"

  budget_filter {
    projects               = ["projects/136547520670"]
    calendar_period        = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "15"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }
}

# One budget per project on the USD account. Same thresholds as noxvpn: email at 50%, 90%
# and 100% of actual spend, plus 100% of forecasted spend.

# thermal-history-343013 (project number 99257183987): Cloud Run noxapp, DNS zone,
# Artifact Registry, the archive snapshot of instance-1.
resource "google_billing_budget" "thermal" {
  billing_account = local.billing_account
  display_name    = "thermal-history"

  budget_filter {
    projects               = ["projects/99257183987"]
    calendar_period        = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "10"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }
}

# bro-project-511307 (project number 305470792638): VM fortg (e2-micro + IP + daily
# snapshots, roughly $8-10/month).
resource "google_billing_budget" "bro" {
  billing_account = local.billing_account
  display_name    = "bro-project"

  budget_filter {
    projects               = ["projects/305470792638"]
    calendar_period        = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "15"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }
}
