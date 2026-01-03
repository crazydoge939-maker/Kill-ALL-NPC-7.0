
-- ==================== ОСНОВНЫЕ ПЕРЕМЕННЫЕ ====================
local isKilling = false
local killInterval = 3
local lastKillTime = 0
local runService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== НАСТРОЙКИ ====================
local MAX_CYCLES = 0 -- Сколько циклов NPC должен выжить перед смертью
local TELEPORT_DELAY = 2 -- Увеличено время между телепортами, чтобы снизить нагрузку
local npcKillQueue = {} -- очередь для порционной убийства
local MAX_NPCS_PER_CYCLE = 1 -- максимальное число NPC за раз

-- ==================== СПИСКИ NPC ====================
-- NPC, которых не нужно убивать
local doNotKillList = {
	["Necromancer"] = true,
}

-- Особые NPC (желтая подсветка)
local specialNPCs = {
	["Undead Tank"] = true,
}

-- ==================== СПИСОК ИГНОРА ====================
local ignoreList = {
	["Hivemind Hologram"] = true,
	["DEADFace"] = true,
	["ULTRAOPAMOGUS"] = true,
	["TrollgeKing"] = true,
	["Derp"] = true,
	["Le true venus:2"] = true,
	["Arena Knight"] = true,
	["Grand Knight"] = true,
	["BUFFNeckTrollge"] = true,
	["Knight"] = true,
	["Mystery"] = true,
	["Shopkeeper"] = true,
	["Trollge"] = true,
}

-- ==================== ТАБЛИЦЫ ОТСЛЕЖИВАНИЯ ====================
local npcAppearanceTimes = {} -- {["NPCName"] = time}
local npcDisplayStates = {} -- {["NPCName"] = {type="green"|"yellow", time=timestamp}}
local npcNameGuis = {} -- {npc = BillboardGui}
local npcCycleLabels = {} -- {npc = TextLabel}
local npcCycles = {} -- {npc = currentCycle}
local npcOriginalNames = {} -- {npc = originalName}
local npcKnownObjects = {} -- {["NPCName"] = {npc1, npc2, ...}}
local npcHighlights = {} -- {npc = Highlight}
local isEnabled = true -- включено/выключено
local lastTeleportTime = 0 -- время последней телепортации

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
local function getNpcColor(npcName)
	if ignoreList[npcName] then
		return nil
	end
	if doNotKillList[npcName] then
		return Color3.fromRGB(0, 255, 0)
	elseif specialNPCs[npcName] then
		return Color3.fromRGB(255, 255, 0)
	else
		return Color3.fromRGB(255, 0, 0)
	end
end

-- ==================== СОЗДАНИЕ GUI ====================
local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KillerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 460)
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UIStroke = Instance.new("UICorner")
UIStroke.CornerRadius = UDim.new(0, 12)
UIStroke.Parent = Frame

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 54, 62)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 34, 42))
}
UIGradient.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Auto Killer"
Title.Font = Enum.Font.Sarpanch
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 120, 0, 40)
ToggleButton.Position = UDim2.new(0, 20, 0, 50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ToggleButton.Font = Enum.Font.Sarpanch
ToggleButton.TextSize = 16
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "[Start] Kill"
ToggleButton.Parent = Frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = ToggleButton

local KillCountLabel = Instance.new("TextLabel")
KillCountLabel.Size = UDim2.new(1, -40, 0, 430)
KillCountLabel.Position = UDim2.new(0, 20, 0, 100)
KillCountLabel.BackgroundTransparency = 1
KillCountLabel.Text = "Жертвы:\n"
KillCountLabel.TextWrapped = true
KillCountLabel.TextXAlignment = Enum.TextXAlignment.Left
KillCountLabel.TextYAlignment = Enum.TextYAlignment.Top
KillCountLabel.Font = Enum.Font.Sarpanch
KillCountLabel.TextSize = 22
KillCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
KillCountLabel.Parent = Frame

local toggleModeButton = Instance.new("TextButton")
toggleModeButton.Size = UDim2.new(0, 120, 0, 40)
toggleModeButton.Position = UDim2.new(0, 150, 0, 50)
toggleModeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
toggleModeButton.Font = Enum.Font.Sarpanch
toggleModeButton.TextSize = 16
toggleModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleModeButton.Text = "[OFF] Подсветку"
toggleModeButton.Parent = Frame

local buttonCorner2 = Instance.new("UICorner")
buttonCorner2.CornerRadius = UDim.new(0, 8)
buttonCorner2.Parent = toggleModeButton

local teleportDelaySettings = Instance.new("Frame")
teleportDelaySettings.Size = UDim2.new(1, -40, 0, 60)
teleportDelaySettings.Position = UDim2.new(0, 20, 0, 340)
teleportDelaySettings.BackgroundTransparency = 1
teleportDelaySettings.Parent = Frame

local teleportDelayLabel = Instance.new("TextLabel")
teleportDelayLabel.Size = UDim2.new(1, 0, 0, 20)
teleportDelayLabel.Position = UDim2.new(0, 0, 0, 55)
teleportDelayLabel.BackgroundTransparency = 1
teleportDelayLabel.Text = "Задержка между TP:"
teleportDelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
teleportDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
teleportDelayLabel.Font = Enum.Font.Gotham
teleportDelayLabel.TextSize = 14
teleportDelayLabel.Parent = teleportDelaySettings

local teleportDelayDropdown = Instance.new("TextButton")
teleportDelayDropdown.Size = UDim2.new(1, 0, 0, 30)
teleportDelayDropdown.Position = UDim2.new(0, 0, 0, 75)
teleportDelayDropdown.BackgroundColor3 = Color3.fromRGB(60, 64, 72)
teleportDelayDropdown.Text = tostring(TELEPORT_DELAY) .. " сек"
teleportDelayDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportDelayDropdown.Font = Enum.Font.Gotham
teleportDelayDropdown.TextSize = 14
teleportDelayDropdown.Parent = teleportDelaySettings

local teleportDelayCorner = Instance.new("UICorner")
teleportDelayCorner.CornerRadius = UDim.new(0, 6)
teleportDelayCorner.Parent = teleportDelayDropdown

local delayOptions = {0.5, 1, 2, 3, 4, 5}
local currentDelayIndex = 3

teleportDelayDropdown.MouseButton1Click:Connect(function()
	currentDelayIndex = currentDelayIndex + 1
	if currentDelayIndex > #delayOptions then
		currentDelayIndex = 1
	end
	TELEPORT_DELAY = delayOptions[currentDelayIndex]
	teleportDelayDropdown.Text = tostring(TELEPORT_DELAY) .. " сек"
end)

local ProgressBackground = Instance.new("Frame")
ProgressBackground.Size = UDim2.new(1, -40, 0, 10)
ProgressBackground.Position = UDim2.new(0, 20, 0, 30)
ProgressBackground.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ProgressBackground.BorderSizePixel = 0
ProgressBackground.Parent = Frame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 5)
progressCorner.Parent = ProgressBackground

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressBackground

local progressInnerCorner = Instance.new("UICorner")
progressInnerCorner.CornerRadius = UDim.new(0, 5)
progressInnerCorner.Parent = ProgressBar

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
local function createNpcGui(npc)
	local npcColor = getNpcColor(npc.Name)
	if ignoreList[npc.Name] then return end
	if not npcColor then return end -- Не создаем GUI, если NPC в игнор-листе
	-- Создание GUI для NPC (если нужно)
	-- Можно оставить пустым или закомментировать, чтобы не отображалось
end

local function updateNpcCycleDisplay(npc)
	if ignoreList[npc.Name] then return end
	local cycleLabel = npcCycleLabels[npc]
	if cycleLabel and npcCycles[npc] ~= nil then
		local percentage = math.min(math.floor((npcCycles[npc] / MAX_CYCLES) * 100), 100)
		cycleLabel.Text = "[" .. percentage .. "%]"
		if npcCycles[npc] >= MAX_CYCLES - 1 then
			cycleLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			local textLabel = cycleLabel.Parent and cycleLabel.Parent:FindFirstChildOfClass("TextLabel")
			if textLabel then
				textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			end
			local bgFrame = cycleLabel.Parent
			if bgFrame and bgFrame:FindFirstChild("UIStroke") then
				bgFrame.UIStroke.Color = Color3.fromRGB(255, 50, 50)
			end
		end
	end
end

-- ==================== ФУНКЦИИ ПОДСВЕТКИ ====================
local function createHighlight(npc)
	if ignoreList[npc.Name] then return nil end -- пропускаем
	local highlight = Instance.new("Highlight")
	highlight.Name = "AutoKillHighlight"
	highlight.Adornee = npc
	highlight.Enabled = isEnabled

	local npcColor = getNpcColor(npc.Name)
	if npcColor then
		if doNotKillList[npc.Name] then
			highlight.FillColor = Color3.fromRGB(0, 85, 0)
			highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
		elseif specialNPCs[npc.Name] then
			highlight.FillColor = Color3.fromRGB(255, 170, 0)
			highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
		else
			highlight.FillColor = Color3.fromRGB(85, 0, 0)
			highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		end
	end

	if not isEnabled then
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 1
	else
		highlight.FillTransparency = 0
		highlight.OutlineTransparency = 0
	end

	highlight.Parent = npc
	return highlight
end

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
local function findHumanoids()
	local npcs = {}
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("Humanoid") and v.Parent and v.Parent:FindFirstChildOfClass("Humanoid") then
			if not game.Players:GetPlayerFromCharacter(v.Parent) then
				table.insert(npcs, v.Parent)
			end
		end
	end
	return npcs
end

local function isNpcAlive(npc)
	if not npc then return false end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	return humanoid ~= nil and humanoid.Health > 0 and hrp ~= nil
end

local function getPlayerPosition()
	local playerCharacter = LocalPlayer.Character
	if playerCharacter then
		local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
		if hrp then
			return hrp.Position
		end
	end
	return nil
end

local function teleportToNpc(npc)
	if ignoreList[npc.Name] then return false end -- пропускаем
	local playerCharacter = LocalPlayer.Character
	if not playerCharacter then return false end

	local playerHrp = playerCharacter:FindFirstChild("HumanoidRootPart")
	local npcHrp = npc:FindFirstChild("HumanoidRootPart")
	if not playerHrp or not npcHrp then return false end

	playerHrp.CFrame = npcHrp.CFrame + Vector3.new(0, 3, 0)
	print("[Auto Killer] Телепортировался к NPC: " .. npc.Name)
	return true
end

local function cleanupNpcData(npc)
	if npcHighlights[npc] then
		npcHighlights[npc]:Destroy()
		npcHighlights[npc] = nil
	end
	if npcNameGuis[npc] then
		npcNameGuis[npc]:Destroy()
		npcNameGuis[npc] = nil
	end
	npcCycles[npc] = nil
	npcOriginalNames[npc] = nil
	local npcName = npc.Name
	if npcKnownObjects[npcName] then
		for i, obj in ipairs(npcKnownObjects[npcName]) do
			if obj == npc then
				table.remove(npcKnownObjects[npcName], i)
				break
			end
		end
		if #npcKnownObjects[npcName] == 0 then
			npcKnownObjects[npcName] = nil
		end
	end
end

local function killNpc(npc)
	if not isNpcAlive(npc) then return end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

local function onNpcTouched(npc, otherPart)
	if not otherPart then return end
	local character = otherPart.Parent
	if character and character:FindFirstChildOfClass("Humanoid") and character.Parent == LocalPlayer.Character then
		if isNpcAlive(npc) and not doNotKillList[npc.Name] and not ignoreList[npc.Name] then
			killNpc(npc)
			print("[Auto Killer] NPC убит при касании: " .. npc.Name)
		end
	end
end

local function connectTouchedEvent(npc)
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if hrp and not hrp:GetAttribute("TouchedConnected") then
		hrp:GetAttribute("TouchedConnected", true)
		hrp.Touched:Connect(function(otherPart)
			onNpcTouched(npc, otherPart)
		end)
	end
end

local function checkForNewNpcs()
	local npcs = findHumanoids()

	for _, npc in pairs(npcs) do
		if npc and isNpcAlive(npc) then
			local npcName = npc.Name
			if not npcKnownObjects[npcName] then
				npcKnownObjects[npcName] = {}
			end
			local isNew = true
			for _, existingNpc in ipairs(npcKnownObjects[npcName]) do
				if existingNpc == npc then
					isNew = false
					break
				end
			end
			if isNew then
				table.insert(npcKnownObjects[npcName], npc)
				if npcHighlights[npc] then
					cleanupNpcData(npc)
				end
				if not npcHighlights[npc] then
					npcHighlights[npc] = createHighlight(npc)
				end
				if not npcNameGuis[npc] then
					createNpcGui(npc)
				end
				-- подключаем касание
				connectTouchedEvent(npc)
			end
		end
	end
end

local function updateHighlights()
	local npcs = findHumanoids()
	checkForNewNpcs()
	for _, npc in pairs(npcs) do
		if npc and isNpcAlive(npc) then
			-- Создаем подсветку только если не в игнор-листе
			if not npcHighlights[npc] and not ignoreList[npc.Name] then
				npcHighlights[npc] = createHighlight(npc)
			end
			-- Создаем GUI только если не в игнор-листе
			if not npcNameGuis[npc] and not ignoreList[npc.Name] then
				createNpcGui(npc)
			end
			if npcHighlights[npc] then
				npcHighlights[npc].Enabled = isEnabled
			end
			if npcNameGuis[npc] then
				npcNameGuis[npc].Enabled = isEnabled
			end
		end
	end
	for npc, highlight in pairs(npcHighlights) do
		if not isNpcAlive(npc) then
			highlight.Enabled = false
			cleanupNpcData(npc)
		end
	end
	for npc, gui in pairs(npcNameGuis) do
		if not isNpcAlive(npc) then
			gui.Enabled = false
		end
	end
end

local function enqueueNpcsToKill()
	local npcs = findHumanoids()
	for _, npc in ipairs(npcs) do
		if isNpcAlive(npc) and not doNotKillList[npc.Name] and not ignoreList[npc.Name] then
			table.insert(npcKillQueue, npc)
		end
	end
end

local function processKillQueue()
	local count = 0
	for i = #npcKillQueue, 1, -1 do
		local npc = npcKillQueue[i]
		if isNpcAlive(npc) then
			if teleportToNpc(npc) then
				wait(0.1)
				killNpc(npc)
			end
		end
		table.remove(npcKillQueue, i)
		count = count + 1
		if count >= MAX_NPCS_PER_CYCLE then
			break
		end
	end
end

-- ==================== ОБНОВЛЕНИЕ СЧЕТЧИКА ====================
KillCountLabel.RichText = true
local previousCount = {}

local function updateKillCount()
	local killedHumanoidsCount = {}
	local currentTime = tick()
	local currentNPCs = {}
	for _, npc in pairs(findHumanoids()) do
		local name = npc.Name
		if ignoreList[name] then
			continue
		end
		currentNPCs[name] = true
		if not npcDisplayStates[name] then
			npcDisplayStates[name] = {type = "green", time = currentTime}
		end
		killedHumanoidsCount[name] = (killedHumanoidsCount[name] or 0) + 1
	end
	for name, _ in pairs(previousCount) do
		if not currentNPCs[name] then
			npcDisplayStates[name] = nil
		end
	end
	for name, count in pairs(killedHumanoidsCount) do
		if not previousCount[name] then
			npcDisplayStates[name] = {type = "green", time = currentTime}
		elseif count ~= previousCount[name] then
			npcDisplayStates[name] = {type = "yellow", time = currentTime}
		end
	end
	previousCount = table.clone(killedHumanoidsCount)
	local displayText = "Жертвы:\n"
	for name, count in pairs(killedHumanoidsCount) do
		local state = npcDisplayStates[name]
		local elapsed = currentTime - (state and state.time or currentTime)
		local progress = math.clamp(elapsed / 10, 0, 1)
		local color
		if state then
			if state.type == "green" then
				color = string.format('rgb(%d,%d,%d)', math.floor(0 + 255 * progress), 255, math.floor(0 + 255 * progress))
			elseif state.type == "yellow" then
				color = string.format('rgb(255,255,%d)', math.floor(255 * progress))
			end
		else
			color = 'rgb(255,255,255)'
		end
		local countSuffix = ""
		if count > 1 then
			countSuffix = " x" .. tostring(count)
		end
		if ignoreList[name] then
			continue
		end
		displayText = displayText .. string.format('<font color="%s">%s%s</font>\n', color, name, countSuffix)
	end
	KillCountLabel.Text = displayText
end

-- ==================== ПЕРЕКЛЮЧЕНИЕ РЕЖИМА ====================
local function toggleKilling()
	isKilling = not isKilling
	if isKilling then
		ToggleButton.Text = "[Stop] Kill"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		lastKillTime = tick()
		enqueueNpcsToKill() -- Заранее заполняем очередь
	else
		ToggleButton.Text = "[Start] Kill"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	end
end

ToggleButton.MouseButton1Click:Connect(toggleKilling)

local function toggleMode()
	isEnabled = not isEnabled
	if isEnabled then
		toggleModeButton.Text = "[OFF] Подсветку"
		toggleModeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		for _, highlight in pairs(npcHighlights) do
			if highlight then
				highlight.FillTransparency = 0
				highlight.OutlineTransparency = 0
				highlight.Enabled = true
			end
		end
	else
		toggleModeButton.Text = "[ON] Подсветку"
		toggleModeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		for _, highlight in pairs(npcHighlights) do
			if highlight then
				highlight.FillTransparency = 1
				highlight.OutlineTransparency = 1
				highlight.Enabled = false
			end
		end
	end
end

toggleModeButton.MouseButton1Click:Connect(toggleMode)

-- ==================== ОСНОВНОЙ ЦИКЛ ====================
runService.Heartbeat:Connect(function()
	if isKilling then
		local currentTime = tick()
		local elapsed = currentTime - lastKillTime
		local progress = math.min(elapsed / killInterval, 1)
		ProgressBar.Size = UDim2.new(progress, 0, 1, 0)
		if elapsed >= killInterval then
			enqueueNpcsToKill()
			processKillQueue()
			lastKillTime = currentTime
			updateKillCount()
		end
	else
		ProgressBar.Size = UDim2.new(0, 0, 1, 0)
	end

	local playerPos = getPlayerPosition()
	if playerPos then
		for npc, highlight in pairs(npcHighlights) do
			if isNpcAlive(npc) and highlight.Enabled then
				-- Линии убраны
			else
				if npcHighlights[npc] then
					npcHighlights[npc]:Destroy()
					npcHighlights[npc] = nil
				end
			end
		end
	end
end)

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ====================
coroutine.wrap(function()
	while true do
		wait(1)
		updateHighlights()
	end
end)()

coroutine.wrap(function()
	while true do
		wait(0.5)
		updateKillCount()
	end
end)()
