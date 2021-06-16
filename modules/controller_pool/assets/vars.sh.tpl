#!/bin/sh
# This template script maps Terraform template variables 
# to shell variables. By defining all template variables in this script,
# other scripts can use plain shell and not worry about Terraform interpolation.
kube_token="${kube_token}"
metal_network_cidr="${metal_network_cidr}"
metal_auth_token="${metal_auth_token}"
metal_project_id="${metal_project_id}"
kube_version="${kube_version}"
secrets_encryption="${secrets_encryption}"
configure_ingress="${configure_ingress}"
count="${count}"
count_gpu="${count_gpu}"
storage="${storage}"
skip_workloads="${skip_workloads}"
control_plane_node_count="${control_plane_node_count}"
primary_node_ip="${primary_node_ip}"
controller="${controller}"
node_addr="${node_addr}"
ssh_private_key_path="${ssh_private_key_path}"

# workloads is a multi-line json blob
workloads=$(cat <<'END_HEREDOC'
${workloads}
END_HEREDOC
)
