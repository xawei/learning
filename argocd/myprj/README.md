# ArgoCD App of Apps Pattern with Helm for EKS Multi-Cluster Bootstrap

Simple ArgoCD "App of Apps" pattern using **official Helm chart repositories** to bootstrap multiple EKS clusters.

## Architecture Overview

```
argocd/myprj/
├── base-components/             # ArgoCD Application definitions (flat structure)
│   ├── cert-manager.yaml       # Uses https://charts.jetstack.io
│   ├── ingress-nginx-dev.yaml  # Uses https://kubernetes.github.io/ingress-nginx
│   └── ingress-nginx-prod.yaml # Production-tuned ingress with autoscaling
├── clusters/                    # Root applications for each cluster
│   ├── dev/
│   │   ├── cluster-a/
│   │   │   └── root-cluster-a.yaml
│   │   ├── cluster-b/
│   │   │   └── root-cluster-b.yaml
│   │   └── kind-eksac-dev/
│   │       └── root-kind-eksac-dev.yaml
│   └── prod/
│       └── cluster-prod-1/
│           └── root-cluster-prod-1.yaml
└── scripts/
    └── setup-cluster.sh
```

## How It Works

1. **Flat Structure**: All ArgoCD Applications are directly in `base-components/` (no subdirectories)
2. **Root Applications**: Each cluster has a root app that points to `base-components/`
3. **Automatic Discovery**: ArgoCD automatically discovers and installs all YAML files in `base-components/`
4. **Official Helm Charts**: Each application uses upstream Helm charts from official repositories

## Usage

### Deploy to a Cluster

```bash
# Apply the root application - ArgoCD will discover and install all base components
kubectl apply -f clusters/dev/kind-eksac-dev/root-kind-eksac-dev.yaml
```

### Monitor Deployment

```bash
# Check all applications
kubectl get applications -n argocd

# Check specific applications created by App of Apps
kubectl get applications -n argocd | grep -E "(cert-manager|ingress-nginx)"
```

### Adding New Components

1. Create new application directly in `base-components/`:
```yaml
# base-components/prometheus.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
spec:
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 45.7.1
    helm:
      values: |
        # Helm values here
```

2. Commit and push - it will automatically be deployed to all clusters

## Components Included

### For All Clusters
- **cert-manager**: TLS certificate management from https://charts.jetstack.io
- **ingress-nginx-dev**: NGINX Ingress (dev config) from https://kubernetes.github.io/ingress-nginx
- **ingress-nginx-prod**: NGINX Ingress (prod config) with autoscaling and higher resources

## Key Features

- ✅ **Simple**: Flat structure, no complex directory hierarchy
- ✅ **Official Charts**: Uses upstream Helm repositories directly
- ✅ **Auto-Discovery**: ArgoCD automatically finds all applications
- ✅ **GitOps**: Version controlled, declarative configuration
- ✅ **Multi-Cluster**: Same structure works for dev/prod clusters

## Next Steps

1. Add more components to `base-components/` as needed
2. Deploy root applications to your clusters
3. Monitor applications via ArgoCD UI or kubectl 