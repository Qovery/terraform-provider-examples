terraform {
  required_providers {
    qovery = {
      source = "qovery/qovery"
    }
  }
}

provider "qovery" {
  token = var.qovery_access_token
}

resource "qovery_cluster" "cluster_z9d173239" {
  organization_id = var.qovery_organization_id
  credentials_id  = var.qovery_gcp_credentials_id
  name            = "gcp-cluster-with-custom-kms-key"
  cloud_provider  = "GCP"
  region          = "europe-west9"
  state           = "READY"
  kubernetes_mode = "MANAGED"

  instance_type = "AUTO_PILOT"

  # Set your GKE KMS Key in your cluster features
  features = {
    gke_kms_key = "projects/my-project/locations/europe-west9/keyRings/my-key-ring/cryptoKeys/my-key"
  }
}
