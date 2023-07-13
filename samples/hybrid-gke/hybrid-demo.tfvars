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

apigee_envgroups = {
  dev = {
    hostnames = ["dev.mlugpspso.joonix.net"]
  }
  test = {
    hostnames = ["test.mlugpspso.joonix.net"]
  }
}

subnets = [{
  name          = "hybrid-us-central1"
  ip_cidr_range = "172.28.0.0/16"
  region        = "us-central1"
  secondary_ip_range = {
    pods     = "10.100.0.0/20"
    services = "10.101.0.0/23"
  }
}]

# POC settings to reduce infrastructure cost
# reconsider using these for production!
node_preemptible_runtime = true
node_locations_data      = ["us-central1-b"]

tf_service_account = "apigee-cicd-sa@apigee-hybrid-proj.iam.gserviceaccount.com"