#!/usr/bin/env bash
# Prints a Luau snippet that checks whether the open Studio place holds this repo's code. Run the output
# through the Studio MCP `execute_luau` tool (datamodel Edit). It returns { checked, mismatches }; an empty
# mismatches list means every synced .luau file is in Studio byte for byte (Rojo copies Source verbatim).
# The folder mapping mirrors default.project.json.
set -euo pipefail

cd "$(dirname "$0")/.."

# repo folder -> Studio path from game, "/" separated (instance names such as RunManager.spec hold dots)
mappings=(
  "src/server:ServerScriptService"
  "src/shared:ReplicatedStorage/Shared"
  "src/client:StarterPlayer/StarterPlayerScripts"
  "tests/studio:ServerStorage/Tests"
)

echo 'local expected = {'
for mapping in "${mappings[@]}"; do
  folder="${mapping%%:*}"
  root="${mapping#*:}"
  while IFS= read -r file; do
    relative="${file#"$folder"/}"
    relative="${relative%.luau}"
    relative="${relative%.server}"
    relative="${relative%.client}"
    case "$relative" in
      init) instance="$root" ;;
      */init) instance="$root/${relative%/init}" ;;
      *) instance="$root/$relative" ;;
    esac
    bytes="$(wc -c <"$file" | tr -d ' ')"
    printf '\t{ path = "%s", bytes = %s },\n' "$instance" "$bytes"
  done < <(find "$folder" -name '*.luau' -type f | sort)
done
echo '}'
cat <<'EOF'
local mismatches = {}
for _, entry in expected do
	local node: Instance? = game
	for part in string.gmatch(entry.path, "[^/]+") do
		node = node and node:FindFirstChild(part)
	end
	if node == nil then
		table.insert(mismatches, `{entry.path}: missing`)
	elseif not node:IsA("LuaSourceContainer") then
		table.insert(mismatches, `{entry.path}: not a script`)
	elseif #(node :: any).Source ~= entry.bytes then
		table.insert(mismatches, `{entry.path}: {#(node :: any).Source} bytes, repo has {entry.bytes}`)
	end
end
return { checked = #expected, mismatches = mismatches }
EOF
