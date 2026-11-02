# Contract: Bake-off report

File: `specs/009-style-bible-bakeoff/bakeoff/README.md`.

## Layout

1. **Method**: stage, lighting, cameras, props and their sizes (research R-08).
2. **Sources**: one paragraph per source, including `not run (reason)` where applicable.
3. **Matrix**: 5 props × up to 4 sources, with the fields in `data-model.md`.
4. **Renders**: relative links to PNGs under `bakeoff/renders/`.
5. **Licences**: for each CC0 and Creator Store candidate: pack or asset name, URL, licence text or name, download or
   inspection date, creator.
6. **Findings**: what each source did well and badly, with triangle counts against the bible's floor and target.
7. **Sourcing rule**: the owner's rule, plus the result, copied into `docs/design/08-style-bible.md` section 11.
8. **Upload hand-off**: at most 5 props, each with chosen source and the file to upload. Nothing is uploaded by the
   agent.

## Rules

- No file from the bake-off is added to `art/export/` or `manifest.json`.
- A Creator Store model with scripts is recorded and excluded.
- Source 3 is run only after the owner approves possible credit use.
- Renders use the `city` atlas cells; no PBR or transparency in any candidate.
- Owner taste is a note, not a gate.
