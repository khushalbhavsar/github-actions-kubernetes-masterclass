CLUSTER  ?= skillpulse
NAMESPACE ?= skillpulse
ARGOCD_NAMESPACE ?= argocd
BACKEND_IMAGE  ?= trainwithshubham/skillpulse-backend:latest
FRONTEND_IMAGE ?= trainwithshubham/skillpulse-frontend:latest

.PHONY: up enterprise-up down build load apply status logs mysql restart monitoring security production falco argocd-install argocd-apps argocd-password argocd-port-forward terraform-validate

up: ## One-shot: build images, create cluster, load images, apply manifests
	$(MAKE) build
	kind create cluster --config k8s/kind-config.yaml --name $(CLUSTER)
	$(MAKE) load
	$(MAKE) apply
	@echo
	@echo "  SkillPulse is live at http://localhost:8888"
	@echo

enterprise-up: ## Local enterprise stack: app, security, monitoring, Falco, Argo CD
	$(MAKE) up
	$(MAKE) security
	$(MAKE) monitoring
	$(MAKE) production
	$(MAKE) falco
	$(MAKE) argocd-install
	$(MAKE) argocd-apps

build: ## Build backend + frontend images for the host's architecture
	docker build -t $(BACKEND_IMAGE)  ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

load: ## Push built images into the kind node
	kind load docker-image $(BACKEND_IMAGE)  --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

apply: ## Apply manifests and wait for rollouts
	kubectl apply -f k8s/00-namespace.yaml \
	              -f k8s/10-mysql.yaml \
	              -f k8s/20-backend.yaml \
	              -f k8s/30-frontend.yaml
	kubectl rollout status statefulset/mysql    -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend   -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend  -n $(NAMESPACE) --timeout=60s

down: ## Delete the cluster
	kind delete cluster --name $(CLUSTER)

status: ## Quick health snapshot
	@kubectl get pods,svc,endpoints -n $(NAMESPACE)

logs: ## Tail all three workloads at once
	@kubectl logs -n $(NAMESPACE) -l 'app in (mysql,backend,frontend)' --all-containers --tail=50 -f --max-log-requests=10

mysql: ## Open a mysql shell into the StatefulSet pod
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- mysql -uskillpulse -pskillpulse123 skillpulse

restart: ## Rebuild + reload images, roll backend + frontend
	$(MAKE) build
	$(MAKE) load
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)
	kubectl rollout status  deployment/backend  -n $(NAMESPACE) --timeout=120s
	kubectl rollout status  deployment/frontend -n $(NAMESPACE) --timeout=60s

monitoring: ## Install Prometheus, Grafana, and Node Exporter
	kubectl apply -f k8s/monitoring
	kubectl rollout status deployment/prometheus -n monitoring --timeout=120s
	kubectl rollout status daemonset/node-exporter -n monitoring --timeout=120s
	kubectl rollout status deployment/grafana -n monitoring --timeout=120s
	kubectl rollout status deployment/alertmanager -n monitoring --timeout=120s
	@echo
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Alertmanager: http://localhost:9093"
	@echo "  Grafana:    http://localhost:3000  (admin / admin123)"
	@echo

security: ## Apply NetworkPolicies and Kubernetes security overlays
	kubectl apply -f k8s/security

production: ## Apply raw production add-ons: Ingress and HPA
	kubectl apply -f k8s/production

falco: ## Install Falco runtime security monitoring
	kubectl apply -f k8s/runtime-security
	kubectl rollout status daemonset/falco -n falco --timeout=180s

argocd-install: ## Install Argo CD into the cluster
	kubectl create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl rollout status deployment/argocd-server -n $(ARGOCD_NAMESPACE) --timeout=180s

argocd-apps: ## Apply Argo CD project and Applications
	kubectl apply -f k8s/argocd/project.yaml
	kubectl apply -f k8s/argocd/skillpulse-application.yaml
	kubectl apply -f k8s/argocd/monitoring-application.yaml
	kubectl apply -f k8s/argocd/security-application.yaml
	kubectl apply -f k8s/argocd/production-application.yaml
	kubectl apply -f k8s/argocd/runtime-security-application.yaml

argocd-password: ## Print initial Argo CD admin password
	kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
	@echo

argocd-port-forward: ## Forward Argo CD UI to https://localhost:8081
	kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8081:443

terraform-validate: ## Format-check and validate Terraform
	cd terraform/aws && terraform fmt -check -recursive && terraform init -backend=false && terraform validate
