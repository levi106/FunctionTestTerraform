provider "azurerm" {
  features {}
}

variable "RESOURCE_GROUP" {
  default = "func-rg-dedicated-linux"
}
variable "LOCATION" {
  default = "JapanEast"
}

resource "azurerm_resource_group" "example" {
  name     = var.RESOURCE_GROUP
  location = var.LOCATION
}

resource "random_string" "random" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

resource "azurerm_storage_account" "example" {
  name                     = "funcstorageacc${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "example-slot" {
  name                     = "funcstorageaccslot${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "example" {
  name = "func-application-insights"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  application_type = "other"
}

resource "azurerm_app_service_plan" "example" {
  name = "func-app-service-plan"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind = "Linux"
  reserved = "true"
  sku {
    tier = "PremiumV3"
    size = "P1v3"
  }
}

resource "azurerm_function_app" "example" {
  name = "func-function-app${random_string.random.result}"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_app_service_plan.example.id
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet",
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.example.instrumentation_key,
    WEBSITE_RUN_FROM_PACKAGE = "1",
    MYSETTING = "prod1"
  }
  os_type = "linux"
  storage_account_name = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  version = "~4"
  site_config {
    cors {
      allowed_origins = ["*"]
    }
  }
}

resource "azurerm_function_app_slot" "example-slot" {
  name = "staging"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_app_service_plan.example.id
  function_app_name = azurerm_function_app.example.name
  os_type = "linux"
  storage_account_name = azurerm_storage_account.example-slot.name
  storage_account_access_key = azurerm_storage_account.example-slot.primary_access_key
  version = "~4"
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet",
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.example.instrumentation_key,
    WEBSITE_RUN_FROM_PACKAGE = "1",
    MYSETTING = "staging1"
  }
  site_config {
    cors {
      allowed_origins = ["*"]
    }
  }
}