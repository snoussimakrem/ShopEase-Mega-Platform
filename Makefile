SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help check scaffold clean

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

check:  ## Hardware baseline — run once per phase, not per step
	@echo "disk_free_GB=$$(df -BG / | awk 'NR==2{gsub(\"G\",\"\",$$4);print $$4}')"
	@echo "ram_free_GB=$$(free -g  | awk '/^Mem/{print $$7}')"
	@echo "docker=$$(docker info --format '{{.ServerVersion}}' 2>/dev/null || echo DOWN)"

scaffold:  ## (Re)create directory tree — idempotent
	@mkdir -p docker/postgres/init docker/kafka docker/minio \
	  ingestion/sources cdc spark/batch spark/streaming \
	  delta/schema delta/optimize trino/catalogs trino/queries \
	  airflow/dags airflow/plugins quality/checks security/vault-policies \
	  observability/prometheus observability/grafana/dashboards \
	  fabric/notebooks fabric/pipelines \
	  tests/unit tests/integration tests/e2e docs/decisions scripts
	@find . -type d -empty -exec touch {}/.gitkeep \;

clean:  ## Remove python caches
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
