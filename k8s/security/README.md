# SkillPulse Kubernetes Security

This folder contains security hardening overlays for the raw Kubernetes manifests:

- NetworkPolicies for frontend, backend, and MySQL traffic
- Default deny ingress/egress posture for the `skillpulse` namespace

Apply after the base app is running:

```bash
kubectl apply -f k8s/security
```

Notes:

- NetworkPolicies require a CNI that enforces them. EKS with Calico or Cilium will enforce these rules; default kind networking may not.
- The base manifests already define ServiceAccounts and non-root container security contexts.

