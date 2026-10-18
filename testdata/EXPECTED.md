# Regression fixture

`fixture/` is a small repository with known problems planted in it. Use it to check the skill after changing `SKILL.md`, or after a new Terragrunt release.

It is not run in CI: it needs a model run, which costs money and varies between runs.

## How to run

```bash
cd testdata/fixture
claude -p "What breaks if we upgrade Terragrunt to the latest stable version? Find the affected places." \
  --plugin-dir ../../plugins/terragrunt-upgrade-impact \
  --allowedTools "Skill" "Read" "Grep" "Glob" "WebFetch" "Bash(gh api:*)" "Bash(grep:*)" "Bash(find:*)" "Bash(cat:*)" "Bash(ls:*)" "Bash(python3:*)" "Bash(jq:*)"
```

The fixture pins Terragrunt `0.67.0`. The expectations below were written for the range 0.67.0 to 1.1.6. A newer target can add entries but should not remove these.

## Must be reported as affected

| Where | What | Status |
|---|---|---|
| `Makefile:4`, `.github/workflows/ci.yml:4` | `apply-all`, `validate-all` | removed (0.84.0) |
| `Makefile:2`, `Makefile:4`, `scripts/deploy.sh:3` | `--terragrunt-*` flags | removed (0.85.0) |
| `Makefile:6` | `hclfmt` | removed (0.90.0) |
| `.github/workflows/ci.yml:5` | `graph-dependencies` | removed (0.90.0) |
| `live/dev/db/terragrunt.hcl:12` | `dependency.vpc.inputs` | removed (0.91.0) |
| `terragrunt.hcl:9-11` | `retryable_errors`, `retry_max_attempts`, `retry_sleep_interval_sec` | removed (0.93.0) |
| `live/dev/app/terragrunt.hcl:4` | `skip = true` | removed (0.93.0) |
| `live/prod/mixed/` | `terragrunt.hcl` and `terragrunt.stack.hcl` in one directory | error (1.0.0) |
| `Makefile:2`, `scripts/deploy.sh:3` | `run-all` | deprecated, not removed |
| `Makefile:4` | `TERRAGRUNT_LOG_LEVEL` | deprecated |
| `live/dev/app/terragrunt.hcl:1` | `include {` without a label | deprecated |
| `live/dev/db/terragrunt.hcl:4,9` | two `dependency "vpc"` blocks | strict control, duplicate labels |

## Must NOT be reported as affected

| Where | Why |
|---|---|
| `skip_outputs` in `live/dev/db/terragrunt.hcl` | different name from `skip` |
| `skip_credentials_validation`, `skip_bucket_versioning` in `terragrunt.hcl` | S3 backend keys, not `skip` |
| `README.md:1`, `scripts/deploy.sh:2` (`plan-all`) | prose and a comment, never executed; "mention only" is fine |
| `exclude { ... }` in `live/prod/app/terragrunt.hcl` | the replacement for `skip`, already correct |

## Known traps this fixture tests

- `hclfmt` and `graph-dependencies` are deprecated in v0.78.0 and removed in v0.90.0. Reporting them as "deprecated, still works" is wrong. The docs' active strict-controls page still lists them.
- `run-all` is only deprecated in this range. Reporting it as removed is also wrong.
