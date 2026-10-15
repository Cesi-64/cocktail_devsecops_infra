terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.20, < 5.10"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # State distant dans Azure Storage : indispensable car la création et la
  # destruction se font dans des runs différents (CI, cron de 17h, reprise...).
  # resource_group_name et storage_account_name sont passés à "terraform init"
  # via -backend-config (voir le guide).
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "staging.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
  # Authentification OIDC : variables ARM_CLIENT_ID, ARM_TENANT_ID,
  # ARM_SUBSCRIPTION_ID et ARM_USE_OIDC=true fournies par la CI.
}
