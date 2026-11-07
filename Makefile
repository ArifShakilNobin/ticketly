SHELL := /bin/bash
JAVA_HOME ?= /usr/lib/jvm/java-17-openjdk-amd64
export JAVA_HOME

.PHONY: help build test infra up down dev stop logs smoke clean fmt-check

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

build: ## Build every module (jars land in services/*/target)
	mvn -B -DskipTests install

test: ## Run all unit tests
	mvn -B test

infra: ## Start infrastructure only (postgres, mongo, redis, kafka) and wait
	docker compose up -d --wait

up: build ## Build jars, then start the whole platform in Docker
	docker compose --profile apps up -d --build --wait

down: ## Stop and remove the Docker platform (keeps data volumes)
	docker compose --profile apps down

clean: ## Stop Docker, remove volumes and delete build output
	docker compose --profile apps down -v --remove-orphans
	rm -rf .run
	mvn -B -q clean

dev: infra ## Infrastructure in Docker + all 7 services on the host (fast iteration)
	bash scripts/dev-up.sh

stop: ## Stop the host-run services started by `make dev`
	bash scripts/dev-down.sh

logs: ## Tail logs of the Docker platform (add a service name to filter)
	@docker compose logs -f --tail=100 $(svc)

smoke: ## End-to-end API smoke test through the gateway
	bash scripts/smoke-test.sh
