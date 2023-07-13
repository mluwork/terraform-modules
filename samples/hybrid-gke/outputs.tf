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

output "cluster_name" {
  description = "Cluster name."
  value       = module.gke-cluster.name
}

output "cluster_region" {
  description = "Cluster location."
  value       = module.gke-cluster.location
}

output "apigee_envgroups" {
  description = "Apigee Env Groups."
  value       = module.apigee.envgroups
}

output "apigee_environments" {
  description = "Apigee Environments"
  value       = module.apigee.environments
}

output "apigee_sas" {
  description = "Apigee Service Accounts"
  value       = [for sa in google_service_account.apigee_sa : sa.email]
}