.PHONY: lint template docs

lint:
	helm lint --strict .

template:
	helm template test .

docs:
	helm-docs
