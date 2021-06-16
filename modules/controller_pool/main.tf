data "cloudinit_config" "cloudinit" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/assets/vars.sh.tpl", {
      kube_token               = var.kube_token
      metal_network_cidr       = var.kubernetes_lb_block
      metal_auth_token         = var.auth_token
      metal_project_id         = var.project_id
      kube_version             = var.kubernetes_version
      secrets_encryption       = var.secrets_encryption ? "yes" : "no"
      configure_ingress        = var.configure_ingress ? "yes" : "no"
      count                    = var.count_x86
      count_gpu                = var.count_gpu
      storage                  = var.storage
      skip_workloads           = var.skip_workloads ? "yes" : "no"
      workloads                = jsonencode(var.workloads)
      control_plane_node_count = var.control_plane_node_count
      primary_node_ip          = metal_device.k8s_primary.network.0.address
    })
    filename = "/root/vars.sh"
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/assets/controller-primary.sh")
    filename     = "controller-primary.sh"
  }
  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/assets/controller-standby.sh")
    filename     = "controller-standby.sh"
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/assets/key_wait_transfer.sh")
    filename     = "key_wait_transfer.sh"
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/assets/vars.sh.tpl", {
      kube_token               = var.kube_token
      metal_network_cidr       = var.kubernetes_lb_block
      metal_auth_token         = var.auth_token
      metal_project_id         = var.project_id
      kube_version             = var.kubernetes_version
      secrets_encryption       = var.secrets_encryption ? "yes" : "no"
      configure_ingress        = var.configure_ingress ? "yes" : "no"
      count                    = var.count_x86
      count_gpu                = var.count_gpu
      storage                  = var.storage
      skip_workloads           = var.skip_workloads ? "yes" : "no"
      workloads                = jsonencode(var.workloads)
      control_plane_node_count = var.control_plane_node_count
      primary_node_ip          = metal_device.k8s_primary.network.0.address
    })

  }

  part {
    content_type = "text/x-shellscript"
    content      = <<EOT
    #!/usr/bin/env bash
    if [[ "$HOSTNAME"=="*primary*" ]]; then
      . controller-primary.sh
    else
      . controller-standby.sh
      . key_wait_transfer.sh
    fi
    EOT
    filename     = "controller.sh"
  }
}

resource "metal_device" "k8s_primary" {
  hostname         = "${var.cluster_name}-controller-primary"
  operating_system = "ubuntu_18_04"
  plan             = var.plan_primary
  facilities       = var.facility != "" ? [var.facility] : null
  metro            = var.metro != "" ? var.metro : null
  user_data        = data.cloudinit_config.cloudinit.rendered
  tags             = ["kubernetes", "controller-${var.cluster_name}"]

  billing_cycle = "hourly"
  project_id    = var.project_id
}

resource "metal_device" "k8s_controller_standby" {
  count      = var.control_plane_node_count
  depends_on = [metal_device.k8s_primary]

  hostname         = format("${var.cluster_name}-controller-standby-%02d", count.index)
  operating_system = "ubuntu_18_04"
  plan             = var.plan_primary
  facilities       = var.facility != "" ? [var.facility] : null
  metro            = var.metro != "" ? var.metro : null
  user_data        = data.cloudinit_config.cloudinit.rendered
  tags             = ["kubernetes", "controller-${var.cluster_name}"]
  billing_cycle    = "hourly"
  project_id       = var.project_id
}

resource "metal_ip_attachment" "kubernetes_lb_block" {
  device_id     = metal_device.k8s_primary.id
  cidr_notation = var.kubernetes_lb_block
}
