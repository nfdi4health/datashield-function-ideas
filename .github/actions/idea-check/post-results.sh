#!/usr/bin/env bash
# Posts the "Exists?" check's results ($1, written by R/check_ideas.R:
# [{number, body, label}]) to the hub ($HUB, $GH_TOKEN): one comment per
# issue and its label, if any (GitHub creates a label on first use). An
# issue that got its comment in the meantime (a parallel run) is skipped,
# unless it was checked on request ($IDEAS_FILE from list-ideas.sh marks
# it `priority`): then the new check is posted too, its comment carries
# <!-- idea-check-priority --> (it doesn't count towards the daily limit)
# and $PRIORITY_LABEL is removed.
set -euo pipefail
results="$1"
[ -s "$results" ] || { echo "No results."; exit 0; }
ideas="${IDEAS_FILE:-}"
n_results="$(jq 'length' "$results")"
for i in $(seq 0 $((n_results - 1))); do
  n="$(jq -r ".[$i].number" "$results")"
  label="$(jq -r ".[$i].label // \"\"" "$results")"
  priority=false
  if [ -n "$ideas" ] && [ -s "$ideas" ]; then
    priority="$(jq --argjson n "$n" '[.ideas[] | select(.number == $n and .priority == true)] | length > 0' "$ideas")"
  fi
  if [ "$priority" != true ] && gh api --paginate "repos/$HUB/issues/$n/comments?per_page=100" --jq '.[].body' | grep -q '<!-- idea-check:'; then
    echo "#$n already has its check; skipped."
    continue
  fi
  { jq -r ".[$i].body" "$results"; if [ "$priority" = true ]; then printf '%s\n' '<!-- idea-check-priority -->'; fi; } |
    gh api -X POST "repos/$HUB/issues/$n/comments" -F body=@- > /dev/null
  if [ -n "$label" ]; then
    gh api -X POST "repos/$HUB/issues/$n/labels" -f "labels[]=$label" > /dev/null
  fi
  if [ "$priority" = true ] && [ -n "${PRIORITY_LABEL:-}" ]; then
    gh api -X DELETE "repos/$HUB/issues/$n/labels/$(jq -rn --arg l "$PRIORITY_LABEL" '$l | @uri')" > /dev/null 2>&1 || true
  fi
  echo "#$n: commented${label:+, label $label}$([ "$priority" = true ] && echo ", on request")."
done
