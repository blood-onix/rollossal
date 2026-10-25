--!strict
-- Runs every *.spec module under ServerStorage.Tests with Jest-Lua. Started from MCP execute_luau:
-- return require(game.ServerStorage.Tests.runner)()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Jest = require(ReplicatedStorage.DevPackages.Jest)

return function()
	local tests = ServerStorage.Tests
	local status, result = Jest.runCLI(tests, { verbose = true, ci = false }, { tests })
		:awaitStatus()
	if status == "Rejected" then
		error(result)
	end
	local failed = result.results.numFailedTestSuites + result.results.numFailedTests
	if failed > 0 then
		error(`{failed} failing Jest suite(s) or test(s)`)
	end
	return result.results
end
