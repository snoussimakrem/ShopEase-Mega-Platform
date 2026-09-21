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
# Append to ~/shopease-mega-platform/Makefile
COMPOSE := docker compose --env-file .env -f docker/compose.yaml

.PHONY: up down logs psql ps

up:  ## Start the stack
	$(COMPOSE) up -d

down:  ## Stop the stack (data volume survives)
	$(COMPOSE) down

logs:  ## Tail logs (all services or: make logs S=postgres)
	$(COMPOSE) logs -f $(S)

ps:  ## Show running services
	$(COMPOSE) ps

psql:  ## Open psql in the running postgres container
	$(COMPOSE) exec postgres psql -U $${POSTGRES_USER} -d $${POSTGRES_DB}

.PHONY: mc-ls

mc-ls:  ## List MinIO buckets
	@docker compose --env-file .env -f docker/compose.yaml exec minio \
	  sh -c 'mc alias set local http://localhost:9000 $$MINIO_ROOT_USER $$MINIO_ROOT_PASSWORD >/dev/null && mc ls local'
.PHONY: kafka-topics kafka-describe

kafka-topics:  ## List Kafka topics
	@docker compose --env-file .env -f docker/compose.yaml exec kafka \
	  /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

kafka-describe:  ## Describe all topics (partitions, replicas)
	@docker compose --env-file .env -f docker/compose.yaml exec kafka \
	  /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe

.PHONY: spark-ui spark-submit

spark-ui:  ## Print Spark UI URLs
	@echo "Master UI:   http://localhost:18080"
	@echo "Worker-1 UI: http://localhost:18081"
	@echo "Worker-2 UI: http://localhost:18082"

spark-submit:  ## Run a job: make spark-submit J=hello.py
	@docker compose --env-file .env -f docker/compose.yaml exec spark-master \
	  /opt/spark/bin/spark-submit \
	    --master spark://spark-master:7077 \
	    --conf spark.executor.memory=512m \
	    --conf spark.executor.cores=1 \
	    /opt/spark-jobs/$(J)