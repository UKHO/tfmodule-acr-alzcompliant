# Terraform Coding Guidelines

These guidelines are designed to ensure consistency, maintainability, and security across all Terraform codebases. Adhering to these standards will help streamline collaboration and improve the quality of our infrastructure as code.

## Code Style & Structure
- Always use the latest features where possible.
- Use consistent indentation (2 spaces) for readability.
- Group related resources logically (e.g., networking, compute, storage).
- Keep resource blocks short and well-organised—avoid large, complex blocks.
 
## Module Usage
- create reusable modules over repeating code.
- Use standard module structure: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`.
- For shared modules, source them from the approved GitHub org (https://github.com/UKHO).
 
## Variables & Outputs
- All variables must have descriptions and types defined.
- Avoid hardcoding values—use variables or locals.
- Outputs should be meaningful and named consistently for reuse in parent modules.
 
##  Security & Secrets
- Conform to Azure Landing Zone policies and best practices.
- Never hardcode secrets or credentials.
- Use environment variables or secure backends like Azure Key Vault, AWS Secrets Manager, or Vault.
- Sensitive outputs should be marked with `sensitive = true`.
- Ensure all infrastructure as code is scanned by Snyk for vulnerabilities.
 
## Validation & Testing
- Include `terraform validate` and `terraform fmt -check` in CI.
- Use `pre-commit` hooks to enforce formatting and checks before merge.
- Run `terraform plan` with a named workspace in all pipelines.
 
## Naming & Tags
- Use consistent resource naming with cloud type, product, environment and resource type (`m-test-dev-acr`).
- All resources must have tags for `SERVICE`, `ENVIRONMENT`, `SERVICE_OWNER`, `RESPONSIBLE_TEAM`, `CALLOUT_TEAM` and `COST_CENTRE`. This should be set via variables or locals.
 
## Comments & Docs
- Add comments for complex resources or unusual patterns.
- Include a README in each module with usage examples and input/output documentation.
- Use terraform-docs to generate and maintain documentation.