# ArgoCD App of Apps Pattern with Helm for EKS Multi-Cluster Bootstrap

Simple ArgoCD "App of Apps" pattern using **official Helm chart repositories** to bootstrap multiple EKS clusters.

## Architecture Overview

```
argocd/myprj/
├── base-components/             # ArgoCD Application definitions using Helm charts
│   ├── common/                  # Apps for all clusters
│   │   ├── cert-manager/
│   │   │   └── application.yaml # Uses https://charts.jetstack.io
│   │   └── README.md
│   ├── dev/                     # Dev-specific apps
│   │   ├── ingress-nginx/
│   │   │   └── application.yaml # Uses https://kubernetes.github.io/ingress-nginx
│   │   └── external-secrets/
│   │       └── application.yaml # Uses https://charts.external-secrets.io
│   └── prod/                    # Prod-specific apps
│       └── ingress-nginx/
│           └── application.yaml # Production-tuned ingress
├── clusters/                    # Root applications for each cluster
│   ├── dev/
│   │   ├── cluster-a/
│   │   │   └── root-cluster-a.yaml
│   │   └── cluster-b/
│   │       └── root-cluster-b.yaml
│   └── prod/
│       └── cluster-prod-1/
│           └── root-cluster-prod-1.yaml
└── scripts/
    └── setup-cluster.sh
```

## How It Works

1. **Base Components**: ArgoCD Applications in `base-components/` that use official Helm charts
2. **Root Applications**: Each cluster has a root app that points to `base-components/`
3. **Automatic Discovery**: ArgoCD automatically installs all applications found in `base-components/`

## Usage

### Deploy to a Cluster

```bash
# Apply the root application - ArgoCD will discover and install all base components
kubectl apply -f clusters/dev/cluster-a/root-cluster-a.yaml
```

### Monitor Deployment

```bash
# Check all applications
kubectl get applications -n argocd

# Sync if needed
argocd app sync root-cluster-a
```

### Adding New Components

1. Create new application in `base-components/`:
```yaml
# base-components/common/prometheus/application.yaml
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

2. It will be automatically deployed to all clusters using the same root application

## Components Included

### Common (All Clusters)
- **cert-manager**: TLS certificate management from https://charts.jetstack.io

### Development
- **ingress-nginx**: NGINX Ingress (dev config) from https://kubernetes.github.io/ingress-nginx
- **external-secrets**: Secret management from https://charts.external-secrets.io

### Production  
- **ingress-nginx**: NGINX Ingress (prod config) with autoscaling

## Next Steps

1. Replace `YOUR_USERNAME/YOUR_REPO` with your Git repository URL
2. Add more components to `base-components/` as needed
3. Deploy root applications to your clusters 