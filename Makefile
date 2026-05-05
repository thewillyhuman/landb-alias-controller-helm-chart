SHELL=/bin/bash
.DEFAULT_GOAL=help

.PHONY: help lint template docs

##@ chart
##############################################################################
CHART_DIR ?= .

lint: ## lints helm chart.
	helm lint --strict $(CHART_DIR)

template: ## runs helm template.
	helm template test $(CHART_DIR)

docs: ## generate helm documentation.
	helm-docs $(CHART_DIR)

##@ helpers
##############################################################################
help: ## shows this help message.
	@awk 'BEGIN {FS = ":.*##"; printf "usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

