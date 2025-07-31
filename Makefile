# SPDX-FileCopyrightText: (C) 2025 pierventre
# SPDX-License-Identifier: MIT

.DEFAULT_GOAL := help
.PHONY: help

##### Variables #####

# Defining the shell, users and groups
SHELL       := bash -e -o pipefail
CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)

# Project variables
PROJECT_NAME      := llamaindex-examples
DB_CONTAINER_NAME := $(PROJECT_NAME)-ollama
OLLAMA_VERSION  := 0.10.1

# Code versions, tags, and so on
VERSION       := $(shell cat VERSION)
VERSION_MAJOR := $(shell cut -c 1 VERSION)
GIT_COMMIT    ?= $(shell git rev-parse HEAD)

# Docker variables
DOCKER_NETWORKING_FLAGS = -p 11434:11434

# Runtime variables
OPENAI_API_KEY=foobar

#### Python venv Target ####
VENV_DIR := venv_llamai

$(VENV_DIR): requirements.txt ## Create Python venv
	python3 -m venv $@ ;\
  set +u; . ./$@/bin/activate; set -u ;\
  python -m pip install --upgrade pip ;\
  python -m pip install -r requirements.txt

data: ## Download data files
	mkdir -p data;\
  wget https://raw.githubusercontent.com/run-llama/llama_index/main/docs/docs/examples/data/paul_graham/paul_graham_essay.txt -O data/paul_graham_essay.txt;\
  echo -e "\nAuthor: Paul Graham" >> data/paul_graham_essay.txt

ollama-start: ## Start the ollam process. See: ollam-stop
	if [ -z "`docker ps -aq -f name=^$(DB_CONTAINER_NAME)`" ]; then \
		docker run --name $(DB_CONTAINER_NAME) --rm $(DOCKER_NETWORKING_FLAGS) --env-file .env -v ollama:/root/.ollama -d ollama/ollama:$(OLLAMA_VERSION); \
	fi

ollama-stop: ## Stop the ollama process. See: ollama-start
	@if [ -n "`docker ps -aq -f name=^$(DB_CONTAINER_NAME)`" ]; then \
		docker container kill $(DB_CONTAINER_NAME); \
	fi

ollama-logs: ## Show the logs of the ollama process
	@if [ -n "`docker ps -aq -f name=^$(DB_CONTAINER_NAME)`" ]; then \
		docker logs $(DB_CONTAINER_NAME); \
	else \
		echo "No container running with name $(DB_CONTAINER_NAME)"; \
	fi

ollama-status: ## Show the status of the ollama process
	@if [ -n "`docker ps -aq -f name=^$(DB_CONTAINER_NAME)`" ]; then \
		docker ps -f name=^$(DB_CONTAINER_NAME); \
	else \
		echo "No container running with name $(DB_CONTAINER_NAME)"; \
	fi

# https://pypi.org/project/reuse/
license: $(VENV_DIR) ## Check licensing with the reuse tool
	set +u; . ./$</bin/activate; set -u ;\
  reuse --version ;\
  reuse --root . lint

run-examples: data $(VENV_DIR) ## run examples - run all Python examples
	set +u; . ./$(VENV_DIR)/bin/activate; set -u ;\
	for f in *.py; do \
		echo "Running $$f"; \
		python "$$f"; \
	done

clean: ## clean-all - delete generated files and venv
	rm -rf "$(VENV_DIR)"
	
help: ## Print help for each target
	@echo llamaindex-examples make targets
	@echo
	@grep '^[[:alnum:]_-]*:.* ##' $(MAKEFILE_LIST) \
    | sort | awk 'BEGIN {FS=":.* ## "}; {printf "%-25s %s\n", $$1, $$2};'
