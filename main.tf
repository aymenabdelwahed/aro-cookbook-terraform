terraform {
  required_version = ">= 0.12.0"
  required_providers {
    azurerm = "~> 1.43.0"
  }
}

provider "azurerm" {
    version = ">=1.43.0"
    subscription_id = var.subscription 
}

#The Application Registration already provided by AzureAD Administrator
data "azuread_service_principal" "azure_aro_service_principal" {
  application_id = var.aro_aadClientId
}

#Generate a New Secret and Assign it to the new ARO Cluster
resource "azuread_service_principal_password" "azure_aro_service_principal_secret" {
  service_principal_id  = data.azuread_service_principal.azure_aro_service_principal.id
  value                 = random_password.azure_aro_generated_secret.result
  end_date              = timeadd(timestamp(), "44000h")
}

resource "random_password" "azure_aro_generated_secret" {
  length                = 32
  special               = true
}

resource "azurerm_resource_group" "azure-aro-rg" {
  name = var.aro_resource_group_name
  location = var.aro_location
}

#Retrieve data related to the current Tenant ID
data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "peeringVnet" {
  name = var.peerVnet_name
  resource_group_name = var.peerVnet_resource_group_name
}

data "azurerm_log_analytics_workspace" "loganalytics" {
  name = var.aro_loganalytics_workspace_name
  resource_group_name = var.aro_loganalytics_workspace_resource_group
}

##Ensure to create first the Azure LogAnalytics Workspace
resource "azurerm_template_deployment" "azure-arocluster" {
  #name (Required) Specifies the name of the template deployment. Changing this forces a new resource to be created.
  name  = var.aro_name

  #resource_group_name  (Required) The name of the ResourceGroup in which to create the template deployment
  resource_group_name = var.aro_resource_group_name

  #File: Reads the contents of a file at the given path and returns them as a string
  template_body = file("${path.module}/azurerm_AROClusterTemplate.json")

  #These key-value pairs are provided as parameters to the ARM template
  parameters = {
    "clusterName": var.aro_name
    "location": var.aro_location
    "aadTenantId": data.azurerm_client_config.current.tenant_id
    "aadClientId": var.aro_aadClientId
    "aadClientSecret": random_password.azure_aro_generated_secret.result
    "aadCustomerAdminGroupId": var.aro_osa_admins_group_id
    "computeNodeType": var.aro_compute_nodesize
    "clusterVnetIPRange": var.aro_vnet_iprange
    "clusterSubnetIPRange": var.aro_subnet_iprange
    "peerVnetId": data.azurerm_virtual_network.peeringVnet.id
    "workspaceResourceId": data.azurerm_log_analytics_workspace.loganalytics.id
  }
  
  #(Required) Specifies the mode that is used to deploy resources.
  #This value could be either Incremental or Complete.
  #Note that you will almost always want this be set to Incremental otherwise the deployment will destroy all Infrastructure not specified within the template, and Terraform will not be aware of this.
  deployment_mode = "Incremental"

  depends_on = [
    azurerm_resource_group.azure-aro-rg,
    data.azurerm_log_analytics_workspace.loganalytics
  ]
}

resource "null_resource" "updateAppRegistration" {
  provisioner "local-exec" {
    command = <<EOC
      az ad app update --id ${var.aro_aadClientId} --reply-urls "https://$(az openshift show -n ${var.aro_name}  -g ${var.aro_resource_group_name} --query publicHostname -o tsv)/oauth2callback/Azure%20AD"
    EOC
    interpreter = ["/bin/bash", "-c"]
  }
   depends_on = [
     azurerm_template_deployment.azure-arocluster
   ]
}
