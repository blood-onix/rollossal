#!/usr/bin/env bash
# Makes sure `rojo serve` is running for this project and reports what an agent needs before any Studio
# task. Starts Rojo in the background when it is not running. Never fails: it only reports.
# Run by the SessionStart hook in .claude/settings.json; safe to run by hand at any time.
set -uo pipefail

cd "$(dirname "$0")/.."

port=34872
log=".cache/rojo-serve.log"

rojo_up() {
  curl -s --max-time 2 "http://localhost:${port}/api/rojo" >/dev/null 2>&1
}

if rojo_up; then
  echo "Rojo: serving on localhost:${port}."
else
  mkdir -p .cache
  nohup rojo serve default.project.json >"$log" 2>&1 &
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.5
    rojo_up && break
  done
  if rojo_up; then
    echo "Rojo: was not running; started \`rojo serve default.project.json\` on localhost:${port} (log ${log})."
  else
    echo "Rojo: could not start \`rojo serve\` (see ${log}). Studio tasks cannot sync until it runs."
  fi
fi

cat <<'EOF'
Studio: before any 🔒 task, call list_roblox_studios, then run the Luau printed by
`scripts/studio-sync-probe.sh` through execute_luau (Edit). An empty `mismatches` list means Studio has
the repo's code. If it is not empty, the Rojo plugin is not connected: ask the user once to press
Connect, then poll the probe (Monitor or ScheduleWakeup, every 30 to 60 s) and continue when it passes.
Do not stop the task or untick Studio work just because the plugin is disconnected. See AGENTS.md.
EOF
