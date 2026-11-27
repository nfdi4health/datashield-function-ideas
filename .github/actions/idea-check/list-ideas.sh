#!/usr/bin/env bash
# The hub's issues for the "Exists?" check (idea-check.yml): open issues
# without the check's comment (<!-- idea-check: ... -->), oldest first, at
# most $MAX_ISSUES, leaving out pull requests, issues carrying a label of
# $SKIP_LABELS (comma or space separated) and issues the literature watch
# opened (a bot's issue with its <!-- literature-watch-method: --> marker:
# already checked; a person's hidden marker doesn't skip the check), and
# issues already routed (a bot's <!-- routed-to: --> comment; user,
# 2026-11-26: the check informs the routing, so after it there's nothing
# to decide).
#
# A daily limit (user, 2026-11-26): at most $DAILY_LIMIT checks in 24
# hours (the bots' check comments of that time; 0: no limit), so nobody can
# start hundreds; the rest waits, with a warning annotation. Requests are
# exempt: an issue carrying $PRIORITY_LABEL that a login of
# $PRIORITY_LOGINS set last (the issue's events) comes first, is checked
# even if it has a check already or a skip label, and doesn't count
# (its comment carries <!-- idea-check-priority -->).
#
# Writes {ideas: [{number, title, body, priority}], others: [{number,
# title}], waiting} to $1; `others` lists every issue of the hub, open or
# closed, for similar ones. Needs $HUB and $GH_TOKEN; R gets only the file.
set -euo pipefail
out="$1"
max="${MAX_ISSUES:-5}"
limit="${DAILY_LIMIT:-20}"
plabel="${PRIORITY_LABEL:-}"
skip_json="$(jq -cn --arg s "${SKIP_LABELS:-}" '$s | [splits("[ ,]+")] | map(select(length > 0))')"
logins_json="$(jq -cn --arg s "${PRIORITY_LOGINS:-}" '$s | [splits("[ ,]+")] | map(select(length > 0))')"
all="$(gh api --paginate "repos/$HUB/issues?state=all&per_page=100&sort=created&direction=asc" | jq -s 'add // [] | map(select(.pull_request == null))')"

# Requests: the label, set last by a listed login.
priority='[]'
if [ -n "$plabel" ] && [ "$(jq 'length' <<< "$logins_json")" -gt 0 ]; then
  labelled="$(jq -c --arg l "$plabel" '.[] | select(.state == "open" and ([.labels[].name] | index($l))) | {number, title, body: (.body // "")}' <<< "$all")"
  while IFS= read -r issue; do
    [ -n "$issue" ] || continue
    n="$(jq -r '.number' <<< "$issue")"
    if ! by="$(gh api --paginate "repos/$HUB/issues/$n/events?per_page=100" | jq -rs --arg l "$plabel" \
        '[add[]? | select(.event == "labeled" and .label.name == $l)] | last | .actor.login // ""')"; then
      echo "::warning::Could not read the events of #$n; checked next time."
      continue
    fi
    if jq -e --arg by "$by" 'index($by)' <<< "$logins_json" > /dev/null; then
      priority="$(jq -c --argjson i "$issue" '. + [$i + {priority: true}]' <<< "$priority")"
    else
      echo "#$n carries $plabel, set by ${by:-nobody known}, who isn't listed: an ordinary issue."
    fi
  done <<< "$labelled"
fi
priority="$(jq -c --argjson m "$max" '.[:$m]' <<< "$priority")"
n_priority="$(jq 'length' <<< "$priority")"

# The day's checks so far: the bots' check comments of the last 24 hours,
# without the requests'.
used=0
if [ "$limit" -gt 0 ]; then
  since="$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
  used="$(gh api --paginate "repos/$HUB/issues/comments?since=$since&per_page=100" | jq -s --arg since "$since" \
    '[add[]? | select(.user.type == "Bot" and .created_at >= $since and ((.body // "") | contains("<!-- idea-check:"))
       and ((.body // "") | contains("<!-- idea-check-priority -->") | not))] | length')"
fi
room=$((max - n_priority))
if [ "$limit" -gt 0 ]; then
  left=$((limit - used))
  [ "$left" -lt 0 ] && left=0
  [ "$left" -lt "$room" ] && room="$left"
fi

taken="$(jq -c '[.[].number]' <<< "$priority")"
candidates="$(jq -c --argjson skip "$skip_json" --argjson taken "$taken" '
  map(select(.state == "open")
      | select(([.number] - $taken | length) == 1)
      | select(([.labels[].name] - $skip | length) == (.labels | length))
      | select(.user.type == "Bot" and ((.body // "") | test("<!--\\s*literature-watch-method:")) | not))
  | .[] | {number, title, body: (.body // "")}' <<< "$all")"
ideas="$priority"
count=0
waiting=0
while IFS= read -r issue; do
  [ -n "$issue" ] || continue
  n="$(jq -r '.number' <<< "$issue")"
  if [ "$count" -ge "$room" ]; then
    # Past the run's or the day's room: only counted when the day's limit
    # holds it back (then the warning says how many wait).
    [ "$limit" -gt 0 ] && [ "$((limit - used))" -lt "$((max - n_priority))" ] || break
  fi
  if ! comments="$(gh api --paginate "repos/$HUB/issues/$n/comments?per_page=100" --jq '.[] | select(.user.type == "Bot") | .body')"; then
    echo "::warning::Could not read the comments of #$n; checked next time."
    continue
  fi
  if grep -q -e '<!-- idea-check:' -e '<!-- routed-to:' <<< "$comments"; then continue; fi
  if [ "$count" -ge "$room" ]; then
    waiting=$((waiting + 1))
    continue
  fi
  ideas="$(jq -c --argjson i "$issue" '. + [$i + {priority: false}]' <<< "$ideas")"
  count=$((count + 1))
done <<< "$candidates"
if [ "$waiting" -gt 0 ]; then
  echo "::warning::Daily limit of $limit idea checks reached ($used in the last 24 hours): $waiting issue(s) wait for a later run."
fi
jq -n --argjson ideas "$ideas" --argjson all "$all" --argjson w "$waiting" \
  '{ideas: $ideas, others: ($all | map({number, title})), waiting: $w}' > "$out"
echo "Issues to check: $((count + n_priority)) ($n_priority on request); $used checks in the last 24 hours."
