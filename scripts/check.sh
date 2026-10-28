#!/usr/bin/env bash
# Single verification command for Rollossal (Quality Gate 1). Fail-fast: the first failing step exits non-zero.
set -euo pipefail

cd "$(dirname "$0")/.."

RULES_DIR="${RULES_DIR:-src/shared/Rules}"
LUAU_DEFS_TAG="1.70.1"
LUAU_DEFS=".cache/globalTypes.d.luau"

step() { printf '\n== %s\n' "$1"; }

step "StyLua format check"
stylua --check src tests scripts

step "Selene lint"
selene generate-roblox-std
selene src tests

step "Rojo sourcemap"
# wally install removes a realm folder that has no dependencies (Packages today), but the project maps all three.
mkdir -p Packages ServerPackages DevPackages
rojo sourcemap default.project.json --output sourcemap.json

step "luau-lsp strict analysis"
if [ ! -f "$LUAU_DEFS" ]; then
  mkdir -p .cache
  curl -fsSL -o "$LUAU_DEFS" \
    "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/${LUAU_DEFS_TAG}/scripts/globalTypes.d.luau"
fi
luau-lsp analyze \
  --definitions="$LUAU_DEFS" \
  --base-luaurc=.luaurc \
  --sourcemap=sourcemap.json \
  --ignore="**/Packages/**" --ignore="**/ServerPackages/**" --ignore="**/DevPackages/**" \
  src tests/studio

step "Lune unit tests"
lune run tests/unit/run

step "World-agnostic guard (no GreyBoxRoom in src/server or src/client)"
if grep -rn "GreyBoxRoom" src/server src/client --include='*.luau'; then
  echo "FAIL: server and client code must read Worlds, not GreyBoxRoom (see lines above)" >&2
  exit 1
fi
echo "OK: no GreyBoxRoom reference in src/server or src/client"

step "Rules purity guard ($RULES_DIR)"
forbidden='(^|[^[:alnum:]_])(Instance|workspace|game|task|DateTime|Vector3|CFrame|GetService|Enum|tick)([^[:alnum:]_]|$)|math\.random|os\.clock|os\.time|require\(script'
if grep -rnE "$forbidden" "$RULES_DIR" --include='*.luau'; then
  echo "FAIL: forbidden Roblox or non-deterministic identifier in $RULES_DIR (see lines above)" >&2
  exit 1
fi
echo "OK: no forbidden identifiers in $RULES_DIR"

step "All checks passed"
