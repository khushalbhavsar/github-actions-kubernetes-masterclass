# Falco Runtime Security

Falco watches Kubernetes nodes and container runtime activity for suspicious behavior such as:

- Shell access inside containers
- Privilege escalation attempts
- Unexpected file writes
- Suspicious process execution

Apply:

```bash
kubectl apply -f k8s/runtime-security
```

Watch alerts:

```bash
kubectl logs -n falco -l app=falco -f
```

Falco needs privileged node access by design. Keep it isolated in its own namespace and restrict who can modify these manifests.

