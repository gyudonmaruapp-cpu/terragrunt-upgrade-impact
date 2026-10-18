plan:
	terragrunt run-all plan --terragrunt-non-interactive
apply-dev:
	TERRAGRUNT_LOG_LEVEL=debug terragrunt apply-all --terragrunt-working-dir live/dev
fmt:
	terragrunt hclfmt
