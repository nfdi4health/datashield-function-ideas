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

**Nothing comes from datashield-workflows at run time** (user,
2026-11-19: "better drift and duplicates than relying on small parts"):
the Claude call and config helpers (`R/functions/shared/`, trimmed to the
subscription path through Claude Code), `config/claude.yml`'s `default` and
`model_rules`, the actions `dispatch-runner` and `propose-branch`, and the
branch clean-up are copies of datashield-workflows' of 2026-11-19, each
file saying so. They will drift: when a fix lands there (above all in
`call_claude_code_tool()`, `claude_code_isolation_args()`,
`credential_variables()`, `plain_comment_text()`), check whether it is
needed here, and the other way round; keep `model_rules` current when
models come out. In the runner, the workspace root is this repository's
`main` (config, prompts) and `.hub` the copy at the commit the workflow
runs (`hub-files`, for R and the scripts; also the defaults
`read_config_yaml()` merges the root's files over).

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
- **Idea check limits** (user, 2026-11-26): at most `daily-limit` (20)
  checks in 24 hours, counted from the bots' check comments, so nobody can
  start hundreds; the rest waits for a later run (a warning annotation;
  the runner also runs the check once a day). The label `bot-check`, set
  by a login of `priority-logins` (the runner's caller: FlorianSchw; who set
  it is read from the issue's events), asks for a check now: first in the
  run, also on a checked or skipped issue, not counted
  (`<!-- idea-check-priority -->`), label removed afterwards. Spending and
  steering aren't a worry for the user; the limit is only against floods.
  RepositoryOverview reports the runner's Claude runs per day.
- **The researcher** runs in the private runner
  `FlorianSchw/datashield-agent-runner` on the user's Claude subscription,
  in one queue with the implementer (decided 2026-11-13);
  `literature-watch.yml` here only starts it (for FlorianSchw, with the
  bots' App and `dispatch-runner`); the runner runs
  `runner-literature-watch.yml` nightly and on that start.
  This repository holds no Claude or NCBI secret.
  **Settings (user, 2026-11-16):** 11 fields (`fields`, checked on the
  PubMed website), `target_per_month` 25 and `years_back` 10 for the first
  round (2026-11-18), `papers_per_run` 1500; the user raises the target or
  years by hand for the next round (no automatic stages). The literature
  watch (`runner-literature-watch.yml`) reads, sorts names into the
  vocabulary and writes the report; nothing else.
- **Requests weigh more than candidates** (user, 2026-11-26): a person's
  hub issue is actual demand, the literature watch's candidates inferred
  demand. The idea check gives requests the same basis (literature
  numbers, by exact name with the marker or by Claude's match without it;
  a research brief for methods DataSHIELD lacks); requests don't go into
  the candidate list.
- **Candidate selection** (built 2026-11-20, `runner-candidate-selection.yml`,
  started here with `candidate-selection.yml`, monthly in the runner; user:
  apart from the reading): ranking over all papers read, "Exists?" down the
  ranking, research, the candidate PR. The PR's top line says what the
  ranking rests on: usable papers read in total, per publication year in a folded table
  (user, 2026-11-20: not the current round's progress). Briefs are kept in
  `research.json` on the data branch and reused for
  `candidates$research_max_age_days` (183) while the verdict and the
  catalogue functions found stay the same; after that Claude updates the
  earlier brief ("what's new"); "not now" gaps keep theirs until then.
