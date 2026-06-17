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

locals {
  my_secret_manager_accesses = {
    for item in qovery_cluster.my_cluster.secret_manager_accesses : item.name => item
  }
}

resource "qovery_cluster" "my_cluster" {
  #
  # Basic AWS cluster with Karpenter mode
  organization_id   = var.qovery_organization_id
  credentials_id    = var.qovery_aws_credentials_id
  name              = "My cluster"
  state             = "READY"
  cloud_provider    = "AWS"
  region            = "eu-west-3"
  kubernetes_mode   = "MANAGED"
  production        = true
  disk_size         = 20
  min_running_nodes = 3
  max_running_nodes = 10
  features = {
    vpc_subnet = "10.0.0.0/16"
    static_ip  = "true"
    karpenter = {
      spot_enabled                 = true
      disk_size_in_gib             = 50
      default_service_architecture = "AMD64"
      qovery_node_pools = {
        requirements = [
          {
            key      = "InstanceSize"
            operator = "In"
            values   = ["medium", "large", "xlarge", "2xlarge", "3xlarge", "4xlarge", "6xlarge", "8xlarge", "9xlarge", "12xlarge", "16xlarge", "18xlarge", "24xlarge", "32xlarge"]
          },
          {
            key      = "Arch"
            operator = "In"
            values   = ["AMD64", "ARM64"]
          },
          {
            key      = "InstanceFamily"
            operator = "In"
            values   = ["c5", "c5a", "c5d", "c5n", "c6g", "c6gd", "c6gn", "c6i", "c6id", "c6in", "c7g", "c7gd", "c7i", "c7i-flex", "c8i", "c8i-flex", "d2", "d3", "i3", "i3en", "i4i", "i7ie", "im4gn", "inf2", "is4gen", "m5", "m5a", "m5ad", "m5d", "m6a", "m6g", "m6gd", "m6i", "m7g", "m7gd", "m7i", "m7i-flex", "m8g", "m8i", "m8i-flex", "r4", "r5", "r5a", "r5ad", "r5d", "r5dn", "r5n", "r6g", "r6gd", "r6i", "r7g", "r7gd", "r7i", "r8g", "r8i", "r8i-flex", "t2", "t3", "t3a", "t4g", "x2iedn"]
          }
        ]
        stable_override  = null
        default_override = null
      }
    }
  }
  routing_table = []

  #
  # Secret Manager Accesses
  secret_manager_accesses = [
    # You cannot have both AWS_ROLE_ARN and AUTOMATICALLY_CONFIGURED
    #{
    #  name = "Role arn"
    #  authentication = {
    #    type     = "AWS_ROLE_ARN"
    #    role_arn = var.aws_secret_manager_role_arn
    #  }
    #  endpoint = {
    #    type   = "AWS_SECRET_MANAGER"
    #    region = var.aws_secret_manager_region
    #  }
    #},
    {
      name = "Automatic configuration"
      authentication = {
        type = "AUTOMATICALLY_CONFIGURED"
      }
      endpoint = {
        type   = "AWS_SECRET_MANAGER"
        region = var.aws_secret_manager_region
      }
    },
    {
      name = "AWS Static Secret Manager configuration"
      authentication = {
        type       = "AWS_STATIC_CREDENTIALS"
        access_key = var.aws_secret_manager_access_key
        secret_key = var.aws_secret_manager_secret_key
        region     = var.aws_secret_manager_region
      }
      endpoint = {
        type   = "AWS_SECRET_MANAGER"
        region = var.aws_secret_manager_region
      }
    },
    {
      name = "GCP Secret Manager configuration"
      authentication = {
        type             = "GCP_JSON_CREDENTIALS"
        json_credentials = var.gcp_secret_manager_json_credentials_in_base64
      }
      endpoint = {
        type       = "GCP_SECRET_MANAGER"
        region     = var.gcp_secret_manager_region
        project_id = var.gcp_secret_manager_project_id
      }
    },
  ]
}

resource "qovery_project" "my_project" {
  organization_id = var.qovery_organization_id
  name            = "My project"
}

resource "qovery_environment" "my_environment" {
  project_id = qovery_project.my_project.id
  name       = "My environment"
  mode       = "PRODUCTION"
  cluster_id = qovery_cluster.my_cluster.id
  external_secrets = [
    {
      key                      = "ENVIRONMENT_EXTERNAL_SECRET"
      reference                = "reference/to/secret"
      secret_manager_access_id = local.my_secret_manager_accesses["AWS Static Secret Manager configuration"].id
      description              = ""
    },
  ]
  external_secret_files = [
    {
      key                      = "ENVIRONMENT_EXTERNAL_SECRET_MOUNTED"
      reference                = "reference/to/secret"
      secret_manager_access_id = local.my_secret_manager_accesses["AWS Static Secret Manager configuration"].id
      mount_path               = "/tmp"
      description              = ""
    },
  ]
}

resource "qovery_container" "my_container" {
  environment_id        = qovery_environment.my_environment.id
  registry_id           = var.container_registry_id
  name                  = "My container"
  image_name            = "nginx"
  tag                   = "1.29.8"
  cpu                   = 500
  memory                = 512
  min_running_instances = 1
  max_running_instances = 2
  healthchecks          = {}
  external_secrets = [
    {
      key                      = "CONTAINER_EXTERNAL_SECRET"
      reference                = "reference/to/secret"
      secret_manager_access_id = local.my_secret_manager_accesses["AWS Static Secret Manager configuration"].id
      description              = ""
    },
  ]
  external_secret_files = [
    {
      key                      = "CONTAINER_EXTERNAL_SECRET_MOUNTED"
      reference                = "reference/to/secret"
      secret_manager_access_id = local.my_secret_manager_accesses["AWS Static Secret Manager configuration"].id
      mount_path               = "/tmp"
      description              = ""
    },
  ]
}


