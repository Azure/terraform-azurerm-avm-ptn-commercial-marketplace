# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for license information.

# ==============================================================================
# Microsoft Graph API — Well-Known IDs (defined in locals.tf)
# ==============================================================================

# ==============================================================================
# 1. Fulfillment API App Registration (Single-Tenant)
#    Used for authenticating calls to the Marketplace SaaS Fulfillment API.
# ==============================================================================

resource "azuread_application" "fulfillment" {
  count = local.create_fulfillment_app ? 1 : 0

  display_name     = "${var.webapp_name_prefix}-FulfillmentAppReg"
  sign_in_audience = "AzureADMyOrg"

  required_resource_access {
    resource_app_id = local.microsoft_graph_app_id

    resource_access {
      id   = local.user_read_scope_id
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "fulfillment" {
  count = local.create_fulfillment_app ? 1 : 0

  client_id = azuread_application.fulfillment[0].client_id
}

resource "time_rotating" "fulfillment_secret" {
  count = local.create_fulfillment_app ? 1 : 0

  rotation_days = 730 # 2 years
}

resource "azuread_application_password" "fulfillment" {
  count = local.create_fulfillment_app ? 1 : 0

  application_id = azuread_application.fulfillment[0].id
  display_name   = "SaaSAPI"
  end_date       = timeadd(time_rotating.fulfillment_secret[0].id, "17520h") # ~2 years
  rotate_when_changed = {
    rotation = time_rotating.fulfillment_secret[0].id
  }
}

# ==============================================================================
# 2. Admin Portal SSO App Registration
#    Single-tenant by default (configurable via is_admin_portal_multi_tenant).
#    Enables OpenID Connect sign-in for the Publisher Admin Portal.
# ==============================================================================

resource "azuread_application" "admin_portal" {
  count = local.create_admin_app ? 1 : 0

  display_name     = "${var.webapp_name_prefix}-AdminPortalAppReg"
  sign_in_audience = var.is_admin_portal_multi_tenant ? "AzureADandPersonalMicrosoftAccount" : "AzureADMyOrg"

  api {
    requested_access_token_version = 2
  }
  required_resource_access {
    resource_app_id = local.microsoft_graph_app_id

    resource_access {
      id   = local.user_read_scope_id
      type = "Scope"
    }
  }
  web {
    logout_url = "https://${local.webapp_admin_name}.azurewebsites.net/logout"
    redirect_uris = [
      "https://${local.webapp_admin_name}.azurewebsites.net/",
      "https://${local.webapp_admin_name}.azurewebsites.net/Home/Index",
      "https://${local.webapp_admin_name}.azurewebsites.net/Home/Index/",
    ]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
}

# ==============================================================================
# 3. Landing Page SSO App Registration (Multi-Tenant)
#    Enables OpenID Connect sign-in for the Customer Portal (landing page).
# ==============================================================================

resource "azuread_application" "landing_page" {
  count = local.create_portal_app ? 1 : 0

  display_name     = "${var.webapp_name_prefix}-LandingpageAppReg"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  api {
    requested_access_token_version = 2
  }
  required_resource_access {
    resource_app_id = local.microsoft_graph_app_id

    resource_access {
      id   = local.user_read_scope_id
      type = "Scope"
    }
  }
  web {
    logout_url = "https://${local.webapp_portal_name}.azurewebsites.net/logout"
    redirect_uris = [
      "https://${local.webapp_portal_name}.azurewebsites.net/",
      "https://${local.webapp_portal_name}.azurewebsites.net/Home/Index",
      "https://${local.webapp_portal_name}.azurewebsites.net/Home/Index/",
    ]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
}
