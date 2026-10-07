SHELL := /usr/bin/env bash
COMPOSE := docker compose

.DEFAULT_GOAL := help
.PHONY: help up down nuke ps logs admin token mirror sync

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

up: ## Start gitea + runner
	$(COMPOSE) up -d

down: ## Stop containers (keep volumes)
	$(COMPOSE) down

nuke: ## Stop containers and delete volumes (fresh instance)
	$(COMPOSE) down -v

ps: ## Show container status
	$(COMPOSE) ps

logs: ## Tail logs
	$(COMPOSE) logs -f --tail=100

admin: ## Create the Gitea admin user
	./scripts/create-admin.sh

token: ## Fetch a runner registration token and store it in .env
	./scripts/get-runner-token.sh

mirror: ## Create a pull mirror: make mirror URL=https://github.com/owner/repo.git
	@test -n "$(URL)" || { echo "usage: make mirror URL=https://github.com/owner/repo.git"; exit 1; }
	./scripts/create-mirror.sh "$(URL)"

sync: ## Force a mirror sync: make sync REPO=owner/repo
	@test -n "$(REPO)" || { echo "usage: make sync REPO=owner/repo"; exit 1; }
	./scripts/sync.sh "$(REPO)"
