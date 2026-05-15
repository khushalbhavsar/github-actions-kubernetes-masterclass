# SkillPulse Argo CD GitOps

This folder contains the GitOps definitions for Argo CD:

- `project.yaml` creates the `skillpulse` Argo CD project.
- `skillpulse-application.yaml` syncs the application manifests in `k8s/`.
- `monitoring-application.yaml` syncs the Prometheus, Grafana, and Node Exporter manifests in `k8s/monitoring/`.

## Install Argo CD

```bash
make argocd-install
```

## Configure Your Repository URL

The Applications currently point at this repository's GitHub remote:

```text
https://github.com/LondheShubham153/github-actions-kubernetes-masterclass.git
```

If you fork the project, replace that value in both Application files with your fork URL.

## Apply GitOps Applications

```bash
make argocd-apps
```

## Access Argo CD

```bash
make argocd-port-forward
```

Then open:

```text
https://localhost:8081
```

Get the initial admin password:

```bash
make argocd-password
```

Argo CD will auto-sync changes committed to the configured repository. Rollbacks can be done from the Argo CD UI or CLI by selecting an older synced revision.
