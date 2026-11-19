# Project: datashield-function-ideas

The hub of missing DataSHIELD functions (created 2026-11-13 by the user).
Issues are the ideas. Since 2026-11-19 this repository also holds the
whole pipeline that serves them (user: the hub is the one place, not a
reusable workflow for other repositories): the workflows
(`.github/workflows/`; `runner-*.yml` are called by the private runner
`FlorianSchw/datashield-agent-runner`, the others run here), their scripts
(`R/` entry scripts, one function per file in `R/functions/literature/`,
`.github/actions/`), prompts (`prompts/`), settings (`config/`), tests
(`tests/`: `Rscript tests/testthat.R` with `LANG=C.UTF-8`, the shell tests,
`node --test tests/node/*.test.mjs`) and CI (`ci.yml`: tests, actionlint,
shellcheck, zizmor). The data lives on the `data` branch (pushed by the
runs, no pull request), with the report
(`literature-watch/reports/overview.md`). The design is in
`dev-notes/hub-design.md`.

**From datashield-workflows** (`nfdi4health/datashield-workflows@main`):
the shared R functions (`R/functions/shared/`: `claude_client()`,
`call_claude_tool()`, `read_config_yaml()`, `plain_comment_text()`, …) and
the defaults of `config/claude.yml` (the `default` profile, `model_rules`),
checked out into `.shared-workflows` by the workflows and CI (locally a
clone next to this one; `tests/testthat/helper-load.R`); the actions
`dispatch-runner` and `propose-branch`; `cleanup-suggestion-branch.yml`.
This repository's `config/claude.yml` has only its own profiles, merged
over those defaults. In the runner, the workspace root is this
repository's `main` (config, prompts) and `.hub` the copy at the commit
the workflow runs (`hub-files`, for R and the scripts).

- **Branches:** `main` only (user's choice); Claude Code sessions work on
  `agent-suggest/<type>/<topic>` and open pull requests into `main`.
  `cleanup-branches.yml` deletes `bot-suggest/*` and `agent-suggest/*`
  branches once their pull request is closed (2026-11-16); the literature
  watch's `data` branch is never touched.
- **Public:** nothing about studies, variables, results or data; the issue
  forms say so. The analysis starter's gap links carry only the missing
  method.
- **Routing:** `config/routes.yml` (`label: owner/repo`, the package's
  name as the label, its client repository as the target; user,
  2026-11-17); `route-idea.yml` creates the labels when that file changes
  and opens the copies in the maintainer's name with `ROUTE_TOKEN` (a
  classic token with only `public_repo`); only FlorianSchw may route
  (`LOGINS` / the action's `allowed-logins` in the workflows).
- **The researcher** runs in the private runner
  `FlorianSchw/datashield-agent-runner` on the user's Claude subscription,
  in one queue with the implementer (decided 2026-11-13);
  `literature-watch.yml` here only starts it (for FlorianSchw, with the
  bots' App and datashield-workflows' `dispatch-runner`); the runner runs
  `runner-literature-watch.yml` nightly and on that start.
  This repository holds no Claude or NCBI secret.
  **Settings (user, 2026-11-16):** 11 fields (`fields`, checked on the
  PubMed website), `target_per_month` 25 and `years_back` 10 for the first
  round (2026-11-18), `papers_per_run` 1500; the user raises the target or
  years by hand for the next round (no automatic stages). Reading,
  vocabulary, report, "Exists?" and the candidate PR are built.
- **Next (decided 2026-11-19, `dev-notes/hub-design.md`):** candidate
  selection as its own workflow (monthly and by hand), the literature
  watch's `candidates` input removed, research reused for 6 months.
