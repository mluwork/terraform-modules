# create service accounts and workloads identity
locals {
  _role_sa = toset(flatten([
    for p, r in var.profile_roles : [
      for role in r : {
        role = role
        sa   = p
      }
    ]
  ]))

  role_sa_map = {
    for r in local._role_sa : "${r.role}:${r.sa}" => r
  }

  # helm charts uses 15 letter short name and the first 7 characters
  # of the sha256 hash of the organization name to build k8s service 
  # account names.
  apigee_org     = var.project_id
  org_hash       = substr(sha256(local.apigee_org), 0, 7)
  org_short_name = substr(local.apigee_org, 0, 15)
  gen_name       = format("%s-%s", local.org_short_name, local.org_hash)

  ksa_gsa_map = {
    "apigee-logger" : "apigee-logger"
    "apigee-watcher" : "apigee-watcher"
    "apigee-udca" : "apigee-udca"
    "apigee-connect-agent" : "apigee-mart"
    "apigee-mart" : "apigee-mart"
    "apigee-metrics" : "apigee-metrics"
  }

}

# create service accounts and role bindings

resource "google_service_account" "apigee_sa" {
  for_each = var.profiles

  account_id   = each.value
  display_name = "${each.value}-apigee-sa"
  project      = var.project_id
}

# create service accounts and role bindings

resource "google_project_iam_member" "apigee_sa" {
  for_each = local.role_sa_map
  project  = var.project_id
  role     = each.value.role
  member   = "serviceAccount:${google_service_account.apigee_sa[each.value.sa].email}"
}


# bind KSA to GSA

resource "google_service_account_iam_binding" "sa_binding" {
  for_each           = local.ksa_gsa_map
  service_account_id = google_service_account.apigee_sa[each.value].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[apigee/-${each.key}-${local.gen_name}-sa]"]
  depends_on = [
    google_project_iam_member.apigee_sa
  ]
}

