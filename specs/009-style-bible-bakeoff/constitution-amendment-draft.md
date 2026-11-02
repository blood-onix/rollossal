# Constitution amendment draft (009, FR-001, research R-01)

Status: **superseded by constitution v4.0.0**, which came from the owner-approved request and has its own pull request:
https://github.com/blood-onix/rollossal/pull/10. This branch first applied this draft as v3.1.0; the merge of v4.0.0 replaced it. Owner
approval is on that pull request. The text below is the original draft, kept as history, and the live constitution wins
wherever it differs.

## Principle IV (replace the last-but-one bullet)

Current: "The game MUST NOT show real brands, logos, flags, meme images or real people's faces, and MUST NOT put words
on textures (pictograms only)."

Proposed: "The game MUST NOT show real brands, logos, flags, meme images, real people's faces, alcohol or gambling
names, or the words "Roblox", "Robux" or "Blox". Invented proper-noun shop names and short signage ARE allowed on
textures and billboards."

## Principle I and Quality Gates (add a visual gate)

Add to Quality Gates, under "What a feature may require":

"Visual gate. Any map or art feature MUST capture the five fixed shots (`art/capture/cameras.json`) before and after
its change, and the owner's review of those shots, or the owner playing the build, MAY hold that feature. The visual
gate is exempt from the two-failure rule. Every other owner check (phone fps, pacing taste, outside playtests) stays on
`docs/release-candidate.md` and MUST NOT hold a feature."

Principle I's last sentence of the feel bullet gains: "Look is the exception, per the visual gate."

## Principle XI

Add:

- "A CC0 mesh imported and moved onto the theme atlas in Blender (one material, UVs in one cell or strip) counts as made
  or edited in Blender. Its licence MUST be recorded in the feature's report."
- "One shared facade/sign atlas and a capped set of billboard textures MAY sit alongside the 1,024 px theme atlas."
- Creator Store line unchanged: scripted models forbidden, mesh-only after inspection.

## Human Approval list

No new entry. The amendment itself is approved by PR.

## Blocks until applied

Authoring signage, importing a CC0 mesh into the game, and treating the visual gate as binding. Not blocked: capture
route, "before" set, bible draft, benchmark, bake-off comparison renders.
