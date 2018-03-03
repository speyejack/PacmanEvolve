console.log("---------- DEBUGGER ----------")
--[[local Pooltop = 0
for ns,s in pairs(pool.species) do	
	table.sort(s.genomes, function (a,b) return(a.fitness > b.fitness) end)
	for ng,g in pairs(s.genomes) do
		if g.fitness > 0 then
			console.log("S: "..ns.." G: " .. ng.. " Fit: "..g.fitness)
			if g.fitness > Pooltop then
				Pooltop = g.fitness
			end
		end
	end
end
console.log("Top: "..Pooltop)
debugTop = 0
for _,s in pairs(debugPool) do
	for _,g in pairs(s) do
		if g.fitness > debugTop then
			debugTop = g.fitness
		end
	end
end
console.log(debugTop)
--]]
--[[
testGenome(level, pool,pool.species[1].genomes[1])
local fit = pool.species[1].genomes[1].fitness
local fails = 0
for i=1,1000 do
	testGenome(level, pool,pool.species[1].genomes[1])
	if pool.species[1].genomes[1].fitness ~= fit then
		console.log("TEST FAILED: inconsistant at "..i)
		console.log(string.format("ERROR: #: %d Fit: %d Inconsistant: %d",i,fit, pool.species[1].genomes[1].fitness))
		fit = pool.species[1].genomes[1].fitness
		fails = fails + 1
	end
end
if fails > 0 then
	console.log(string.format("TEST FAILED: Failed with %d fail(s)",fails))
else
	console.log("TEST SUCCESSFUL: Finished without inconsistancy")
end--]]
--[[
local genomeAfter = getGenomeByID(pool,debugID)
local name = "backup."..(pool.generation-1).."."..SaveName..".pool"
console.log(name)
local old_pool = loadPool(name)
forms.destroyall()
local genomeBefore = getGenomeByID(old_pool, debugID)
testGenome(level,pool,genomeBefore)
local Bfit = genome.fitness
testGenome(level,pool,genomeAfter)
local Afit = genome.fitness
console.log("B:A "..Bfit..":"..Afit)
console.log("Done")
--]]
--[[
local last = debugLastNetwork
local current = getGenomeByID(pool,debugID).neurons
local differ = false
for nn,neuron in pairs(last) do
	for nl, link in pairs(neuron.incoming) do
		if link.into ~= current[nn].incoming[nl].into then
			differ = true
		end
	end
	if differ then break end
end
console.log("Differ: "..tostring(differ))
--]]
console.log(tonumber(false))





