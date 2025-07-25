#!/bin/bash

# ArgoCD App of Apps Cluster Setup Script
# Usage: ./setup-cluster.sh <environment> <cluster-name> <git-repo-url>

set -e

ENVIRONMENT=$1
CLUSTER_NAME=$2
GIT_REPO_URL=$3

if [ $# -ne 3 ]; then
    echo "Usage: $0 <environment> <cluster-name> <git-repo-url>"
    echo "Example: $0 dev cluster-c https://github.com/myorg/myrepo"
    exit 1
fi

CLUSTER_DIR="clusters/${ENVIRONMENT}/${CLUSTER_NAME}"
ROOT_APP_FILE="${CLUSTER_DIR}/root-${CLUSTER_NAME}.yaml"

echo "🚀 Setting up ArgoCD App of Apps for ${CLUSTER_NAME} in ${ENVIRONMENT} environment"

# Create cluster directory if it doesn't exist
mkdir -p "${CLUSTER_DIR}"

# Create root application
cat > "${ROOT_APP_FILE}" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-${CLUSTER_NAME}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${GIT_REPO_URL}
    targetRevision: HEAD
    path: argocd/myprj/clusters/${ENVIRONMENT}/${CLUSTER_NAME}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

# Create kustomization.yaml
cat > "${CLUSTER_DIR}/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  # Common base components for all clusters
  - ../../../base-components/common/cert-manager/application.yaml
  
  # Environment-specific components
EOF

if [ "${ENVIRONMENT}" == "dev" ]; then
    cat >> "${CLUSTER_DIR}/kustomization.yaml" << EOF
  - ../../../base-components/dev/ingress-nginx/application.yaml
  - ../../../base-components/dev/external-secrets/application.yaml
EOF
elif [ "${ENVIRONMENT}" == "prod" ]; then
    cat >> "${CLUSTER_DIR}/kustomization.yaml" << EOF
  - ../../../base-components/prod/ingress-nginx/application.yaml
EOF
fi

cat >> "${CLUSTER_DIR}/kustomization.yaml" << EOF

patchesStrategicMerge:
  # Cluster-specific patches
  - cluster-specific-patches.yaml

namePrefix: ${CLUSTER_NAME}-
EOF

# Create cluster-specific patches
cat > "${CLUSTER_DIR}/cluster-specific-patches.yaml" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ingress-nginx-${ENVIRONMENT}
spec:
  source:
    helm:
      values: |
        controller:
          service:
            annotations:
              service.beta.kubernetes.io/aws-load-balancer-name: "${CLUSTER_NAME}-ingress-nlb"
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
spec:
  source:
    helm:
      values: |
        installCRDs: true
        global:
          leaderElection:
            namespace: cert-manager
        prometheus:
          enabled: false
        # Add ${CLUSTER_NAME}-specific cert-manager config here
EOF

echo "✅ Created cluster configuration files:"
echo "   - ${ROOT_APP_FILE}"
echo "   - ${CLUSTER_DIR}/kustomization.yaml"  
echo "   - ${CLUSTER_DIR}/cluster-specific-patches.yaml"
echo ""
echo "📋 Next steps:"
echo "1. Review and customize the generated files"
echo "2. Commit and push to your Git repository"
echo "3. Apply the root application to your cluster:"
echo "   kubectl apply -f ${ROOT_APP_FILE}"
echo "4. Monitor the deployment:"
echo "   kubectl get applications -n argocd"
echo "   argocd app sync root-${CLUSTER_NAME}"
echo ""
echo "🎉 Cluster ${CLUSTER_NAME} is ready for GitOps with ArgoCD!" 