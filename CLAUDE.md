# Project: datashield-function-ideas

The hub of missing DataSHIELD functions (created 2026-11-13 by the user).
Issues are the ideas; this repository holds only thin callers of
`nfdi4health/datashield-workflows` (`route-idea.yml`, `literature-watch.yml`),
their settings in `config/`, and the literature watch's report
(`literature-watch/reports/overview.md`, by pull request); its data lives
on the `data` branch (pushed by the runs, no pull request). Logic, prompts and tests live in
datashield-workflows; the design is in its `dev-notes/issue-agents.md`
("A central hub") and `dev-notes/v1-planning.md` (6b).

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
  classic token with only `public_repo`); only `allowed-logins` may
  route.
- **The researcher** runs in the private runner
  `FlorianSchw/datashield-agent-runner` on the user's Claude subscription,
  in one queue with the implementer (decided 2026-11-13); the caller here
  (`literature-watch.yml` → `literature-watch-start.yml`) only starts it, for
  `allowed-logins`, with the bots' App; the runner also runs it nightly.
  This repository holds no Claude or NCBI secret.
  **Settings (user, 2026-11-16):** 11 fields (`fields`, checked on the
  PubMed website), `target_per_month` 25 and `years_back` 5 for the first
  round, `papers_per_run` 1500; the user raises the target or years by
  hand for the next round (no automatic stages). Pilot done; backfill and
  monthly runs built; classification, "Exists?" and the candidate PR with
  three boxes per candidate designed, not built.
