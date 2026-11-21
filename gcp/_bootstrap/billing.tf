# Budgets on the USD billing account. Budgets belong to the billing account, not to a
# project, so they live here even when they watch a project managed elsewhere.
#
# claude-agent has only roles/billing.viewer: enough to read and import budgets, but any
# change here needs billing.costsManager, i.e. an apply by a human.

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
