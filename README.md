# terragrunt-upgrade-impact

A Claude Code skill that assesses what a Terragrunt version upgrade will break in your repository, before you upgrade.

It holds no knowledge base. It reads Terragrunt's release notes and migration docs at run time, so it keeps up with new releases without being updated.

## What it does

- Finds the current and target Terragrunt version, and reads every release in between.
- Classifies each change as removed, deprecated or behavior change, using the release notes as the authority (the docs pages can lag).
- Searches the whole repository, not only `*.hcl`: Makefiles, CI files, scripts, Dockerfiles.
- Checks structure that grep cannot see (for example a unit directory holding both `terragrunt.hcl` and `terragrunt.stack.hcl`).
- Reports what is affected, what was checked and is not affected, and what could not be checked.
- Read-only: it never runs `apply` or changes your files.

## Install

```bash
claude plugin marketplace add gyudonmaruapp-cpu/terragrunt-upgrade-impact
claude plugin install terragrunt-upgrade-impact@terragrunt-upgrade-impact
```

Then ask, for example: "What breaks if we upgrade Terragrunt from 0.67 to the latest?" The skill is `/terragrunt-upgrade-impact:terragrunt-upgrade-impact`.

## Limits

- The judgement is made by the model reading the sources, so results can vary between runs. The report lists the sources read and what was not checked so you can verify.
- It does not cover OpenTofu/Terraform or provider upgrades.
- Needs `gh` (authenticated) or network access to read GitHub releases and docs.terragrunt.com.

## Credits

The structure follows `provider-upgrade-analysis` from [lgbarn/devops-skills](https://github.com/lgbarn/devops-skills) (MIT).

## License

MIT

## Development

- `scripts/check-urls.sh` checks that the pages the skill reads still exist. CI runs it weekly, together with `claude plugin validate`.
- `testdata/` holds a fixture with known problems and the expected result. See `testdata/EXPECTED.md`. Run it by hand after changing the skill.
