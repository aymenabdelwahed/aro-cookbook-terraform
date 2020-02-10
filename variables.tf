variable "subscription" {}

variable "aro_name" {
  description = "The Azure Red Hat OpenShift (ARO) name"
}

variable "aro_resource_group_name" {
  description = "Name of resource group to deploy ARO resources in."
}

variable "aro_location" {
  description = "The ACR location where all resources should be created"
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {
    environment = "Production"
  }
}

variable "aro_aadClientId" {
  description = "The Application ID used by the Azure Red Hat OpenShift"
}

variable "aro_osa_admins_group_id" {
    description = "The OSA Adminstrators Group ID"
}

#variable "aro_loganalytics_workspace" {
#    description = "The LogAnalytics WorkSpace ObjectID"
#}

variable "aro_loganalytics_workspace_name" {
    description = "The LogAnalytics WorkSpace Name"
}

variable "aro_loganalytics_workspace_resource_group" {
    description = "The LogAnalytics WorkSpace Name in which the LogAnayltics Workspace is located"
}

variable "aro_compute_nodesize" {
  description = "The ARO Worker nodes size"
}

variable "aro_compute_nodecount" {
  type        = number
  description = "The ARO Worker nodes count"
}

variable "aro_vnet_iprange" {
  description = "The IP Range assigned to the ARO VNET"
}

variable "aro_subnet_iprange" {
  description = "The IP Range assigned to the ARO Subnet"
}

#variable "peerVnetId" {
#  description = "The Object ID of the peering VNET"
#}

variable "peerVnet_name" {
  description = "The Name of the peering VNET"
}

variable "peerVnet_resource_group_name" {
  description = "The Resource Group of the peering VNET"
}
