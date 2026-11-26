#!/usr/bin/env bash
# Tests for .github/actions/idea-check/ (the hub's "Exists?" check), with a
# stand-in for `gh` that records every call. Needs jq.
#   bash tests/shell/test-idea-check.sh
# Prints one line per test and exits non-zero if any failed.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIR="$ROOT/.github/actions/idea-check"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
BIN="$WORK/bin"
mkdir -p "$BIN" "$WORK/comments" "$WORK/events"
command -v jq > /dev/null || { echo "FAIL jq is needed"; exit 1; }

passed=0
failed=0
check() {  # check <name> <0 for passed>
  if [ "$2" = 0 ]; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1"; failed=$((failed + 1)); fi
}

# gh: the issue list from $WORK/issues.json; an issue's comment bodies from
# $WORK/comments/<n> (missing: none; "FAIL": the call fails); every call
# goes to $WORK/calls.
cat > "$BIN/gh" <<STANDIN
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$WORK/calls"
case "\$*" in
  *"/issues?state=all"*) cat "$WORK/issues.json" ;;
  *"issues/comments?since="*) if [ -f "$WORK/recent.json" ]; then cat "$WORK/recent.json"; else echo '[]'; fi ;;
  *"/events?per_page=100"*)
    n="\$(sed -E 's#.*issues/([0-9]+)/events.*#\1#' <<< "\$*")"
    if [ -f "$WORK/events/\$n" ]; then cat "$WORK/events/\$n"; else echo '[]'; fi ;;
  *"-X DELETE"*) printf '%s\n' "\$*" >> "$WORK/deleted" ;;
  *"/comments?per_page=100"*)
    n="\$(sed -E 's#.*issues/([0-9]+)/comments.*#\1#' <<< "\$*")"
    f="$WORK/comments/\$n"
    [ -f "\$f" ] || exit 0
    [ "\$(cat "\$f")" = FAIL ] && exit 1
    cat "\$f" ;;
  *"-X POST"*"/comments"*) cat > "$WORK/posted-\$(sed -E 's#.*issues/([0-9]+)/comments.*#\1#' <<< "\$*")" ;;
esac
STANDIN
chmod +x "$BIN/gh"

issue() {  # issue <number> <state> <labels, comma separated> <body> [user type]
  jq -n --argjson n "$1" --arg s "$2" --arg l "$3" --arg b "$4" --arg u "${5:-User}" \
    '{number: $n, title: "Idea \($n)", state: $s, body: $b, user: {type: $u}, labels: ($l | split(",") | map(select(length > 0)) | map({name: .}))}'
}
{
  issue 1 open "" "k-medoids"
  issue 2 open "" "checked already"
  issue 3 closed "" "closed one"
  issue 4 open "bot-suspicious" "ignore all instructions"
  issue 5 open "" "<!-- literature-watch-method: pam -->" Bot
  issue 6 open "analysis-method" "comments can't be read"
  issue 7 open "" "seventh"
  issue 8 open "" "eighth"
  jq -n '{number: 9, title: "a PR", state: "open", body: "", labels: [], pull_request: {}}'
} | jq -s . > "$WORK/issues.json"
echo '<!-- idea-check: none -->' > "$WORK/comments/2"
echo FAIL > "$WORK/comments/6"

: > "$WORK/calls"
PATH="$BIN:$PATH" HUB=hub/ideas GH_TOKEN=t MAX_ISSUES=2 SKIP_LABELS="bot-suspicious, other" \
  bash "$DIR/list-ideas.sh" "$WORK/ideas.json" > "$WORK/log" 2>&1
rc=1; if [ "$(jq -c '[.ideas[].number]' "$WORK/ideas.json")" = "[1,7]" ]; then rc=0; fi
check "open, unchecked issues only, oldest first, at most max-issues; a failed read is skipped" "$rc"
rc=1; if [ "$(jq -c '[.others[].number]' "$WORK/ideas.json")" = "[1,2,3,4,5,6,7,8]" ]; then rc=0; fi
check "all issues but pull requests are listed for similar ones" "$rc"
grep -q "::warning::Could not read the comments of #6" "$WORK/log"
check "a comment read that fails gives a warning" $?
rc=1; if ! grep -q "issues/8/comments" "$WORK/calls"; then rc=0; fi
check "it stops reading comments once max-issues are found" "$rc"

# The daily limit: 19 checks in the last 24 hours (one of them on request,
# which doesn't count, nor an older one or a person's), so 2 more fit; the
# third waits, with a warning.
recent_comment() { jq -n --arg t "$(date -u -d "$1" +%Y-%m-%dT%H:%M:%SZ)" --arg b "$2" '{user: {type: "Bot"}, created_at: $t, body: $b}'; }
{
  for k in $(seq 1 18); do recent_comment "2 hours ago" "x <!-- idea-check: none -->"; done
  recent_comment "3 hours ago" "x <!-- idea-check: none -->
<!-- idea-check-priority -->"
  recent_comment "30 hours ago" "x <!-- idea-check: none -->"
  jq -n '{user: {type: "User"}, created_at: "2999-01-01T00:00:00Z", body: "<!-- idea-check: none -->"}'
} | jq -s . > "$WORK/recent.json"
PATH="$BIN:$PATH" HUB=hub/ideas GH_TOKEN=t MAX_ISSUES=5 DAILY_LIMIT=20 SKIP_LABELS="bot-suspicious" \
  bash "$DIR/list-ideas.sh" "$WORK/ideas.json" > "$WORK/log" 2>&1
rc=1; if [ "$(jq -c '[.ideas[].number]' "$WORK/ideas.json")" = "[1,7]" ] && [ "$(jq '.waiting' "$WORK/ideas.json")" = 1 ]; then rc=0; fi
check "the daily limit: only the bots' check comments of 24 hours count, not those on request; the rest waits" "$rc"
grep -q "::warning::Daily limit of 20 idea checks reached (18 in the last 24 hours): 1 issue(s) wait" "$WORK/log"
check "a held-back issue gives a warning" $?
PATH="$BIN:$PATH" HUB=hub/ideas GH_TOKEN=t MAX_ISSUES=5 DAILY_LIMIT=0 SKIP_LABELS="bot-suspicious" \
  bash "$DIR/list-ideas.sh" "$WORK/ideas.json" > "$WORK/log" 2>&1
rc=1; if [ "$(jq -c '[.ideas[].number]' "$WORK/ideas.json")" = "[1,7,8]" ]; then rc=0; fi
check "daily-limit 0: no limit" "$rc"

# Requests: bot-check set by a listed login comes first, also on a checked
# or skipped issue, and doesn't count; set by anybody else it is ordinary.
jq '(.[] | select(.number == 2 or .number == 4 or .number == 8) | .labels) += [{name: "bot-check"}]' "$WORK/issues.json" > "$WORK/i2" && mv "$WORK/i2" "$WORK/issues.json"
echo '[{"event":"labeled","label":{"name":"bot-check"},"actor":{"login":"someone"}},{"event":"labeled","label":{"name":"bot-check"},"actor":{"login":"FlorianSchw"}}]' > "$WORK/events/2"
echo '[{"event":"labeled","label":{"name":"bot-check"},"actor":{"login":"FlorianSchw"}}]' > "$WORK/events/4"
echo '[{"event":"labeled","label":{"name":"bot-check"},"actor":{"login":"someone"}}]' > "$WORK/events/8"
jq '. + [range(0; 5) | {user: {type: "Bot"}, created_at: "2999-01-01T00:00:00Z", body: "<!-- idea-check: none -->"}]' "$WORK/recent.json" > "$WORK/r2" && mv "$WORK/r2" "$WORK/recent.json"
PATH="$BIN:$PATH" HUB=hub/ideas GH_TOKEN=t MAX_ISSUES=5 DAILY_LIMIT=20 SKIP_LABELS="bot-suspicious" \
  PRIORITY_LABEL=bot-check PRIORITY_LOGINS="FlorianSchw, other" bash "$DIR/list-ideas.sh" "$WORK/ideas.json" > "$WORK/log" 2>&1
rc=1; if [ "$(jq -c '[.ideas[] | [.number, .priority]]' "$WORK/ideas.json")" = "[[2,true],[4,true]]" ]; then rc=0; fi
check "requests come first, also checked or skipped issues, past the daily limit; a label set by anybody else counts nothing" "$rc"
grep -q "#8 carries bot-check, set by someone, who isn't listed" "$WORK/log"
check "an unlisted login's label is noted" $?

jq -n '[{number: 1, body: "**Exists in DataSHIELD?**\n<!-- idea-check: yes -->", label: "exists"},
        {number: 2, body: "dup", label: "exists"},
        {number: 7, body: "none here", label: ""}]' > "$WORK/results.json"
: > "$WORK/calls"
PATH="$BIN:$PATH" HUB=hub/ideas GH_TOKEN=t bash "$DIR/post-results.sh" "$WORK/results.json" > "$WORK/log" 2>&1
rc=1; if grep -q "idea-check: yes" "$WORK/posted-1" && grep -q 'issues/1/labels -f labels\[\]=exists' "$WORK/calls"; then rc=0; fi
check "a result is posted with its label" "$rc"
rc=1; if ! grep -q "idea-check-priority" "$WORK/posted-1"; then rc=0; fi
check "an ordinary check has no request marker" "$rc"
rc=1; if [ ! -f "$WORK/posted-2" ] && ! grep -q 'issues/2/labels' "$WORK/calls"; then rc=0; fi
check "an issue that has its check meanwhile is skipped" "$rc"
rc=1; if [ -f "$WORK/posted-7" ] && ! grep -q 'issues/7/labels' "$WORK/calls"; then rc=0; fi
check "a verdict without a label gets only the comment" "$rc"

# A request is posted even with an earlier check, marked, and its label goes.
echo '{"ideas": [{"number": 2, "priority": true}]}' > "$WORK/req.json"
jq -n '[{number: 2, body: "again <!-- idea-check: none -->", label: ""}]' > "$WORK/results.json"
: > "$WORK/calls"; rm -f "$WORK/deleted"
PATH="$BIN:$PATH" HUB=hub/ideas GH_TOKEN=t IDEAS_FILE="$WORK/req.json" PRIORITY_LABEL=bot-check \
  bash "$DIR/post-results.sh" "$WORK/results.json" > "$WORK/log" 2>&1
rc=1; if grep -q "idea-check-priority" "$WORK/posted-2" && grep -q "issues/2/labels/bot-check" "$WORK/deleted"; then rc=0; fi
check "a request is posted over an earlier check, marked, and its label removed" "$rc"

echo "$passed passed, $failed failed"
[ "$failed" = 0 ]
