#!/usr/bin/env bash
# Proves the Rules purity guard in scripts/check.sh works: it must FAIL on a forbidden
# identifier and PASS on clean code. The pattern is read from check.sh so the two cannot drift.
set -euo pipefail

cd "$(dirname "$0")/.."

pattern_line="$(grep -E "^forbidden='" scripts/check.sh)"
[ -n "$pattern_line" ] || { echo "FAIL: forbidden pattern not found in scripts/check.sh" >&2; exit 1; }
eval "$pattern_line"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run_guard() {
  grep -rnE "$forbidden" "$1" --include='*.luau' >/dev/null
}

# Clean fixture: pure arithmetic only. The guard must NOT match.
printf -- '--!strict\nlocal function add(a: number, b: number): number\n\treturn a + b\nend\nreturn add\n' \
  > "$tmp/Clean.luau"
if run_guard "$tmp"; then
  echo "FAIL: guard flagged clean code" >&2
  exit 1
fi
echo "OK: clean Rules fixture passes the guard"

# Forbidden fixtures: each identifier must be caught.
for bad in 'local p = game.Players' 'local v = Vector3.new(0, 1, 0)' 'local t = tick()' \
           'local r = math.random(1, 6)' 'local s = task.wait(1)' 'local w = workspace' \
           'local x = os.clock()' 'local i = Instance.new("Part")' 'local m = require(script.Parent.X)'; do
  rm -f "$tmp"/*.luau
  printf -- '--!strict\n%s\n' "$bad" > "$tmp/Bad.luau"
  if ! run_guard "$tmp"; then
    echo "FAIL: guard missed forbidden line: $bad" >&2
    exit 1
  fi
done
echo "OK: guard catches every forbidden identifier fixture"
echo "test-guard passed"
