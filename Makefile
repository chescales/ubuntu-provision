.PHONY: list

# Default task to get a list of tasks when `make' is run without args.
# <https://stackoverflow.com/questions/4219255>
list:
	@echo Available tasks:
	@echo ----------------
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
	@echo

list-tags:
	@ansible-playbook ubuntu-local.yml --list-tags | grep "TASK TAGS:"

provision:
	ansible-playbook ubuntu-local.yml --skip-tags "timezone,locale"
	#ansible-playbook ubuntu-local.yml --tags all

provision-tags:
ifndef TAGS
	$(error TAGS is undefined. Call this command with 'make provision-tags TAGS=tag1[,tag2...]')
endif
	ansible-playbook ubuntu-local.yml --tags "$(TAGS)"

provision-interactive: list-tags
	@echo "\nSelect which tags to run from the previous list. Usage: 'tag1[,tag2...]' or type 'all' to run everything."
	@read -p 'Tags: ' tags; \
	echo "ansible-playbook ubuntu-local.yml --tags \"$$tags\""; \
	ansible-playbook ubuntu-local.yml --tags "$$tags"

