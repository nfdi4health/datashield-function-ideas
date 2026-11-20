#!/usr/bin/env bash
# The month a candidate selection is named after
# (runner-candidate-selection.yml: its file
# literature-watch/candidates/YYYY-MM.json, its branch and its pull
# request's title): the current one. A scheduled run in the first half of
# a month belongs to the month before: the runner schedules the selection
# late in the month (the 28th), and a run that gets its turn only after
# midnight is in the next month already when that day is the month's
# last. Named after its own month, the next regular run would get the
# same name. A run started by hand always gets the current month.
#
# $EVENT is the run's event (github.event_name); $NOW (YYYY-MM-DD) is for
# tests.
set -euo pipefail

now="${NOW:-$(date -u +%Y-%m-%d)}"
if [ "${EVENT:-}" = schedule ] && [ "$((10#$(date -u -d "$now" +%d)))" -lt 15 ]; then
  date -u -d "$(date -u -d "$now" +%Y-%m-01) -1 day" +%Y-%m
else
  date -u -d "$now" +%Y-%m
fi
