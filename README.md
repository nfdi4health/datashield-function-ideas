# DataSHIELD function ideas

The place for **functions DataSHIELD doesn't have yet**: statistical
methods analysts need, helpers that would make analyses easier, and who is
working on what. It replaces lists kept in spreadsheets: ideas live as
issues next to where the work happens, can be voted on, and are passed on
to the package that will implement them.

## Share an idea

[Open an issue](../../issues/new/choose) and pick:

- **Analysis method:** a statistical method you'd need in DataSHIELD, e.g.
  a clustering method or an imputation approach;
- **Other idea:** utilities, helpers, documentation.

This repository is public. Describe the method only: **no study names,
variable names, research questions, results or data.**

Already there? Give the issue a 👍 and add how you'd use it: that shows
the demand.

## Where ideas come from

- **People**, through the issue forms.
- **The DataSHIELD analysis starter** (`datashield-analysis-suggest`): when
  a step of an analysis plan needs a function no package offers, its pull
  request offers a prefilled link to an issue here. It carries only what
  is missing, never the plan; the analyst opens it under their own account.
- **The literature watch**: a nightly read of the published literature
  (PubMed, PMC) for the methods health research uses. Once a month it
  proposes the most used methods DataSHIELD lacks in a pull request, each
  with a short brief, for a maintainer to decide: open an issue, not now,
  or don't suggest again.

## What happens to an idea

1. It is collected here: a 👍 counts the demand, and comments help shape
   the idea until it has a home.
2. A maintainer routes it to the repository of the package that fits (a
   label per package): the issue is copied there, with a link back.
   Discussion and work happen there from then on; this issue stays open as
   the record of demand, and a 👍 here still counts.

## How it works

The workflows come from
[nfdi4health/datashield-workflows](https://github.com/nfdi4health/datashield-workflows)
(`route-idea.yml`, `literature-watch.yml`); this repository holds the
callers and their settings (`config/`). The literature watch runs nightly
in a private runner repository on the maintainer's Claude subscription:
it reads a random sample of open-access research articles per field and
month, keeps what it finds on the `data` branch (IDs, titles and the
methods named, never the papers' text), with its report
(`literature-watch/reports/overview.md`) and progress there too. The
monthly candidates come as a pull request
(`literature-watch/candidates/YYYY-MM.json`); `literature-candidates.yml`
keeps it red until every candidate has exactly one box ticked and, on
merge, opens the issues and records the decisions. Its fields and pace are
in `config/literature-watch.yml`.
