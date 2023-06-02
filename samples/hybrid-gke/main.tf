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

locals {
  envgroups   = { for key, value in var.apigee_envgroups : key => value.hostnames }
  vpc_project = var.vpc_create ? module.project.project_id : var.vpc_host_project
}

data "google_client_config" "provider" {}

provider "helm" {
  kubernetes {
    host  = "https://${module.gke-cluster.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      module.gke-cluster.ca_certificate,
    )
  }
}

module "project" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v16.0.0"
  name            = var.project_id
  parent          = var.project_parent
  billing_account = var.billing_account
  project_create  = var.project_create
  services = [
    "apigee.googleapis.com",
    "apigeeconnect.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "pubsub.googleapis.com",
    "sourcerepo.googleapis.com",
  ]

  # organization policies

  # org_policies = {
  #   "iam.disableServiceAccountKeyCreation" = {
  #     rules = [ { enforce = true }]
  #   }
  # }



  # additional IAM grants to service accounts
  # iam_additive = {
  #   "roles/editor" = ["serviceAccount:${var.tf_service_account}"]
  # }

  # logging 

  # logging_sinks = {
  #   warnings = {
  #     destination = module.bucket.id
  #     filter = "severity=DEBUG"
  #     exclusions = {
  #       no-compute = "logName:compute"
  #     }

  #     type = "logging"
  #   }
  # }
}

# module "bucket" {
#   source = "github.com/terraform-google-mocules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
#   parent_type = "project"
#   parent = var.project_id
#   id    = "logging_bucket"
# }

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
  project_id = local.vpc_project
  name       = var.network
  subnets    = var.subnets
  vpc_create = var.vpc_create
}

module "apigee" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/apigee?ref=v19.0.0"
  project_id = module.project.project_id
  organization = var.org_create ? {
    runtime_type     = "HYBRID"
    analytics_region = var.ax_region
  } : null
  envgroups    = var.env_create ? local.envgroups : null
  environments = var.env_create ? var.apigee_environments : null
}

module "gke-cluster" {
  source                   = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gke-cluster?ref=v16.0.0"
  project_id               = module.project.project_id
  name                     = var.gke_cluster.name
  location                 = var.gke_cluster.location
  network                  = var.vpc_create ? module.vpc.self_link : var.network_self_link
  subnetwork               = var.vpc_create ? module.vpc.subnet_self_links["${var.gke_cluster.region}/hybrid-${var.gke_cluster.region}"] : var.gke_cluster.subnetwork
  secondary_range_pods     = var.gke_cluster.secondary_range_pods
  secondary_range_services = var.gke_cluster.secondary_range_services
  master_authorized_ranges = var.gke_cluster.master_authorized_ranges
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false # Change to true to remove external ip address.
    master_ipv4_cidr_block  = var.gke_cluster.master_ip_cidr
    master_global_access    = true
  }
  addons = {
    cloudrun_config            = false
    dns_cache_config           = false
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
    istio_config = {
      enabled = false
      tls     = false
    }
    network_policy_config                 = false
    gce_persistent_disk_csi_driver_config = true
    gcp_filestore_csi_driver_config       = false
    config_connector_config               = false
    kalm_config                           = false
    gke_backup_agent_config               = false
  }
}

module "gke-nodepool-runtime" {
  source                      = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gke-nodepool?ref=v16.0.0"
  project_id                  = module.project.project_id
  cluster_name                = module.gke-cluster.name
  location                    = module.gke-cluster.location
  name                        = "apigee-runtime"
  node_machine_type           = var.node_machine_type_runtime
  node_preemptible            = var.node_preemptible_runtime
  initial_node_count          = 1
  node_tags                   = ["apigee-hybrid", "apigee-runtime"]
  node_service_account        = var.nodepool_service_account_email
  node_service_account_create = var.nodepool_service_account_create
}

module "gke-nodepool-data" {
  source                      = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gke-nodepool?ref=v16.0.0"
  project_id                  = module.project.project_id
  cluster_name                = module.gke-cluster.name
  location                    = module.gke-cluster.location
  name                        = "apigee-data"
  node_machine_type           = var.node_machine_type_data
  initial_node_count          = 1
  node_tags                   = ["apigee-hybrid", "apigee-data"]
  node_locations              = var.node_locations_data
  node_service_account        = var.nodepool_service_account_email
  node_service_account_create = var.nodepool_service_account_create
  node_disk_type              = "pd-balanced"
}

# resource "google_sourcerepo_repository" "apigee-k8s" {
#   project = module.project.project_id
#   name    = "apigee-config"
# }

resource "google_compute_firewall" "allow-master-webhook" {
  project     = var.vpc_create ? module.project.project_id : var.vpc_host_project
  name        = "gke-master-apigee-webhooks"
  description = "gke-master-apigee-webhooks"
  network     = module.vpc.self_link
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["9443"]
  }
  target_tags = ["apigee-hybrid"]
  source_ranges = [
    var.gke_cluster.master_ip_cidr,
  ]
}

## Change Me to use the Artifact Registry with self-hosted images and helm charts
## Alternatively, use quay.io/jetstack repository if the Nodes have access to the internet.
resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = var.cert_manager_helm_repo
  chart      = "cert-manager"
  version    = "v1.7.3"

  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    module.gke-cluster
  ]

}

## May need to pull from self-managed source (file or bucket)
resource "helm_release" "sealed-secrets" {
  count      = var.deploy_sealed_secrets ? 1 : 0
  name       = "sealed-secrets-controller"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.7.0"
  namespace  = "kube-system"

  depends_on = [
    module.gke-cluster
  ]

}

# resource "google_compute_firewall" "allow-master-kubeseal" {
#   count     = var.deploy_sealed_secrets ? 1 : 0
#   project   = module.project.project_id
#   name      = "gke-master-kubeseal"
#   network   = module.vpc.self_link
#   direction = "INGRESS"
#   allow {
#     protocol = "tcp"
#     ports    = ["8080"]
#   }
#   target_tags = ["apigee-hybrid"]
#   source_ranges = [
#     var.gke_cluster.master_ip_cidr,
#   ]
# }

# module "nat" {
#   source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat?ref=v16.0.0"
#   project_id     = var.vpc_create ? module.project.project_id : var.vpc_host_project
#   region         = var.gke_cluster.region
#   name           = "nat-${var.gke_cluster.region}"
#   router_network = module.vpc.self_link
# }

# If the organization does not allow control of IAM Policy etc. then comment out the "iam" and "iam_project_roles" blocks.
module "apigee-service-account" {
  source       = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v16.0.0"
  project_id   = module.project.project_id
  name         = "apigee-all-sa"
  display_name = "apigee-all-sa"
  description  = "Apigee Service Account"
  # iam = {
  #   "roles/iam.serviceAccountUser" = [
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-cassandra-schema-setup-svc-account-${module.project.project_id}]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-cassandra-user-setup-svc-account-${module.project.project_id}]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-connect-agent-svc-account-${module.project.project_id}]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-datastore-svc-account]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-mart-svc-account-${module.project.project_id}]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-metrics-adapter-svc-account]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-metrics-app-svc-account]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-metrics-proxy-svc-account]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-redis-default-svc-account]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-redis-envoy-default-svc-account]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-runtime-svc-account-${module.project.project_id}-test1]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-synchronizer-svc-account-${module.project.project_id}-test1]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-udca-svc-account-${module.project.project_id}-test1]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-udca-svc-account-${module.project.project_id}]",
  #     "serviceAccount:${module.project.project_id}.svc.id.goog[apigee/apigee-watcher-svc-account-${module.project.project_id}]",
  #   ]
  # }
  # iam_project_roles = {
  #   "${module.project.project_id}" = [
  #     "roles/logging.logWriter",
  #     "roles/monitoring.metricWriter",
  #     "roles/storage.objectAdmin",
  #     "roles/apigee.analyticsAgent",
  #     "roles/apigee.synchronizerManager",
  #     "roles/apigeeconnect.Agent",
  #     "roles/apigee.runtimeAgent"
  #   ]
  # }
  depends_on = [
    module.gke-cluster
  ]
}
