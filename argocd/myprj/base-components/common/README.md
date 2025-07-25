# Common Base Components

This directory contains ArgoCD application definitions for components that should be deployed to **all clusters** regardless of environment.

## Components

### cert-manager
- **Purpose**: Automatic TLS certificate management and renewal
- **Source**: Official Jetstack Helm chart from https://charts.jetstack.io
- **Chart Version**: v1.13.3
- **Namespace**: `cert-manager`
- **Features**:
  - Automatic CRD installation
  - Let's Encrypt integration ready
  - Configurable Prometheus metrics
  - Resource requests/limits configured

## Usage

Common components are automatically included in all cluster configurations through their respective `kustomization.yaml` files.

To customize a common component for a specific cluster, add patches in the cluster's `cluster-specific-patches.yaml` file.

Example patch for cert-manager Helm values:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
spec:
  source:
    helm:
      values: |
        prometheus:
          enabled: true
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

## Helm Chart Sources

All applications in this directory use official Helm chart repositories:
- **cert-manager**: https://charts.jetstack.io
- Each application points directly to the upstream chart repository
- Helm values are used for configuration instead of raw YAML manifests 