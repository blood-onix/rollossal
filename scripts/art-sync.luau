--!strict
-- Writes art/scripts/budgets.json from Config and the Snow Village data. Run from the repo root:
--   lune run scripts/art-sync

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local ArtBudgets = require("./art-budgets")

local OUTPUT = "art/scripts/budgets.json"

fs.writeDir("art/scripts")
fs.writeFile(OUTPUT, serde.encode("json", ArtBudgets.build(), true) .. "\n")
print(`wrote {OUTPUT}`)
