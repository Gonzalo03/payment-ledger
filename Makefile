# Load local overrides if present (.env is git-ignored). A clean clone has no
# .env, so every variable below also has a default that matches compose.yaml.
-include .env

DATABASE_URL        ?= postgres://ledger:ledger@localhost:5432/ledger?sslmode=disable
GOOSE_DRIVER        ?= postgres
GOOSE_DBSTRING      ?= $(DATABASE_URL)
GOOSE_MIGRATION_DIR ?= migrations

# Make these visible to every command run by a recipe (go test, goose...).
export DATABASE_URL GOOSE_DRIVER GOOSE_DBSTRING GOOSE_MIGRATION_DIR

GOOSE := go tool goose

# Test shortcuts:
#   make test v=1                     -> verbose
#   make test run=TestDatabase/ping   -> only matching tests (implies verbose)
#   make test TESTFLAGS="-count=3"    -> any other go test flag
TESTFLAGS ?=
GOTESTFLAGS := $(if $(or $(v),$(run)),-v) $(if $(run),-run '$(run)') $(TESTFLAGS)

.DEFAULT_GOAL := help
.PHONY: help up down reset migrate-up migrate-down migrate-status migrate-create \
        fmt fmt-check vet lint test-unit test build run-api

help: ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-16s %s\n", $$1, $$2}'

## --- Local environment ---

up: ## Start Postgres and wait until it is healthy
	docker compose up -d --build --wait

down: ## Stop containers (data is kept)
	docker compose down

reset: ## Stop containers AND delete the database volume
	docker compose down -v

## --- Migrations ---

migrate-up: ## Apply all pending migrations
	$(GOOSE) up

migrate-down: ## Roll back the last migration
	$(GOOSE) down

migrate-status: ## Show applied/pending migrations
	$(GOOSE) status

migrate-create: ## Create a migration: make migrate-create name=add_entries
	@test -n "$(name)" || (echo "usage: make migrate-create name=<snake_case_name>" && exit 1)
	$(GOOSE) -s create $(name) sql

## --- Quality ---

fmt: ## Format all Go code
	gofmt -w cmd internal

fmt-check: ## Fail if any Go file is not gofmt-formatted
	@out="$$(gofmt -l cmd internal)"; \
	if [ -n "$$out" ]; then echo "not formatted:"; echo "$$out"; exit 1; fi

vet: ## Run go vet (including integration-tagged files)
	go vet ./...
	go vet -tags integration ./...

lint: fmt-check vet ## fmt-check + vet

## --- Tests ---

test-unit: ## Unit tests only (no database needed)
	go test -race $(GOTESTFLAGS) ./...

test: migrate-up ## All tests, including integration. Options: v=1 run=<pattern>
	go test -race -count=1 -tags integration $(GOTESTFLAGS) ./...

## --- Build & run ---

build: ## Build all binaries into bin/
	go build -o bin/ ./cmd/...

run-api: ## Run the API locally
	go run ./cmd/api
