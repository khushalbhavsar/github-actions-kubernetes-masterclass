# SkillPulse Production Kubernetes Add-ons

This folder contains raw-manifest production add-ons for EKS:

- NGINX Ingress resource
- HorizontalPodAutoscalers for frontend and backend

Production order:

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/10-mysql.yaml
kubectl apply -f k8s/20-backend.yaml
kubectl apply -f k8s/30-frontend.yaml
kubectl apply -f k8s/security
kubectl apply -f k8s/production
```

Argo CD will automatically sync these manifests from Git for continuous deployment.

