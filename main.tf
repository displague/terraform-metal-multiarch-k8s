provider "metal" {
  auth_token = var.auth_token
}

resource "metal_project" "new_project" {
  count = var.metal_create_project ? 1 : 0
  name  = var.metal_project_name
  bgp_config {
    deployment_type = "local"
    md5             = "C179c28c41a85b"
    # todo: use random provider or reuse kube token (making kubetoken available in metadata)?
    asn = 65000
  }
}

resource "metal_vlan" "vlan" {
  facility   = var.facility != "" ? var.facility : null
  metro      = var.metro != "" ? var.metro : null
  project_id = var.metal_create_project ? metal_project.new_project[0].id : var.project_id
}