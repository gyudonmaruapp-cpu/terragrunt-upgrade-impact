---
name: terragrunt-upgrade-impact
description: Use when analyzing a Terragrunt version upgrade (0.x to 1.x, or 1.x to a newer minor) for breaking changes, deprecations and migration requirements in terragrunt.hcl, CI, scripts and Makefiles, before changing anything.
---

# Terragrunt Upgrade Impact

## Overview

Analyze the impact of upgrading Terragrunt itself before making changes. Identify removed and deprecated commands, flags, environment variables and HCL, and the behavior changes that leave nothing to grep for.

This skill holds no knowledge base. Every fact comes from the primary sources below, read at run time, because Terragrunt's removals, strict controls and flag names change with every release.

**Announce at start:** "I'm using the terragrunt-upgrade-impact skill to assess this upgrade."

## Rules

- Read-only. Never run `apply`, `destroy`, or anything that changes state or the repository. Proposing fixes is fine; editing only when the user asks.
- Never report "no impact" for something you could not check. List what failed or was skipped under "Not checked".
- Do not cite a version, flag, command or control you did not read in a source during this run.
- Put the source URL next to each finding so the user can verify it.

## Primary sources

| Need | Source |
|---|---|
| Latest stable version, every release's breaking changes | `gh api repos/gruntwork-io/terragrunt/releases --paginate` (field `body`); fallback https://github.com/gruntwork-io/terragrunt/releases |
| Old to new commands, flags, env vars | https://docs.terragrunt.com/migrate/cli-redesign |
| Strict controls still opt-in (warn today) | https://docs.terragrunt.com/reference/strict-controls/active |
| Strict controls already enforced | https://docs.terragrunt.com/reference/strict-controls/completed |
| How to enable strict controls | https://docs.terragrunt.com/reference/strict-controls |
| What 1.x promises, and what it excludes | https://docs.terragrunt.com/process/1-0-guarantees/ |
| Per-change migration guides | links inside each release's breaking-changes text |

**The release notes are authoritative; the docs pages can lag.** In testing, the active-controls page still listed `hclfmt` and `graph-dependencies` while the release notes said they had been removed. Decide "removed" or "only deprecated" from the release notes of the version in question. Use the docs pages for replacement names and control names.

## Process

### Step 1: Identify current state

```bash
terragrunt --version
tofu --version    # or: terraform version
```

Also look for pins: `.terragrunt-version`, `.tool-versions`, `mise.toml`, CI workflow files, Dockerfiles, devcontainer config. Many repositories pin nothing: ask the user, but do not stop there. While waiting, trace every old name found in the repository through all stable releases (Step 3) and report the version in which each was deprecated or removed. The user can then compare that with what they run. If pipelines and developers use different versions, report each; do not pick one.

### Step 2: Identify target version

Latest stable (not a `-rc`), a version the user names, or the next minor. Terragrunt's own version and the OpenTofu/Terraform version it drives are separate; note both.

### Step 3: Research breaking changes

Fetch all releases once, drop pre-releases, keep tags after current up to target, and filter locally; do not open releases one by one. Most releases have no breaking text, so filtering is cheap even for a large jump.

The heading varies (emoji prefix, `#` depth, sometimes only "deprecated" or "no longer" in the text). Search the whole body of each release for `breaking`, `removed`, `no longer`, `deprecated`, not only the breaking-changes section: real items sit outside it (a deprecation announced in a feature note; a bug fix the maintainers call "technically a breaking change in behavior"). Expect noise: `no longer` mostly appears in bug-fix lines such as "no longer panics". Keep an item only when something a user already has (a command, flag, env var, HCL, output, default, path) stops working or changes. Read the migration guides the notes link to.

Classify each change from its own release's wording:

- **Removed**: errors at the target version.
- **Deprecated**: works, warns, will break later.
- **Behavior change**: still runs, result differs.

**Trace each name through the whole range and use the latest statement.** One name is often deprecated in one release and removed several releases later, and several names are deprecated together in one note. Do this per name, mechanically, not by reading excerpts. Save all releases to a file once, then for every old name found in the repository list the stable releases that mention it:

```bash
gh api repos/gruntwork-io/terragrunt/releases --paginate > "${TMPDIR:-/tmp}/tg-releases.json"
jq -r --arg n "hclfmt" '.[] | select(.prerelease==false and ((.body // "") | contains($n))) | .tag_name' "${TMPDIR:-/tmp}/tg-releases.json"
```

Keep only tags in range, open the surrounding lines of each, in version order, and take the last statement as the status. This is how a name that looks "only deprecated" in its first note turns out to be removed many releases later. The docs pages are a cross-check, not a substitute: they can still list a removed name as an opt-in strict control.

**Never write "deprecated, still works" or "removed" for a name you have not traced this way.** If you did not, report it as "status unverified" next to the item itself, not only in a footnote. A wrong "still works" is worse than an honest "unknown".

### Step 4: Analyze impact

| Category | Impact | Example of the kind of thing |
|---|---|---|
| **Removed** command, flag, env var, HCL attribute or block | HIGH | the repo uses something gone at the target |
| **Behavior change** | MEDIUM | defaults, output, paths, discovery, provisioning |
| **Deprecated** | LOW now, HIGH later | warns today |

#### Code scan

Take the old names from the sources, not from memory. Search the whole repository, not only `*.hcl`: `terragrunt.hcl`, `*.hcl`, `terragrunt.stack.hcl`, shell scripts, `Makefile`, Dockerfiles, CI files (`.github/`, `.gitlab-ci.yml`, ...), pre-commit config, and docs that contain runnable commands. Record file, line, matched text, replacement.

- Read each hit in context. A match in a comment, changelog or README prose is not executed: list it under "Checked, not affected" as "mention only" (low priority if someone may copy the command).
- Anchor HCL attribute searches to the start of the line. `skip =` is a different thing from `skip_outputs`, `skip_credentials_validation`, `skip_bucket_versioning`. Apply the same care to every short name.

#### Structure check (grep misses these)

Check whichever of these the sources you read say matter for this range: a directory holding both `terragrunt.hcl` and `terragrunt.stack.hcl`; `include` blocks without a label; two `dependency` blocks with the same label or `config_path`; a root `terragrunt.hcl` found through `find_in_parent_folders()`; values read from a dependency's inputs rather than its outputs.

### Step 5: Terragrunt-specific checks

Where Terragrunt upgrades tend to bite. These are categories to look at, not facts: confirm each against the release notes for your range.

| Area | What to look at |
|---|---|
| **CI and scripts, not only HCL** | Old command names, `--terragrunt-` flags and `TERRAGRUNT_` env vars live in Makefiles, workflows and wrapper scripts as often as in HCL |
| **OpenTofu/Terraform compatibility** | Which engine versions the target is tested against (stated in the release notes). A Terragrunt upgrade can force an engine upgrade, or the reverse |
| **Backend and state setup** | Whether `remote_state` / `generate` / backend creation behavior changed (for example automatic provisioning versus an explicit bootstrap flag) |
| **Dependencies** | `dependency` outputs, `mock_outputs`, anything read from other units. Use `terragrunt find` with the graph filters in https://docs.terragrunt.com/features/filter to list the units downstream of a shared one |
| **Shared files** | `root.hcl` / root `terragrunt.hcl`, `include`, `common.hcl`: one change reaches every unit that includes it |
| **Working directory and cache** | Where files are read and written during a run (`.terragrunt-cache`, hidden files, generated files) |
| **Hooks and external tools** | `before_hook` / `after_hook` calling bundled tools (for example tflint) that may no longer ship in the binary |
| **Paths and platforms** | Path-returning HCL functions and Windows versus Linux behavior |
| **Experiments** | Anything under `--experiment` has no stability guarantee in 1.x: list every use |
| **Wrappers around Terragrunt** | Atlantis, GitHub Actions, Terraform Cloud, Renovate and similar: check whether they pin or pass flags |

### Step 6: Generate report

```markdown
## Terragrunt Upgrade Impact: <current> -> <target>

Sources read: <URLs, fetch date>
Not checked: <anything that failed or was out of scope>

### Summary

| Component | Current | Target | Risk Level |
|---|---|---|---|
| terragrunt | 0.67.0 | 1.1.6 | HIGH |
| tofu/terraform | x.y.z | (compat range from notes) | |

### Affected

#### 1. [Change name]
- **Type:** Removed | Deprecated | Behavior change | Status unverified
- **Removed/Deprecated in:** <version, from release notes; the releases you traced>
- **Found:** `Makefile:4` `terragrunt apply-all ...`
- **Fix:** `terragrunt run --all apply`
- **Source:** <URL>

### Checked, not affected
<each change you searched for and found nothing, one line each; "mention only" hits go here>

### Behavior changes (verify by running)
<change, how it was described in the notes, how to observe it>

### Deprecations (future concern)

| Item | Deprecated in | Replacement | Source |
|---|---|---|---|

### Recommended Upgrade Path

1. Pin the current version everywhere (CI, devcontainer, `.terragrunt-version`/mise).
2. Fix HIGH items (removed) first, then MEDIUM, then deprecations.
3. Dry run in a lower environment with strict mode (Step 7).
4. Bump the pin in one lower environment, run `terragrunt run --all plan`, review the plan for differences you did not expect.
5. Roll the pin forward environment by environment.

### Risk Assessment

| Factor | Assessment |
|---|---|
| Removed items | X |
| Behavior changes needing a run | Y |
| Files | Z |
| Estimated effort | Low / Medium / High |
| Recommended timing | Now / After testing / Wait |
```

"Checked, not affected" is required. It is what lets the reader trust the "Affected" list.

### Step 7: Dry run with strict controls

Strict controls turn deprecation warnings into errors, so remaining usage fails before the real upgrade. Read https://docs.terragrunt.com/reference/strict-controls for the exact forms at run time. As seen there: `--strict-mode` / `TG_STRICT_MODE=true` for all controls; `--strict-control <name>` / `TG_STRICT_CONTROL=<name>` for specific ones (comma-separated in the environment variable); categories such as `deprecated-commands`.

Tell the user to run their normal non-mutating commands (for example `terragrunt run --all plan`) with strict controls enabled, in a lower environment or CI, and send you the output. The docs recommend this for lower environments. Do not run it against production yourself.

## Common upgrade patterns

Read https://docs.terragrunt.com/process/1-0-guarantees/ at run time; it was the following when this skill was written.

### 0.x to 1.x

Many removals happened across the 0.x releases on the road to 1.0 (the release notes of that period describe them as steps toward 1.0). The further back the current version, the more entries in the report. Check every release in the range, not only 1.0.

### 1.x minor upgrades

1.x promises no breaking changes in minor releases for commands, flags and valid HCL. Excluded from that promise: experimental features, log wording, `list` and catalog UI output, bug fixes that change buggy behavior, third-party integration changes, performance changes, Go version support. So still read the notes for those, and for new deprecations.

### Patch upgrades

Bug fixes. Generally safe, still skim the notes.

### Deprecations in 1.x

The guarantees page says functionality deprecated in 1.x will likely be removed in 2.x. Fix deprecation warnings now even though they do not break anything today.

## Safety checklist

Before recommending the upgrade:

- [ ] Every release in the range was read, or the gap is listed under "Not checked"
- [ ] Removed items are found and have a fix
- [ ] Behavior changes are listed with how to observe them
- [ ] Current version is pinned in every pipeline and for developers
- [ ] Strict-control dry run is clean, or remaining errors are explained
- [ ] The OpenTofu/Terraform version works with the target
- [ ] Backend/`remote_state` changes (if any) are understood, state backed up if the notes touch them
- [ ] Rollback is defined: pin back to the previous version, and check the notes for changes the previous version cannot read
- [ ] Lower environment planned before production
- [ ] User informed of risks

## Out of scope

- OpenTofu/Terraform and provider upgrades (use a provider-upgrade skill). Mention them only where a Terragrunt release says the supported engine range changed.
- Applying fixes. Propose them.

## Credits

Structure follows `provider-upgrade-analysis` from https://github.com/lgbarn/devops-skills (MIT). The primary-source retrieval, release classification, structure checks and Terragrunt-specific sections are additions for Terragrunt.
