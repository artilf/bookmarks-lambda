SHELL = /usr/bin/env bash -xeuo pipefail
stack_name=bookmarks-lambda

isort:
	pipenv run isort -rc \
		src/ \
		tests/

lint:
	pipenv run flake8 \
		src/ \
		tests/

black:
	pipenv run black \
		src/ \
		tests/

format: isort black lint

package:
	rm -rf dist
	mkdir dist
	pipenv run aws cloudformation package \
		--template-file sam.yml \
		--s3-bucket $$ARTIFACTS_S3_BUCKET \
		--output-template-file dist/template.yml

deploy: package
	pipenv run aws cloudformation deploy \
		--template-file dist/template.yml \
		--stack-name $(stack_name) \
		--capabilities CAPABILITY_IAM \
		--role-arn $(AWS_CFN_DEPLOY_ROLE_ARN) \
		--no-fail-on-empty-changeset

test-unit:
	@for test_dir in $$(find tests/unit -maxdepth 1 -type d); do \
		handler=$$(basename $$test_dir); \
		if [[ $$handler =~ unit|__pycache__ ]]; then continue; fi; \
		PYTHONPATH=submodules/bookmarks-layer/src/layer/python:src/$$handler \
		pipenv run pytest $$test_dir --cov-config=setup.cfg --cov=src/$$handler; \
	done
