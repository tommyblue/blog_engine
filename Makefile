.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

deploy: ## Deploy on https://github.com/tommyblue/tommyblue.github.io
	./script/deploy.sh

dev: ## Run hugo dev server locally
	./script/local_run.sh

new: ## Create a new post. Requires TITLE="<permalink>" argument
	hugo new content/post/$(TITLE).md
