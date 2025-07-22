# Learning External DNS

## Local KIND cluster
create a local KIND cluster with 1 master node and 1 worker node for testing
```
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
kubeadmConfigPatches:
- |
  kind: ClusterConfiguration
  kubernetesVersion: v1.33.0
EOF
```