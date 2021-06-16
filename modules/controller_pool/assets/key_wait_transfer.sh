#!/bin/bash

source vars.sh || ( echo vars.sh not found ; exit 1)

SSH_ARGS="-i $ssh_private_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

/usr/bin/ssh $SSH_ARGS root@$node_addr "while true; do if ! type kubeadm > /dev/null; then sleep 20; else break; fi; done"
sleep 360
CERT_KEY=$(echo `/usr/bin/ssh $SSH_ARGS -q root@$controller "kubeadm init phase upload-certs --upload-certs | grep -v upload-certs"` | sed -e 's|(stdin)= ||g')
CA_CERT_HASH=$(echo `/usr/bin/ssh $SSH_ARGS -q root@$controller "openssl x509 -in /etc/kubernetes/pki/ca.crt -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256"` | sed -e 's|(stdin)= ||g')
/usr/bin/ssh $SSH_ARGS -q root@$node_addr "mkdir -p /etc/kubernetes/pki/etcd" ; \
/usr/bin/ssh $SSH_ARGS root@$controller "mkdir -p /etc/kubernetes/pki/etcd; while true; do if [ ! -f /etc/kubernetes/pki/etcd/ca.key ]; then sleep 20; else break; fi; done" ;
for cert in {sa,{front-proxy-,etcd/,}ca}.{key,crt} 
    /usr/bin/scp -3  -q root@$controller:/etc/kubernetes/pki/$cert root@$node_addr:/etc/kubernetes/pki/$cert
done
echo "waiting..."
sleep 360
/usr/bin/ssh $SSH_ARGS root@$node_addr "kubeadm join $controller:6443 --token $kube_token --control-plane --discovery-token-ca-cert-hash sha256:$CA_CERT_HASH" && \
echo "Control plane node configured: $node_addr"