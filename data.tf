# ---------------------------------------------------------------------------
# Lê os outputs do repo 2 (rede + EKS) a partir do state remoto no S3.
# Fornece: vpc_id, private_subnet_ids, node_security_group_id.
# ---------------------------------------------------------------------------
data "terraform_remote_state" "k8s" {
  backend = "s3"

  config = {
    bucket = "oficina-tfstate-909314263457"
    key    = "oficina-k8s-infra/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  vpc_id                 = data.terraform_remote_state.k8s.outputs.vpc_id
  private_subnet_ids     = data.terraform_remote_state.k8s.outputs.private_subnet_ids
  node_security_group_id = data.terraform_remote_state.k8s.outputs.node_security_group_id
}
