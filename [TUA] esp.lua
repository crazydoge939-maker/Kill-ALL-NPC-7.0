-- ==================== НАЧАЛО ====================
getgenv().G = true
getgenv().Creator = 'https://discord.gg/B3HqPPzFYr - HalloweenGaster'

local runService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== ОСНОВНЫЕ ПЕРЕМЕННЫЕ ====================
local isKilling = false
local killInterval = 3
local lastKillTime = 0
local npcKillQueue = {}
local MAX_NPCS_PER_CYCLE = 1
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
local doNotKillList = {
    ["Necromancer"] = true,
}
local specialNPCs = {
    ["Undead Tank"] = true,
}

local npcHighlights = {}
local npcNameGuis = {}
local npcCycles = {}
local npcOriginalNames = {}
local npcKnownObjects = {}
local npcDisplayStates = {}
local npcAppearanceTimes = {}
local isEnabled = true

local toggleScript = true -- для включения/выключения основного цикла

-- ==================== ФУНКЦИИ ====================

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
    if ignoreList[npc.Name] then return false end
    local playerCharacter = LocalPlayer.Character
    if not playerCharacter then return false end
    local playerHrp = playerCharacter:FindFirstChild("HumanoidRootPart")
    local npcHrp = npc:FindFirstChild("HumanoidRootPart")
    if not playerHrp or not npcHrp then return false end
    playerHrp.CFrame = npcHrp.CFrame + Vector3.new(0, 3, 0)
    print("[Auto Killer] Телепортировался к NPC: " .. npc.Name)
    return true
end

local function killNpc(npc)
    if not isNpcAlive(npc) then return end
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if humanoid then
        humanoid.Health = 0
        humanoid.MaxHealth = 0
    end
    if hrp then
        hrp:BreakJoints()
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

-- ==================== GUI ====================
local function createGui()
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
    teleportDelayDropdown.Text = tostring(3) .. " сек"
    teleportDelayDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportDelayDropdown.Font = Enum.Font.Gotham
    teleportDelayDropdown.TextSize = 14
    teleportDelayDropdown.Parent = teleportDelaySettings

    local teleportDelayCorner = Instance.new("UICorner")
    teleportDelayCorner.CornerRadius = UDim.new(0, 6)
    teleportDelayCorner.Parent = teleportDelayDropdown

    local delayOptions = {0.5, 1, 2, 3, 4, 5}
    local currentDelayIndex = 4 -- по умолчанию 3 сек

    local TELEPORT_DELAY = delayOptions[currentDelayIndex]

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

    -- ==================== Кнопки ====================
    local function toggleKilling()
        isKilling = not isKilling
        if isKilling then
            ToggleButton.Text = "[Stop] Kill"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            lastKillTime = tick()
            enqueueNpcsToKill()
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

    toggleModeButton.MouseButton1Click = toggleMode
end

createGui()

local function updateHighlights()
    for _, npc in pairs(findHumanoids()) do
        if isNpcAlive(npc) then
            if not npcHighlights[npc] and not ignoreList[npc.Name] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "AutoKillHighlight"
                highlight.Adornee = npc
                highlight.Enabled = isEnabled
                local color = getNpcColor(npc.Name)
                if color then
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
                npcHighlights[npc] = highlight
            else
                if npcHighlights[npc] then
                    npcHighlights[npc].Enabled = isEnabled
                end
            end
        end
    end
    -- Удаление тех, кто умер
    for npc, highlight in pairs(npcHighlights) do
        if not isNpcAlive(npc) then
            if highlight then
                highlight:Destroy()
            end
            npcHighlights[npc] = nil
        end
    end
end

local function getNpcCyclePercentage(npc)
    if not npc then return 0 end
    local cycle = npcCycles[npc] or 0
    local maxCycle = 10 -- или другая ваша константа
    return math.min(math.floor((cycle / maxCycle) * 100), 100)
end

local function updateNpcCycleDisplay(npc)
    if ignoreList[npc.Name] then return end
    local cycleLabel = npcCycleLabels[npc]
    if cycleLabel and npcCycles[npc] ~= nil then
        local percentage = getNpcCyclePercentage(npc)
        cycleLabel.Text = "[" .. percentage .. "%]"
        if npcCycles[npc] >= 10 then
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

local function checkAndUpdateNpcs()
    local npcs = findHumanoids()
    for _, npc in pairs(npcs) do
        if npc and isNpcAlive(npc) then
            if not npcHighlights[npc] and not ignoreList[npc.Name] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "AutoKillHighlight"
                highlight.Adornee = npc
                highlight.Enabled = isEnabled
                local color = getNpcColor(npc.Name)
                if color then
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
                npcHighlights[npc] = highlight
            else
                if npcHighlights[npc] then
                    npcHighlights[npc].Enabled = isEnabled
                end
            end
        end
    end
end

local function updateKillCount()
    -- Тут ваш код для отображения количества жертв
end

local function mainLoop()
    while true do
        if toggleScript then
            if isKilling then
                local currentTime = tick()
                local elapsed = currentTime - lastKillTime
                local progress = math.min(elapsed / killInterval, 1)
                _G.ProgressBar.Size = UDim2.new(progress, 0, 1, 0)
                if elapsed >= killInterval then
                    enqueueNpcsToKill()
                    processKillQueue()
                    lastKillTime = currentTime
                    updateKillCount()
                end
            else
                _G.ProgressBar.Size = UDim2.new(0, 0, 1, 0)
            end

            if isEnabled then
                updateHighlights()
            end
        end
        wait(0.1)
    end
end

coroutine.wrap(mainLoop)()

-- ==================== ВКЛЮЧЕНИЕ/ВЫКЛЮЧЕНИЕ ====================
local function toggleScriptState()
    toggleScript = not toggleScript
    if toggleScript then
        print("Скрипт включен")
    else
        print("Скрипт выключен")
    end
end

-- Можно добавить горячие клавиши или другой способ управления
-- Например:
-- game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
-- 	if input.KeyCode == Enum.KeyCode.P then
-- 		toggleScriptState()
-- 	end
-- end)

-- ==================== ИТОГО ====================
-- В этом коде объединены ваши функции, добавлены GUI и управление
-- Настраивайте переменные и интерфейс по необходимости.
