
-- Основные переменные
local isKilling = false
local killInterval = 5
local lastKillTime = 0
local runService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Создаем GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KillerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 300)
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
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 120, 0, 35)
ToggleButton.Position = UDim2.new(0, 20, 0, 50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 16
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "Start Kill"
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = ToggleButton
ToggleButton.Parent = Frame

local KillCountLabel = Instance.new("TextLabel")
KillCountLabel.Size = UDim2.new(1, -40, 0, 120)
KillCountLabel.Position = UDim2.new(0, 20, 0, 95)
KillCountLabel.BackgroundTransparency = 1
KillCountLabel.Text = "Жертвы:\n"
KillCountLabel.TextWrapped = true
KillCountLabel.TextXAlignment = Enum.TextXAlignment.Left
KillCountLabel.TextYAlignment = Enum.TextYAlignment.Top
KillCountLabel.Font = Enum.Font.Gotham
KillCountLabel.TextSize = 20
KillCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
KillCountLabel.Parent = Frame

-- Линия прогресса расположена ниже логов
local ProgressBackground = Instance.new("Frame")
ProgressBackground.Size = UDim2.new(1, -40, 0, 10)
ProgressBackground.Position = UDim2.new(0, 20, 0, 270)
ProgressBackground.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ProgressBackground.BorderSizePixel = 0
local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 5)
progressCorner.Parent = ProgressBackground
ProgressBackground.Parent = Frame

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
ProgressBar.BorderSizePixel = 0
local progressInnerCorner = Instance.new("UICorner")
progressInnerCorner.CornerRadius = UDim.new(0, 5)
ProgressBar.Parent = ProgressBackground

local function toggleKilling()
	isKilling = not isKilling
	if isKilling then
		ToggleButton.Text = "Stop Kill"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		lastKillTime = tick()
	else
		ToggleButton.Text = "Start Kill"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	end
end

ToggleButton.MouseButton1Click:Connect(toggleKilling)

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

local npcHighlights = {} -- таблица для хранения подсветки всех NPC

local function updateHighlights()
	local npcs = findHumanoids()
	for _, npc in pairs(npcs) do
		if npc then
			local highlight = npcHighlights[npc]
			if not highlight then
				highlight = Instance.new("Highlight")
				highlight.Name = "Highlight"
				highlight.Adornee = npc
				highlight.FillColor = Color3.fromRGB(85, 0, 0)
				highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
				highlight.Parent = npc
				npcHighlights[npc] = highlight
			end
			highlight.Enabled = true
		end
	end
end

local lineFolder = Instance.new("Folder", workspace)
lineFolder.Name = "PlayerToNPCLines"

local function createLine()
	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")

	attachment0.Parent = workspace
	attachment1.Parent = workspace

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.Transparency = NumberSequence.new(0.5)
	beam.Parent = lineFolder

	return {
		Beam = beam,
		Attachment0 = attachment0,
		Attachment1 = attachment1,
		TargetPos0 = Vector3.new(), -- целевая позиция для Attachment0
		TargetPos1 = Vector3.new()  -- целевая позиция для Attachment1
	}
end

-- Функция проверки, жив ли NPC
local function isNpcAlive(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	return humanoid and humanoid.Health > 0 and hrp
end

local npcLines = {}
local smoothingFactor = 1 -- Чем меньше, тем медленнее перемещение (плавнее)

local function updateLines()
	local playerCharacter = LocalPlayer.Character
	if not playerCharacter then return end
	local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local playerPos = hrp.Position

	for npc, highlight in pairs(npcHighlights) do
		if highlight.Enabled then
			if isNpcAlive(npc) then
				local lineData = npcLines[npc]
				if not lineData then
					lineData = createLine()
					npcLines[npc] = lineData
				end
				-- Обновляем целевые позиции
				lineData.TargetPos0 = playerPos
				local npcHrp = npc:FindFirstChild("HumanoidRootPart")
				if npcHrp then
					lineData.TargetPos1 = npcHrp.Position
				end
				-- Плавное перемещение Attachment к целевым позициям
				local currentPos0 = lineData.Attachment0.WorldPosition
				local newPos0 = currentPos0:Lerp(lineData.TargetPos0, smoothingFactor)
				lineData.Attachment0.WorldPosition = newPos0

				local currentPos1 = lineData.Attachment1.WorldPosition
				local newPos1 = currentPos1:Lerp(lineData.TargetPos1, smoothingFactor)
				lineData.Attachment1.WorldPosition = newPos1
			else
				-- NPC умер или исчез — удаляем линию и подсветку
				if npcLines[npc] then
					npcLines[npc].Beam:Destroy()
					npcLines[npc].Attachment0:Destroy()
					npcLines[npc].Attachment1:Destroy()
					npcLines[npc] = nil
				end
				if npcHighlights[npc] then
					npcHighlights[npc].Enabled = false
				end
			end
		else
			-- подсветка отключена, удаляем линию
			if npcLines[npc] then
				npcLines[npc].Beam:Destroy()
				npcLines[npc].Attachment0:Destroy()
				npcLines[npc].Attachment1:Destroy()
				npcLines[npc] = nil
			end
		end
	end

	-- Удаляем линии для NPC, которых больше нет или не подсвечены
	for npc, lineData in pairs(npcLines) do
		if not npcHighlights[npc] or not npcHighlights[npc].Enabled then
			lineData.Beam:Destroy()
			lineData.Attachment0:Destroy()
			lineData.Attachment1:Destroy()
			npcLines[npc] = nil
		end
	end
end

local function removeLine(npc)
	local lineData = npcLines[npc]
	if lineData then
		lineData.Beam:Destroy()
		lineData.Attachment0:Destroy()
		lineData.Attachment1:Destroy()
		npcLines[npc] = nil
	end
end

-- Постоянное обновление подсветки
coroutine.wrap(function()
	while true do
		wait(1)
		updateHighlights()
		updateLines()
	end
end)()

local killedHumanoidsCount = {}

local function updateKillCount()
	killedHumanoidsCount = {}
	for _, npc in pairs(findHumanoids()) do
		local name = npc.Name
		if killedHumanoidsCount[name] then
			killedHumanoidsCount[name] = killedHumanoidsCount[name] + 1
		else
			killedHumanoidsCount[name] = 1
		end
	end
	local displayText = "Жертвы:\n"
	for name, count in pairs(killedHumanoidsCount) do
		displayText = displayText .. name
		if count > 1 then
			displayText = displayText .. " x" .. count
		end
		displayText = displayText .. "\n"
	end
	KillCountLabel.Text = displayText
end

coroutine.wrap(function()
	while true do
		wait(0.5)
		updateKillCount()
	end
end)()

local function killMovingHumanoids()
	local npcs = findHumanoids()
	for _, npc in pairs(npcs) do
		if isNpcAlive(npc) then
			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			local hrp = npc:FindFirstChild("HumanoidRootPart")
			local velocity = hrp.AssemblyLinearVelocity
			local speed = velocity.Magnitude
			if speed > 1 then
				local highlight = npcHighlights[npc]
				if highlight then
					highlight.Enabled = true
				end
				humanoid.Health = 0
				-- удаляем линию сразу после убийства
				if npcLines[npc] then
					npcLines[npc].Beam:Destroy()
					npcLines[npc].Attachment0:Destroy()
					npcLines[npc].Attachment1:Destroy()
					npcLines[npc] = nil
				end
			end
		end
	end
end

-- Основной цикл
runService.Heartbeat:Connect(function()
	if isKilling then
		local currentTime = tick()
		local elapsed = currentTime - lastKillTime
		local progress = math.min(elapsed / killInterval, 1)
		ProgressBar.Size = UDim2.new(progress, 0, 1, 0)

		if elapsed >= killInterval then
			killMovingHumanoids()
			lastKillTime = currentTime
			updateKillCount()
		end
	else
		ProgressBar.Size = UDim2.new(0, 0, 1, 0)
	end

	local playerCharacter = LocalPlayer.Character
	if not playerCharacter then return end
	local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local playerPos = hrp.Position

	for npc, highlight in pairs(npcHighlights) do
		if highlight.Enabled then
			if isNpcAlive(npc) then
				local lineData = npcLines[npc]
				if not lineData then
					lineData = createLine()
					npcLines[npc] = lineData
				end
				-- Обновляем целевые позиции
				lineData.TargetPos0 = playerPos
				local npcHrp = npc:FindFirstChild("HumanoidRootPart")
				if npcHrp then
					lineData.TargetPos1 = npcHrp.Position
				end
				-- Плавное перемещение Attachment к целевым позициям
				local currentPos0 = lineData.Attachment0.WorldPosition
				local newPos0 = currentPos0:Lerp(lineData.TargetPos0, smoothingFactor)
				lineData.Attachment0.WorldPosition = newPos0

				local currentPos1 = lineData.Attachment1.WorldPosition
				local newPos1 = currentPos1:Lerp(lineData.TargetPos1, smoothingFactor)
				lineData.Attachment1.WorldPosition = newPos1
			else
				-- NPC умер или исчез — удаляем линию и подсветку
				if npcLines[npc] then
					npcLines[npc].Beam:Destroy()
					npcLines[npc].Attachment0:Destroy()
					npcLines[npc].Attachment1:Destroy()
					npcLines[npc] = nil
				end
				if npcHighlights[npc] then
					npcHighlights[npc].Enabled = false
				end
			end
		else
			-- подсветка отключена, удаляем линию
			if npcLines[npc] then
				npcLines[npc].Beam:Destroy()
				npcLines[npc].Attachment0:Destroy()
				npcLines[npc].Attachment1:Destroy()
				npcLines[npc] = nil
			end
		end
	end

	-- Удаляем линии для NPC, которых больше нет или не подсвечены
	for npc, lineData in pairs(npcLines) do
		if not npcHighlights[npc] or not npcHighlights[npc].Enabled then
			lineData.Beam:Destroy()
			lineData.Attachment0:Destroy()
			lineData.Attachment1:Destroy()
			npcLines[npc] = nil
		end
	end
end)

-- Перетаскивание GUI
local dragging = false
local dragStart
local startPos

Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
	end
end)

Frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

Frame.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		Frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
	end
end)
