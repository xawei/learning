# ArgoCD App of Apps Pattern with Helm for EKS Multi-Cluster Bootstrap

Simple ArgoCD "App of Apps" pattern using **official Helm chart repositories** to bootstrap multiple EKS clusters.

## Architecture Overview

```
argocd/myprj/
├── base-components/             # ArgoCD Application definitions (flat structure)
│   ├── cert-manager.yaml       # TLS certificate management
│   └── ingress-nginx.yaml      # NGINX Ingress Controller
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

1. **Flat Structure**: All ArgoCD Applications are directly in `base-components/`
2. **Root Applications**: Each cluster has a root app that points to `base-components/`
3. **Automatic Discovery**: ArgoCD automatically installs all YAML files in `base-components/`
4. **Official Helm Charts**: Each application uses upstream Helm charts from official repositories

## Automatic GitOps Behavior

### ✅ **Fully Automatic - No Manual Intervention Required**

Our root applications are configured with enhanced sync policies for reliable automatic GitOps:

```yaml
syncPolicy:
  automated:
    prune: true        # ✅ Auto-remove apps when deleted from Git
    selfHeal: true     # ✅ Auto-sync when Git changes
    allowEmpty: false  # ✅ Prevent accidental deletion of all apps
  syncOptions:
    - PrunePropagationPolicy=foreground  # ✅ Proper cleanup order
    - PruneLast=true                     # ✅ Prune after sync
```

### 🔄 **What Happens Automatically**

| Action in Git | ArgoCD Response | Manual Effort |
|---------------|-----------------|---------------|
| Add new app YAML to `base-components/` | ✅ Automatically installs | **None** |
| Remove app YAML from `base-components/` | ✅ Automatically uninstalls | **None** |
| Modify app YAML in `base-components/` | ✅ Automatically updates | **None** |
| Change Helm values in app | ✅ Automatically syncs | **None** |

### 🧪 **Test the Automatic Behavior**

Try this to see automatic installation/removal in action:

```bash
# 1. Add a new application
cat > base-components/grafana.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: grafana
spec:
  source:
    repoURL: https://grafana.github.io/helm-charts
    chart: grafana
    targetRevision: 6.50.0
    helm:
      values: |
        adminPassword: admin
EOF

# 2. Commit and push
git add . && git commit -m "Add Grafana" && git push

# 3. Watch ArgoCD automatically create the grafana application
kubectl get applications -n argocd -w

# 4. Remove the application
rm base-components/grafana.yaml
git add . && git commit -m "Remove Grafana" && git push

# 5. Watch ArgoCD automatically remove it
kubectl get applications -n argocd -w
```

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

- **cert-manager**: TLS certificate management from https://charts.jetstack.io
- **ingress-nginx**: NGINX Ingress Controller from https://kubernetes.github.io/ingress-nginx

## Key Features

- ✅ **Zero Manual Intervention**: Add/remove apps by editing Git only
- ✅ **Ultra Simple**: Just 2 applications, no environment complexity
- ✅ **Official Charts**: Uses upstream Helm repositories directly
- ✅ **Auto-Discovery**: ArgoCD automatically finds all applications
- ✅ **GitOps**: True GitOps - Git is the single source of truth
- ✅ **Multi-Cluster**: Same components work for all clusters

## Next Steps

1. Add more components by dropping YAML files in `base-components/`
2. Deploy root applications to your clusters
3. Monitor applications via ArgoCD UI or kubectl 