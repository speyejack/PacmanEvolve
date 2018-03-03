PoolStateName = "Temp.pool"
SaveName = "PacMan"
StateName = "Pac-Man-2"
LevelName = "Pac-Man.lvl"
InputRadius = 6
InputSize = (InputRadius*2+1)*(InputRadius*2+1)
totalPellets = 192

ButtonNames = {
	"Up",
	"Down",
	"Left",
	"Right",
}

Inputs = InputSize+1
Outputs = #ButtonNames

Population = 200
--[[
DeltaExcess = 1.0
DeltaDisjoint = 1.0
DeltaWeights = 0.4
DeltaThreshold = 3.0
--]]
DeltaExcess = 5.0
DeltaDisjoint = 5.0
DeltaWeights = 1.0
DeltaThreshold = 0.7
--
DeltaTimer = 0.1
DeltaPellet = 192000
Deltalevel = 10000

StaleSpecies = 20
MutateConnectionsChance = 0.25
PerturbChance = 0.90
CrossoverChance = 0.75
LinkMutationChance = 0.20
NodeMutationChance = 0.05
PreturbMutationChance = 0.05
StepSize = 0.1
DisableMutationChance = 0.4
EnableMutationChance = 0.2

TimeoutConstant = 20

MaxNodes = 1000000

function newInnovation()
	-- This is a place holder function, newPool() creates the real function
	return -1
end

function newGenomeID()
	-- This is a place holder function, newPool() creates the real function
	return -1
end

function newPool()
	local pool = {}
	pool.species = {}
	pool.generation = 0
	pool.innovation = 0
	pool.genomeId = 0
	pool.maxFitness = 0
	pool.currSpecies = 1
	pool.currGenome = 0
	pool.progression = 0
	pool.playTop = false
	pool.reset = false
	pool.time = os.clock()
	function newInnovation() pool.innovation = pool.innovation + 1 return pool.innovation end
	function newGenomeID() pool.genomeId = pool.genomeId + 1 return pool.genomeId end
	createForm(level,pool)
	return pool
end

function newSpecies()
	local species = {}
	species.genomes = {}
	species.staleness = 0
	species.maxFitness = 0
	species.averageFitness = 0
	return species
end

function newGenome()
	local genome = {}
	genome.neurons = {}
	genome.links = {}
	genome.fitness = 0
	genome.size = 0
	genome.rank = 0
	genome.id = newGenomeID()
	genome.mutationRates = {}
	genome.mutationRates["weights"] = MutateConnectionsChance
	genome.mutationRates["link"] = LinkMutationChance
	genome.mutationRates["perturb"] = PreturbMutationChance
	genome.mutationRates["node"] = NodeMutationChance
	genome.mutationRates["step"] = StepSize
	return genome
end

function newLink()
	local link = {}
	link.into = 0
	link.out = 0
	link.weight = 0
	link.enabled = true
	link.innovation = 0
	return link
end

function copyLink(link)
	local nLink = {}
	nLink.into = link.into
	nLink.out = link.out
	nLink.weight = link.weight
	nLink.enabled = link.enabled
	nLink.innovation = link.innovation
	return nLink
end

function newNeuron()
	local neuron = {}
	neuron.incoming = {}
	neuron.value = 0.0
	return neuron
end

function getNeuronRanks(genome)
	local indices = {}
	local starts = {} -- Links 
	local ends = {}
	for i = 1, #genome.links do
		if genome.links[i].enabled then
			table.insert(indices, i)
			if starts[genome.links[i].into] == nil then
				starts[genome.links[i].into] = {}
			end
			table.insert(starts[genome.links[i].into],i)
			ends[genome.links[i].out] = true
		end
	end
	local ranks = {}
	local rankIndex = 0
	local checking = {}
	local tocheck = {}
	local checked = {}
	for _, index in pairs(indices) do
		if genome.links[index].into <= Inputs or ends[genome.links[index].into] == nil then
			table.insert(checking, index)
			checked[index] = 1
		end
	end
	while #checking > 0 do
		ranks[rankIndex] = checking
		rankIndex = rankIndex + 1
		for _, index in pairs(checking) do	
			if checked[index] == nil then checked[index] = 1 end
			if starts[genome.links[index].out] ~= nil and checked[index] < 3 then
				for _, link in pairs(starts[genome.links[index].out]) do
					table.insert(tocheck,link)
					checked[index] = checked[index] + 1
				end
			end
		end
		checking = tocheck
		tocheck = {}
	end
	ranks[rankIndex] = {}
	for o = 1, Outputs do
		table.insert(ranks[rankIndex],MaxNodes + o)
	end
	local nums = {}
	for rank = 0,rankIndex - 1 do
		for _,linkIndex in pairs(ranks[rank]) do
			nums[genome.links[linkIndex].into] = rank - 1
			nums[genome.links[linkIndex].out] = rank 
		end
	end
	return nums, rankIndex - 1
end

function generateNetwork(genome)
	local network = {}
	local collection = {}
	local convert = {}
	local convertR = {}
	
	for i=1,Inputs do
		local neuron = newNeuron()
		collection[i] = neuron
		network[i] = neuron
		convert[i] = i
		convertR[i] = i
	end
	network[Inputs].value = 1
	
	local ranks = getNeuronRanks(genome)
	local unsorted = {}
	
	for o=1,Outputs do
		collection[o + MaxNodes] = newNeuron()
		convert[o + MaxNodes] = o + MaxNodes
		convertR[o + MaxNodes] = o + MaxNodes
	end
	
	-- To generate the pairings, you could order them by a float, with 0 as input, 1 as output, 
	-- and for every division of a link, you just take the midpoint between the two linked nodes. 
	-- Then sort the list based on that float value
	for _,link in pairs(genome.links) do
		if link.enabled then
			if collection[link.into] == nil and link.into > Inputs and link.into <= MaxNodes then
				local neuron = newNeuron()
				collection[link.into] = neuron
				assert(ranks[link.into] ~= nil,"Failed into with "..link.into)
				table.insert(unsorted, {rank=ranks[link.into],neuron = neuron, id = link.into})
			end
			if collection[link.out] == nil and link.out > Inputs and link.out <= MaxNodes then
				local neuron = newNeuron()
				collection[link.out] = neuron
				assert(ranks[link.out] ~= nil,"Failed out with "..link.out)
				table.insert(unsorted, {rank=ranks[link.out],neuron = neuron, id = link.out})
			end
			table.insert(collection[link.out].incoming, link)
		end
	end
	table.sort(unsorted, function (a,b) return (a.rank < b.rank) end)
	--[[for _,neuron in pairs(unsorted) do
		console.write(neuron.rank..", ")
	end
	
	console.log()--]]
	--console.log(#unsorted)
	for  i = 1,#unsorted do
		if unsorted[i].id > Inputs then
			table.insert(network,unsorted[i].neuron)
			convert[unsorted[i].id] = #network
			convertR[#network] = unsorted[i].id
		end
	end
	
	for o=1,Outputs do
		network[o + MaxNodes] = collection[o+MaxNodes]
	end
	genome.neurons = network
	genome.convert = convert
	genome.convertR = convertR
end

function basicGenome()
	local genome = newGenome()
	genome.size = Inputs
	while not linkMutate(genome) do end
	genome.mutationRates["link"] = 1
	mutate(genome)
	genome.mutationRates["link"] = LinkMutationChance
	return genome
end

function clearJoypad()
	local pad = joypad.get()
	for b,t in pairs(pad) do
		pad[b] = false
	end
	joypad.set(pad)
end

function setJoypad(output)
	if output["P1 "..ButtonNames[1]] and output["P1 "..ButtonNames[2]] then
		output["P1 "..ButtonNames[1]] = false
		output["P1 "..ButtonNames[2]] = false
	end
	if output["P1 "..ButtonNames[3]] and output["P1 "..ButtonNames[4]] then
		output["P1 "..ButtonNames[3]] = false
		output["P1 "..ButtonNames[4]] = false
	end
	joypad.set(output)
end

function initalizePool()
	local pool = newPool()
	for i = 1,Population do
		addToGeneration(pool, basicGenome())
	end
	console.write("Starting ")
	logPool(pool)
	savePool("backup."..pool.generation.."."..SaveName..".pool", pool)
	startPoolState(PoolStateName,pool)
	return pool
end

function sigmoid(x)
	return 2/(1+math.exp(-4.9*x))-1
end

function evaluateNetwork(genome, inputs)
	local network = genome.neurons
	for i=1,#inputs do
		network[i].value = inputs[i]
	end
	
	for n,neuron in pairs(network) do
		local sum = 0 
		for _,link in pairs(neuron.incoming) do
			if link.enabled then
				if genome.convert[link.into] == nil then
					console.log(link.into..":"..link.out)
					assert(false,"Found bad link during evaluating network")
				end
				sum = sum + network[genome.convert[link.into]].value * link.weight
			end
		end
		if sum ~= 0 then
			neuron.value = sigmoid(sum)
		end
	end
	
	local output = {}
	for o = 1,Outputs do
		local name = "P1 " .. ButtonNames[o]
		if network[o + MaxNodes].value > 0 then
			network[o + MaxNodes].value = 1
			output[name] = true
		else
			network[o + MaxNodes].value = 0
			output[name] = false
		end
	end
	return output
end

function containsLink(genome,link)
	local found = false
	for n,connect in pairs(genome.links)do
		if link.into == connect.into and link.out == connect.out then
			found = true
			break
		end
	end
	return found
end

function randomNeuronIndex(genome, nonInput)
	local validNeurons = {}
	if not nonInput then
		for i = 1, Inputs do
			validNeurons[i] = true
		end
	end
	
	for i = 1, Outputs do
		validNeurons[i + MaxNodes] = true
	end
	
	for n,link in pairs(genome.links) do
		if link.into > Inputs then
			validNeurons[link.into] = true
		end
		if link.out > Inputs then
			validNeurons[link.out] = true
		end
	end
	
	local count = 0
	for _,_ in pairs(validNeurons) do
		count = count + 1
	end
	
	if count == 0 then
		return 0
	end
	
	local k = math.random(1, count)
	for n,neuron in pairs(validNeurons) do
		if k == 1 then
			return n
		end
		k = k - 1
	end
	
end

function linkMutate(genome)
	local n1 = randomNeuronIndex(genome, false)
	local n2 = randomNeuronIndex(genome, true)
	if (n1 <= Inputs and n2 <= Inputs) or (n1 > MaxNodes and n2 > MaxNodes)  or n1 == n2 then
		return false
	end
	if n1 > n2 then
		temp = n1
		n1 = n2
		n2 = temp
	end
	local link = newLink()
	link.into = n1
	link.out = n2
	if containsLink(genome, link) then
		return false
	end
	
	link.weight = math.random() * 2 - 1
	link.innovation = newInnovation()
	table.insert(genome.links,link)
	return true
end

function nodeMutate(genome)
	if #genome.links < 1 then
		return
	end
	local link = genome.links[math.random(#genome.links)]
	if not link.enabled then
		return
	end
	genome.size = genome.size + 1
	
	link.enabled = false
	local l1 = newLink()
	l1.into = link.into
	l1.out = genome.size
	l1.weight = link.weight
	l1.innovation = newInnovation()
	local l2 = newLink()
	l2.into = genome.size
	l2.out = link.out
	l2.weight = 1
	l2.innovation = newInnovation()
	table.insert(genome.links,l1)
	table.insert(genome.links,l2)
	
end

function weightMutate(genome)
	for _,link in pairs(genome.links) do
		if math.random() < genome.mutationRates["perturb"] then
			link.weight = math.random() * 2 - 1
		end
	end		
end

function mutate(genome)
	if math.random() < genome.mutationRates["link"] then
		linkMutate(genome)
	end
	
	if math.random() < genome.mutationRates["node"] then
		nodeMutate(genome)
	end
	
	if math.random() < genome.mutationRates["weights"] then
		weightMutate(genome)
	end
	return genome
end

function crossover(g1, g2)
	if g2.fitness > g1.fitness then
		local temp = g1
		g1 = g2
		g2 = temp
	end
	
	local child = newGenome()
	local genes2 = {}
	for i = 1,#g2.links do
		genes2[g2.links[i].innovation] = link
	end
	
	for i = 1,#g1.links do
		local link = g1.links[i]
		local link2 = genes2[link.innovation]
		if link2 ~= nil and math.random(2) == 1 and link2.enabled then
			table.insert(child.links, copyLink(link2))
		else
			table.insert(child.links, copyLink(link))
		end
	end
	
	for mutation,rate in pairs(g1.mutationRates) do
		child.mutationRates[mutation] = rate
	end
	
	child.size = math.max(g1.size,g2.size)
	return child
end

function sameSpecies(s1, s2)
	-- Makes s1 have the most links
	if s1.links[#s1.links].innovation < s2.links[#s2.links].innovation then
		temp = s1
		s1 = s2
		s2 = temp
	end
	links1 = {}
	for i = 1, #s1.links do
		links1[s1.links[i].innovation] = s1.links[i]
	end
	
	links2 = {}
	for i = 1, #s2.links do
		links2[s2.links[i].innovation] = s2.links[i]
	end

	local disjoint = 0
	local excess = 0
	local weight = 0
	local count = 1
	for n,link in pairs(links1) do
		if n > s2.links[#s2.links].innovation then
			excess = excess + 1
		elseif links2[n] == nil then
			disjoint = disjoint + 1
		else
			weight = weight + math.abs(link.weight - links2[n].weight)
			count = count + 1
		end
	end
	for n,link in pairs(links2) do
		if links1[n] == nil then
			disjoint = disjoint + 1
		end
		
	end
	local n = 0
	for _,_ in pairs(links1) do
		n = n + 1
	end
	--[[
	if #links1 < 20 then
		n = 1
	else n = #links1 end
	n = #links1
	--]]
	
	local diff = (DeltaExcess * excess / n) + (DeltaDisjoint *  disjoint/ n) + (DeltaWeights * weight / count)
	return DeltaThreshold > diff
end

function addToGeneration(pool, genome)
	for i = 1,#pool.species do
		if sameSpecies(pool.species[i].genomes[1], genome) then
			table.insert(pool.species[i].genomes,genome)
			return
		end
	end
	
	local species = newSpecies()
	table.insert(pool.species,species)
	table.insert(species.genomes,genome)
end

function cullSpecies(pool, CutToOne)
	for s = 1, #pool.species do
		table.sort(pool.species[s].genomes, function (a,b) return (a.fitness > b.fitness) end)
		--console.log(s.." Top B: "..pool.species[s].genomes[1].fitness)
		
		local genomes = {}
		local safe = 1
		if not CutToOne then
			safe = math.ceil((#pool.species[s].genomes)/2)
		end
		for g = 1, safe do
			table.insert(genomes,pool.species[s].genomes[g])
		end
		--console.log(s.." Top A: "..pool.species[s].genomes[1].fitness)
		pool.species[s].genomes = genomes
	end
end

function calculateAverage(species)
	local sum = 0
	for i = 1,#species.genomes do
		sum = sum + species.genomes[i].fitness
	end
	species.averageFitness = sum/#species.genomes
	return species.averageFitness
end

function totalAverageFitness(pool)
	local total = 0
	for s = 1,#pool.species do
		total = total + calculateAverage(pool.species[s])
	end
	return total
end

function rankGlobally(pool)
	genomes = {}
	for _,species in pairs(pool.species) do
		for _,genome in pairs(species.genomes) do
			table.insert(genomes,genome)
		end
	end
	
	table.sort(genomes, function (a,b) return (a.fitness > b.fitness) end)
	
	for i = 1, #genomes do
		genomes[i].rank = i
	end
end

function removeStaleSpecies(pool)
	local survived = {}
	for n,species in pairs(pool.species) do
		table.sort(species.genomes, function (a,b) return (a.fitness > b.fitness) end)
		if species.genomes[1].fitness > species.maxFitness then
			species.maxFitness = species.genomes[1].fitness
			species.staleness = 0
		else
			species.staleness = species.staleness + 1
		end
		if species.staleness <= StaleSpecies or species.maxFitness >= pool.maxFitness then
			table.insert(survived, species)
		end
	end
	pool.species = survived
end

function removeWeakSpecies(pool)
	local survived = {}
	
	local total = totalAverageFitness(pool)
	for _,species in pairs(pool.species) do
		local pop = math.floor(species.averageFitness / total * Population)
		if pop >= 1 then
			table.insert(survived, species)
		end
	end
	
	pool.species = survived
end

function sortSpecies(pool)
	table.sort(pool.species, function (a,b) return (a.maxFitness > b.maxFitness) end)
	for _,species in pairs(pool.species) do
		table.sort(species.genomes, function (a,b) return (a.fitness > b.fitness) end )
	end
end

function breedChild(species)
	local p1 = species.genomes[math.random(#species.genomes)]
	local p2 = species.genomes[math.random(#species.genomes)]
	local child = crossover(p1,p2)
	
	mutate(child)
	
	return child
end

function newGeneration(pool)
	debugPool = {}
	for ns, s in pairs(pool.species) do
		debugPool[ns] = {}
		for ng, g in pairs(s.genomes) do
			debugPool[ns][ng] = g
		end
	end
	local realMax = 0
	local topG = 0
	local topS = 0
	for ns,s in pairs(pool.species) do
		s.maxFitness = 0
		for ng,g in pairs(s.genomes) do
			if g.fitness > realMax then
				realMax = g.fitness
				topG = ng
				topS = ns
			end
			if g.fitness > s.maxFitness then
				s.maxFitness = g.fitness
			end
		end
	end
	-- console.log("S: "..topS.." G: "..topG)
	
	local fail = false
	if (realMax < pool.maxFitness) then error("Premature Degeneration") end
	logPool(pool)
	pool.time = os.clock()
	--[[
	if fail then
		console.log("ERROR: Gen "..pool.generation.." devolved from "..pool.maxFitness.." to "..realMax)
		pool.maxFitness = realMax
		client.pause()
		-- error("Degeneration")
	end
	-- error("Finished Gen")
	--]] 
	cullSpecies(pool, false)
	removeStaleSpecies(pool)
	rankGlobally(pool)
	sortSpecies(pool)
	removeWeakSpecies(pool)

	-- Reproduce
	local total = totalAverageFitness(pool)
	children = {}
	for s = 1,#pool.species do
		local species = pool.species[s]
		if pool.maxFitness < species.maxFitness then
			pool.maxFitness = species.maxFitness
		end
		
		local breed = math.floor(species.averageFitness / total * Population) - 1
		for i = 1, breed do
			table.insert(children, breedChild(species))
		end
	end
	
	-- Insert Species
	cullSpecies(pool, true)
	while #pool.species + #children < Population do
		table.insert(children,breedChild(pool.species[math.random(#pool.species)]))
	end
	
	realMax = 0
	for ns,s in pairs(pool.species) do
		s.maxFitness = 0
		for ng,g in pairs(s.genomes) do
			if g.fitness > realMax then
				realMax = g.fitness
				topG = ng
				topS = ns
			end
			if g.fitness > s.maxFitness then
				s.maxFitness = g.fitness
			end
		end
	end
	
	if realMax ~= pool.maxFitness then
		error("Degeneration")
	end
	
	for i = 1,#children do
		addToGeneration(pool,children[i])
	end
	
	pool.generation = pool.generation + 1
	pool.currGenome = 0
	pool.currSpecies = 1
	pool.progression = 0
	savePool("backup."..pool.generation.."."..SaveName..".pool", pool)
	startPoolState(PoolStateName,pool)
end 

function playTop(level, pool)
	local topSpecies = 0
	local topGenome = 0
	local topFitness = 0
	for ns,s in pairs(pool.species) do
		for ng,g in pairs(s.genomes) do
			if topFitness < g.fitness then
				topFitness = g.fitness
				topSpecies = ns
				topGenome = ng
			end
		end
	end
	-- console.write("TopF: "..topFitness.. " RealF: "..pool.species[topSpecies].genomes[topGenome].fitness .. " S: " .. topSpecies .. " g: " .. topGenome)
	client.speedmode(100)
	testGenome(level, pool, pool.species[topSpecies].genomes[topGenome])
	client.speedmode(6399)
end

function loadLevel(filename)
	local level = {}
	local file = io.open(filename,"r")
	local switch = {["#"] = 1,["o"] = 0,["."] = 0,[" "] = 0}
	local y = 0
	for line in file:lines(filename) do
		--console.write(line)
		y = y + 1
		level[#level + 1] = {}
		for x = 1,#line do
			--console.write(switch[string.sub(line,x,x)])
			table.insert(level[y],switch[line.sub(line,x,x)])
		end
	end
	file:close()
	return level
end

function savePool(filename, pool)
	local file = io.open(filename,"w")
	file:write(pool.generation.."\n")
	file:write(pool.maxFitness.."\n")
	file:write(pool.innovation.."\n")
	file:write(pool.currSpecies.."\n")
	file:write(pool.currGenome.."\n")
	file:write(#pool.species.."\n")
	for s = 1,#pool.species do
		local species = pool.species[s]
		file:write(species.maxFitness.."\n")
		file:write(species.averageFitness.."\n")
		file:write(species.staleness.."\n")
		file:write(#species.genomes.."\n")
		for g = 1,#species.genomes do
			local genome = species.genomes[g]
			file:write(genome.fitness.."\n")
			file:write(genome.size.."\n")
			file:write(genome.id.."\n")
			for m,r in pairs(genome.mutationRates)do
				file:write(m.."\n")
				file:write(r.."\n")
			end
			file:write("Done\n")
			file:write(#genome.links.."\n")
			for l = 1,#genome.links do
				local link = genome.links[l]
				file:write(link.into.." ")
				file:write(link.out.." ")
				file:write(link.weight.." ")
				file:write(link.innovation.." ")
				if link.enabled then file:write("1\n") else file:write("0\n") end
			end
		end
	end
	
	file:close()
end

function loadPool(filename)
	local file = io.open(filename, "r")
	if file == nil then return end
	local pool = newPool()
	pool.generation = file:read("*number")
	pool.maxFitness = file:read("*number")
	pool.innovation = file:read("*number")
	pool.currSpecies = file:read("*number")
	pool.currGenome = file:read("*number")
	for s = 1,file:read("*number") do
		local species = newSpecies()
		
		species.maxFitness = file:read("*number")
		species.averageFitness = file:read("*number")
		species.staleness = file:read("*number")
		for g = 1,file:read("*number") do
			local genome = newGenome()
			genome.fitness = file:read("*number")
			genome.size = file:read("*number")
			genome.id = file:read("*number")
			if genome.id > pool.genomeId then pool.genomeId = genome.id end
			local line = file:read("*line")
			while line ~= "Done" do
				genome.mutationRates[line] = file:read("*number")
				line = file:read("*line")
			end
			for l = 1, file:read("*number") do
				local link = newLink()
				link.into, link.out, link.weight, link.innovation, link.enabled = file:read("*number","*number","*number","*number","*number")
				if link.enabled == 1 then link.enabled = true else link.enabled = false end
				genome.links[l] = link
			end
			species.genomes[g] = genome
		end
		pool.species[s] = species
	end
	
	file:close()
	return pool
end

function loadPoolState(filename)
	local file = io.open(filename,"r")
	if file == nil then return end
	local poolF = file:read("*line")
	if poolF == nil then return end
	local pool = loadPool(poolF)
	local line = file:read("*line")
	while line ~= nil do
		genome = getNextGenome(pool)
		genome.fitness = tonumber(line)
		if genome.fitness > pool.maxFitness then
			pool.maxFitness = genome.fitness
		end
		line = file:read("*line")
	end
	file:close()
	return pool
end

function startPoolState(filename, pool)
	local file = io.open(filename,"w+")
	file:write("backup."..pool.generation.."."..SaveName..".pool")
	file:close()
end

function updatePoolState(filename ,genome)
	local file = io.open(filename, "a+")
	file:write("\n"..genome.fitness)
	file:close()
end

function restartPoolState(filename, pool)
	local file = io.open(filename,"w+")
	file:write("backup."..pool.generation.."."..SaveName..".pool\n")
	local genome = 1
	for s = 1,pool.currSpecies - 1 do
		for g = 1, #pool.species[s].genomes do
			file:write(pool.species[s].genomes[g].fitness.."\n")
		end
	end
	for g = 1,pool.currGenome - 1 do
		file:write(pool.species[s].genomes[g].fitness.."\n")
	end
	file:close()
end

function getPosition()
	return math.ceil((memory.read_u8(0x001A)-4)/8) - 1, math.ceil((memory.read_u8(0x001C)-4)/8) - 0
end

function getInputs(level)
	local input = {}
	local size = InputRadius*2+1
	--[[
	local pacX = 0
	local pacY = 0 --]]
	local pacX, pacY = getPosition()
	local xBound = 176/8 - 1
	local yBound = 216/8
	local ghosts = {}
	
	for n = 0,3 do
		local gX = math.ceil((memory.read_u8(0x001E + n * 4)-4)/8) - 1
		local gY = math.ceil((memory.read_u8(0x0020 + n * 4)-4)/8) - 0
		gX = pacX - gX
		gY = pacY - gY
		if ((math.abs(gX) <= InputRadius) and (math.abs(gY) <= InputRadius)) then
			ghosts[#ghosts + 1] = {}
			ghosts[#ghosts].x = gX
			ghosts[#ghosts].y = gY
		end
	end

	
	for dy = -InputRadius, InputRadius do
		for dx = -InputRadius, InputRadius do
			if ((pacX + dx >= 1) and (pacX + dx <= xBound) and (pacY + dy >= 1) and (pacY + dy <= yBound)) then
				input[#input + 1] = level[pacY + dy][pacX + dx]
				for _,ghost in pairs(ghosts) do
					if (input[#input] == 0 and -ghost.x == dx and -ghost.y == dy) then
						input[#input] = -1
					end
				end
			else
				input[#input + 1] = 1
			end
		end
	end
	return input
end

function getScore()
	return 100000 * memory.read_u8(0x0075) + 10000 * memory.read_u8(0x0074) + 1000 * memory.read_u8(0x0073) + 100 * memory.read_u8(0x0072) + 10 * memory.read_u8(0x0071) +  memory.read_u8(0x0070)
end

function getFitness()
	return memory.read_u8(0x0068) * totalPellets + (totalPellets - memory.read_u8(0x006A))
end

function testGenome(level, pool, genome)
	local oldX = 0
	local oldY = 0
	local timeout = 0
	local timer = 0
	local isTesting = true
	local frame = 0
	if genome.fitness ~= 0 then
		debugLastNetwork = genome.neurons
	end
	generateNetwork(genome)
	savestate.load(StateName..".state")
	local inps = nil
	local canvas = nil
	local outs = nil
	while isTesting do
		if frame % 5 == 0 then
			inps = getInputs(level)
			outs = evaluateNetwork(genome, inps)
			genome.fitness = getFitness()
			canvas = createGUI(pool, genome)
			pelletsLeft = memory.read_u8(0x006A)
		end
		joypad.set(outs)
		drawGUI(canvas)
		
		local pacX,pacY = getPosition()
		if oldX == pacX and oldY == pacY then
			timeout = timeout + 1
		else
			oldX = pacX
			oldY = pacY
			timeout = 0
			timer = timer + 1
		end
		
		if pelletsLeft == 0 then
			while memory.read_u8(0x006A) == 0 do
				emu.frameadvance()
			end
			while memory.read_u8(0x001A) == 0 do
				emu.frameadvance()
			end
			local startX = memory.read_u8(0x001A)
			while memory.read_u8(0x001A) == startX do
				emu.frameadvance()
			end
			client.pause()
		end
		--[[
		if timeout > TimeoutConstant then
			isTesting = false
			clearJoypad()
		end
		--]]
		if memory.read_u8(0x0067) < 3 or timeout > TimeoutConstant + timer then
			genome.fitness = getFitness()
			return
		end
		frame = frame + 1
		emu.frameadvance()
	end
end

function createGUI(pool,genome)
	local backgroundColor = 0xFF000000 + 0x00101010 * 2
	local cellSize = 4
	local xPos = 214
	local yPos = 92
	local outXPos = xPos
	local outYPos = 218
	
	--[[if not isGUIChecked() then
		return nil
	end--]]
	local neuralSpace = outYPos - yPos - (InputRadius+2) * cellSize 
	local canvas = {}
	local cells = {}
	canvas.boxes = {}
	canvas.lines = {}
	canvas.text = {}
	canvas.letters = {}
	table.insert(canvas.boxes,{174,18, 255, 231,backgroundColor, backgroundColor})
	
	-- Write top text
	canvas.text[1] = {xPos - InputRadius * cellSize, 18, "Generation: "..pool.generation, 0xFFFFFFFF, backgroundColor}
	canvas.text[2] = {xPos - InputRadius * cellSize, 26, "Species: "..pool.currSpecies, 0xFFFFFFFF, backgroundColor}
	canvas.text[3] = {xPos - InputRadius * cellSize, 34, "Genome: "..pool.currGenome, 0xFFFFFFFF, backgroundColor}
	canvas.text[4] = {xPos - InputRadius * cellSize, 42, "Fitness: "..genome.fitness, 0xFFFFFFFF, backgroundColor}
	canvas.text[5] = {xPos - InputRadius * cellSize, 50, "Top Fitness: "..pool.maxFitness, 0xFFFFFFFF, backgroundColor}
	canvas.text[6] = {xPos - InputRadius * cellSize, 58, "Progress: "..math.floor(pool.progression / Population * 100).."%", 0xFFFFFFFF, backgroundColor}
	-- Input Cells
	local i = 1
	for dy = -InputRadius, InputRadius do
		for dx = -InputRadius, InputRadius do
			cell = {}
			cell.x = xPos + dx * cellSize
			cell.y = yPos + dy * cellSize
			cell.value = genome.neurons[i].value
			if cell.value == 0 then
				cell.value = -0.1
			end
			cells[#cells + 1] = cell
			i = i + 1
		end
	end
	
	
	-- Bias Cell
	local biasCell = {}
	biasCell.x = xPos + cellSize * -(InputRadius + 2)
	biasCell.y = yPos + cellSize * InputRadius
	biasCell.value = 1
	table.insert(cells, biasCell)
	-- Output Cells
	local dx = -math.ceil(Outputs/2)
	local spacer = math.ceil((2*InputRadius + 1)/Outputs*cellSize)
	for n,b in pairs(ButtonNames) do
		cell = {}
		cell.x = xPos + dx * spacer + cellSize
		cell.y = outYPos
		cell.value = math.ceil(genome.neurons[MaxNodes + n].value) / 2 + 0.5
		--if genome.neurons[MaxNodes + n].value > 0 then cell.value = 1 else cell.value = 0.5 end
		value = math.floor(cell.value * 0xFF)
		table.insert(canvas.letters,{cell.x - cellSize, cell.y + 2, string.sub(b,1,1), 0xFFFFFFFF, backgroundColor})
		cells[MaxNodes + n] = cell
		dx = dx + 1
	end
	
	-- Middle Cells
	math.randomseed(genome.links[#genome.links].innovation * #genome.neurons)
	math.random()
	local ySpacer = ((neuralSpace)/(#genome.neurons - Inputs + 1))
	-- canvas.debug = {xPos - InputRadius * cellSize ,shiftdown,xPos + InputRadius *cellSize,shiftdown + (#genome.neurons - Inputs + 1) * ySpacer,0xFFFFFFFF,0xFFFFFFFF}
	for n,neuron in pairs(genome.neurons) do
		if n > Inputs and n <= MaxNodes then
			local cell = {}
			--cell.x = xPos
			--cell.y = yPos + InputRadius * cellSize + neuralSpace/2
			cell.x = math.random(-InputRadius,InputRadius) * cellSize + xPos
			cell.y = math.floor((yPos + (InputRadius + 1) * cellSize) + ((n - Inputs + 1) * ySpacer))
			-- cell.y = (yPos + InputRadius) + ((n - Inputs) * ySpacer + math.random()/2 * ySpacer)
			cell.value = neuron.value
			
			cells[genome.convertR[n]] = cell
		end
	end
	
	local halfCell = cellSize/2
	for n, cell in pairs(cells) do
		local value = math.ceil((cell.value + 1) / 2 * 0xFF)
		--local opacity =0xFF000000
		local opacity = 0xFF000000
		if cell.value == 0 then
			opacity = 0x50000000
		end
		color = opacity + value*0x10000 + value*0x100 + value
		table.insert(canvas.boxes,{cell.x - halfCell, cell.y - halfCell,
					cell.x + halfCell, cell.y + halfCell, opacity,color})
	end
	table.insert(canvas.lines, {xPos,yPos,xPos,yPos-cellSize,0xFFFF0000})
	
	-- Draws Links
	for n,link in pairs(genome.links) do
		if link.enabled then
			local c1 = cells[link.into]
			local c2 = cells[link.out]
			local opacity = 0xA0000000
			if c1.value == 0 then
				opacity = 0x20000000
			end
			
			local color = 0x80-math.floor(math.abs(sigmoid(link.weight))*0x80)
			if link.weight > 0 then 
				color = opacity + 0x8000 + 0x10000*color
			else
				color = opacity + 0x800000 + 0x100*color
			end
			--console.log(c1.x..", "..c1.y..", "..c2.x..", "..c2.y..", "..string.format("0x%x",color))
			table.insert(canvas.lines,{c1.x,c1.y,c2.x,c2.y, color})
		end
	end
	
	return canvas
end

function drawGUI(canvas)
	--Config
	if not isGUIChecked() or canvas == nil then
		return nil
	end
	
	for _,box in pairs(canvas.boxes) do gui.drawBox(box[1],box[2],box[3],box[4],box[5],box[6]) end
	for _,text in pairs(canvas.text) do gui.pixelText(text[1],text[2],text[3],text[4],text[5]) end
	for _,letter in pairs(canvas.letters) do gui.drawText(letter[1], letter[2], letter[3], letter[4], letter[5]) end
	for _,line in pairs(canvas.lines) do gui.drawLine(line[1], line[2], line[3], line[4], line[5]) end
	-- gui.drawBox(canvas.debug[1],canvas.debug[2],canvas.debug[3],canvas.debug[4],canvas.debug[5],canvas.debug[6])
end

function getCurrentGenome(pool)
	return pool.species[pool.currSpecies].genomes[pool.currGenome]
end

function getGenomeByID(pool,id)
	for _,s in pairs(pool.species) do
		for _,g in pairs(s.genomes) do
			if g.id == id then
				return g
			end
		end
	end
	return nil
end

function getNextGenome(pool)
	-- Finds next genome
	if pool.currGenome >= #pool.species[pool.currSpecies].genomes then
		pool.currGenome = 0
		pool.currSpecies = pool.currSpecies + 1
	end
	if pool.currSpecies > #pool.species then
		newGeneration(pool)
	end
	pool.currGenome = pool.currGenome + 1
	pool.progression = pool.progression + 1
	return pool.species[pool.currSpecies].genomes[pool.currGenome]
end

function onExit()
	forms.destroyall()
	client.speedmode(100)
end

function createForm(level, pool)
	local form = {}
	form[1] = forms.newform(200,220,"Contoller")
	forms.setlocation(form[1],client.xpos() + client.screenwidth() + 4,0)
	--[[
	forms.button(form,"Link Mutate",function () linkMutate(genome); generateNetwork(genome) end, 5, 10)
	forms.button(form,"Node Mutate",function () nodeMutate(genome); generateNetwork(genome) end, 5, 35)
	forms.button(form,"Weight Mutate",function () weightMutate(genome); generateNetwork(genome) end, 5, 60)
	forms.button(form,"Mutate",function () mutate(genome); generateNetwork(genome) end, 5, 85)
	
	--]]
	form[2] = forms.button(form[1], "Play Top", function () pool.playTop = true end,5,80)
	form[3] = forms.checkbox(form[1], "GUI", 5, 140)
	form[4] = forms.label(form[1],"Generation: ",5,10)
	form[5] = forms.label(form[1],"Progress: ",5,35)
	form[6] = forms.label(form[1],"Top Fit: ",5,60)
	form[7] = forms.button(form[1], "Reset Pool", function () pool.reset = true end,5,110)
	
	function isGUIChecked() return forms.ischecked(form[3]) end
	function updateForm(pool) forms.settext(form[4],"Generation: "..pool.generation);forms.settext(form[5],"Progress: "..math.floor(pool.progression / Population * 100).."%");forms.settext(form[6],"Top Fit: "..pool.maxFitness) end
	return form
end

function logPool(pool)
	console.log("Gen:"..pool.generation.." #S:"..#pool.species.." maxF:"..pool.maxFitness..string.format(" t:%d",(os.clock() - pool.time)))
end

function mainLoop(level, pool)
	client.speedmode(6399)
	local genome = nil
	while true do
		if pool.reset then
			console.clear()
			console.writeline("----------NEW SESSION----------")
			pool = initalizePool()
			onExit()
			createForm(level,pool)
			client.speedmode(6399)
		end
		if pool.playTop then
			pool.playTop = false
			playTop(level,pool)
		end
		genome = getNextGenome(pool)
		fit = genome.fitness
		testGenome(level, pool, genome)
		if fit ~= 0 and fit ~= genome.fitness then
			debugID = genome.id
			debugFail = true
			testGenome(level,pool,genome)
			if fit ~= genome.fitness then
				error("Genome Degen: ID: "..genome.id.. " Fit: "..fit.." NFit: "..genome.fitness)
			end
			debugFail = false
		end
		if pool.maxFitness < genome.fitness then
			pool.maxFitness = genome.fitness
		end
		updateForm(pool)
		updatePoolState(PoolStateName,genome)
	end
end
-- TODO: fix error with breeding not allowing top fitness genome to continue through generations, fix top play, put level into pool?
console.clear()
forms.destroyall()
console.writeline("----------NEW SESSION----------")

debugLastNetwork = nil
debugFail = false
debugID = -1
level = loadLevel(LevelName)
pool = nil
pool = loadPoolState(PoolStateName)
if pool == nil then pool = initalizePool() end
event.onexit(onExit)
noError, message = pcall(mainLoop(level, pool))
console.log("Caught:")
console.log(message)
onExit()
