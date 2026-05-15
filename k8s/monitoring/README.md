# SkillPulse Monitoring

This folder adds a lightweight observability stack for the local Kubernetes environment:

- Prometheus for scraping Kubernetes, container, node, and SkillPulse API metrics
- Node Exporter for node-level CPU, memory, disk, and network metrics
- Grafana with a pre-provisioned Prometheus datasource and SkillPulse dashboard

## Apply

```bash
make monitoring
```

With the provided kind port mappings:

- Prometheus: http://localhost:9090
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
