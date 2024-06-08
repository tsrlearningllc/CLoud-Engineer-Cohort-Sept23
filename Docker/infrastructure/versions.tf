terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.88.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = ">= 1.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}