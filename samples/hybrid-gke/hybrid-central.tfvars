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

ax_region = "us-central1"

# CHANGE ME
tf_service_account     = "apigee-cicd-sa@apigee-hybrid-proj.iam.gserviceaccount.com"
project_create         = false
vpc_create             = false
org_create             = false
env_create             = false
vpc_host_project       = "CHANGE ME"
network                = "CHANGE ME"
network_self_link      = "CHANGE ME"
cert_manager_helm_repo = "oci://us-central1-docker.pkg.dev/<CHANGE ME to PROJECT_ID>/<ARTIFACT REGISTRY ID>/charts"

apigee_environments = {
  dev = {
    display_name = "dev"
    description  = "Environment created by apigee/terraform-modules"
    node_config  = null
    iam          = null
    envgroups    = ["dev"]
  }
  test = {
    display_name = "test"
    description  = "Environment created by apigee/terraform-modules"
    node_config  = null
    iam          = null
    envgroups    = ["test"]
  }
}

# CHANGE ME
apigee_envgroups = {
  dev = {
    hostnames = ["dev.example.com"]
  }
  test = {
    hostnames = ["test.example.com"]
  }
}

# subnets = [{
#   name          = "dev-apigee-gke-nodes"
#   description   = "DEV Subnet for K8s Kubernetes Cluster on us-central1"
#   ip_cidr_range = "172.28.13.0/24"
#   region        = var.ax_region
#   secondary_ip_range = {
#     pods     = "10.100.0.0/20"
#     services = "10.101.0.0/23"
#   }
# }]

# CHANGE ME
gke_cluster = {
  location = var.ax_region
  master_authorized_ranges = {
    "workstation" = "34.139.202.148/32" # This will need to be updated to your IP address or network range.
  }
  subnetwork               = "CHANGE ME - self_link (FQDN) for the subnet"
  master_ip_cidr           = "172.28.12.16/28"
  name                     = "hybrid-cluster"
  region                   = var.ax_region
  secondary_range_pods     = "CHANGE ME"
  secondary_range_services = "CHANGE ME"
}

node_preemptible_runtime = false
node_locations_data      = ["us-central1-a", "us-central1-b", "us-central1-c"]
