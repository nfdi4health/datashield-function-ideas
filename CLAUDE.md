# Project: datashield-function-ideas

The hub of missing DataSHIELD functions (created 2026-11-13 by the user).
Issues are the ideas; this repository holds only thin callers of
`nfdi4health/datashield-workflows` (`route-idea.yml`, `methods-scan.yml`),
their settings in `config/`, and later the researcher's data files
(`scans/YYYY-MM.yml`). Logic, prompts and tests live in
datashield-workflows; the design is in its `dev-notes/issue-agents.md`
("A central hub") and `dev-notes/v1-planning.md` (6b).

- **Branches:** `main` only (user's choice); Claude Code sessions work on
  `agent-suggest/<type>/<topic>` and open pull requests into `main`.
- **Public:** nothing about studies, variables, results or data; the issue
  forms say so. The analysis starter's gap links carry only the missing
  method.
- **Routing:** labels in `.github/workflows/route-idea.yml` (`label =
  owner/repo`); only `allowed-logins` may route; the bots' App must be
  installed on the target.
- **The researcher** runs in the private runner
  `FlorianSchw/datashield-agent-runner` on the user's Claude subscription,
  in one queue with the implementer (decided 2026-11-13); the caller here
  (`methods-scan.yml` → `methods-scan-start.yml`) only starts it, for
  `allowed-logins`, with the bots' App. Its pilot report comes back as
  `scans/pilot-YYYY-MM.md` in a pull request. This repository holds no
  Claude or NCBI secret any more.
  Phases: pilot (built), vocabulary round, backfill, monthly candidate PR
  with three boxes per candidate (designed, not built).
