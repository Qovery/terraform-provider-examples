# GKE KMS Key 

The KMS key can be set through your `qovery_cluster` `features`:
```tf
resource "qovery_cluster" "cluster_z9d173239" {
  // ...
  features = {
    gke_kms_key = "projects/my-project/locations/europe-west9/keyRings/my-key-ring/cryptoKeys/my-key"
  }
}
```

Configure carefully your KMS key permissions to ensure successful cluster installation: [doc here](https://www.qovery.com/docs/configuration/integrations/kubernetes/gke/managed#cmek-requirements-optional)


