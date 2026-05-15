# SkillPulse Monitoring

This folder adds a lightweight observability stack for the local Kubernetes environment:

- Prometheus for scraping Kubernetes, container, node, and SkillPulse API metrics
- Node Exporter for node-level CPU, memory, disk, and network metrics
- Grafana with a pre-provisioned Prometheus datasource and SkillPulse dashboard
- Alertmanager with example routing for Slack/email-style notifications

## Apply

```bash
make monitoring
```

With the provided kind port mappings:

- Prometheus: http://localhost:9090
- Alertmanager: http://localhost:9093
- Grafana: http://localhost:3000

If the cluster was created before these port mappings existed, recreate it with `make down && make up`.

Grafana demo credentials:

```text
admin / admin123
```

## What Gets Scraped

- `/metrics` from the backend pod through the `prometheus.io/*` annotations
- kubelet cAdvisor metrics for Kubernetes pod/container CPU and memory
- Node Exporter on each kind node
- Prometheus itself

## Alerts

Prometheus loads alert rules from `25-prometheus-rules.yaml` and routes alerts to Alertmanager.

Before production use, replace the example receiver in `50-alertmanager.yaml` with your real Slack webhook, email SMTP settings, or incident-management webhook.

Falco runtime security lives in `../runtime-security` because it needs privileged node access and should be reviewed separately from the metrics stack.
