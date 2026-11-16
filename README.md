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
- **The researcher** (in preparation): a monthly scan of the published
  literature (PubMed, PMC) for the methods health research uses, proposing
  candidates DataSHIELD lacks in a pull request, for a person to decide.

## What happens to an idea

1. It is collected here, with votes and discussion.
2. A maintainer routes it to the repository of the package that fits (a
   label per package): the issue is copied there, with a link back. Work
   happens there; this issue stays open as the record of demand.

## How it works

The workflows come from
[nfdi4health/datashield-workflows](https://github.com/nfdi4health/datashield-workflows)
(`route-idea.yml`, `methods-scan.yml`); this repository holds the callers,
their settings (`config/`) and the researcher's reports (`scans/`, by
pull request). The researcher itself runs in a private runner repository on
the maintainer's Claude subscription; this repository only starts it.
