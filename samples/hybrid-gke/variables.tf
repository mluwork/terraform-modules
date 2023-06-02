/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "ax_region" {
  description = "GCP region for storing Apigee analytics data (see https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli)."
  type        = string
}

variable "apigee_envgroups" {
  description = "Apigee Environment Groups."
  type = map(object({
    hostnames = list(string)
  }))
  default = {}
}

variable "apigee_environments" {
  description = "Apigee Environments."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    iam          = optional(map(list(string)))
    envgroups    = list(string)
  }))
  default = null
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "project_parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.project_parent == null || can(regex("(organizations|folders)/[0-9]+", var.project_parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = false
}

variable "network" {
  description = "Network name to be used for hosting the Apigee hybrid cluster."
  type        = string
  default     = "apigee-network"
}

variable "network_self_link" {
  description = "The self_link FQDN for the host VPC. Required if var.vpc_create is false."
  type        = string
  default     = null
}

variable "subnets" {
  description = "Subnets to be greated in the network."
  type = list(object({
    name               = string
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  }))
  default = []
}

variable "gke_cluster" {
  description = "GKE Cluster Specification"
  type = object({
    name                     = string
    region                   = string
    location                 = string
    master_ip_cidr           = string
    master_authorized_ranges = map(string)
    subnetwork               = string
    secondary_range_pods     = string
    secondary_range_services = string
  })
  default = {
    location = "us-central1"
    master_authorized_ranges = {
      "internet" = "0.0.0.0/8"
    }
    master_ip_cidr           = "192.168.0.0/28"
    name                     = "hybrid-cluster"
    region                   = "us-central1"
    secondary_range_pods     = "pods"
    secondary_range_services = "services"
    subnetwork               = "CHANGE_ME LINK TO SUBNETWORK"
  }
}

variable "node_preemptible_runtime" {
  description = "Use preemptible VMs for runtime node pool"
  type        = bool
  default     = null
}

variable "node_locations_data" {
  description = "List of locations for the data node pool"
  type        = list(string)
  default     = null
}

variable "node_machine_type_runtime" {
  description = "Machine type for runtime node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "node_machine_type_data" {
  description = "Machine type for data node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "deploy_sealed_secrets" {
  description = "Deploy the sealed-secrets operator (see https://github.com/bitnami-labs/sealed-secrets)."
  type        = bool
  default     = true
}

variable "tf_service_account" {
  description = "Service account used by Terraform"
  type        = string
}

variable "org_create" {
  description = "Create Apigee Organization"
  type        = bool
  default     = false
}

variable "vpc_create" {
  description = "Create VPC network and subnets"
  type        = bool
  default     = true
}

variable "env_create" {
  description = "Create the Apigee Environments and Groups"
  type        = bool
  default     = true
}

variable "vpc_host_project" {
  description = "The host project which shares SNETs with this project."
  type        = string
  default     = null
}

variable "nodepool_service_account_email" {
  description = "The Service Account email to use with the Node Pool"
  type        = string
  default     = null
}
variable "nodepool_service_account_create" {
  description = "Should create the nodepool_service_account from the provided email"
  type        = bool
  default     = false
}

variable "cert_manager_helm_repo" {
  description = "The repository to use for cert-manager helm charts."
  type        = string
  default     = "https://charts.jetstack.io"
}
