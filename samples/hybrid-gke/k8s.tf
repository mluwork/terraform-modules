provider "kubernetes" {
  host  = "https://${module.gke-cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    module.gke-cluster.ca_certificate,
  )
}

# create a namespace for apigee
resource "kubernetes_namespace" "apigee" {
  metadata {
    labels = {
      name = "apigee"
    }
    name = "apigee"
  }
}

# step 1, read the service accounts and make them available as data
#data "kubernetes_service_account" "default" {
#  metadata {
#    name = "apigee"
#  }
#
#  depends_on = [
#    module.gke-cluster
#  ]
#
#  # read the service accounts
#}
