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
Frame.Size = UDim2.new(0, 300, 0, 250)
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
KillCountLabel.Text = "Victims:\n"
KillCountLabel.TextWrapped = true
KillCountLabel.TextXAlignment = Enum.TextXAlignment.Left
KillCountLabel.TextYAlignment = Enum.TextYAlignment.Top
KillCountLabel.Font = Enum.Font.Gotham
KillCountLabel.TextSize = 20
KillCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
KillCountLabel.Parent = Frame

local ProgressBackground = Instance.new("Frame")
ProgressBackground.Size = UDim2.new(1, -40, 0, 10)
ProgressBackground.Position = UDim2.new(0, 20, 0, 230)
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
        ToggleButton.Text = "Stop"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        lastKillTime = tick() -- чтобы начать отсчет сразу после запуска
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

local function highlightNPC(npc)
    if not npc then return end
    local highlight = npc:FindFirstChild("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Highlight"
        highlight.Adornee = npc
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.Parent = npc
    end
    highlight.Enabled = true
end

local function removeHighlight(npc)
    if npc then
        local highlight = npc:FindFirstChild("Highlight")
        if highlight then
            highlight.Enabled = false
        end
    end
end

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

-- Новая функция: телепортировать к случайному NPC, убить всех и телепортировать игрока чуть дальше
local function teleportAndKillAllNPCs()
    local npcs = findHumanoids()
    if #npcs == 0 then return end
    local npc = npcs[math.random(1, #npcs)]
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    local playerChar = LocalPlayer.Character
    local playerHRP = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
    if not hrp or not playerHRP then return end

    -- Расчет позиции для телепортации чуть дальше от NPC
    local npcPos = hrp.Position
    local playerPos = playerHRP.Position
    local direction = (playerPos - npcPos).unit
    local teleportDistance = 10 -- дистанция, на которую телепортируемся дальше
    local newPlayerPos = npcPos + direction * teleportDistance + Vector3.new(0, 3, 0)

    -- Телепортируем игрока
    playerHRP.CFrame = CFrame.new(newPlayerPos)

    -- Убиваем всех NPC
    for _, npcToKill in pairs(findHumanoids()) do
        local humanoid = npcToKill:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            highlightNPC(npcToKill)
            humanoid.Health = 0
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
            -- Каждые killInterval секунд телепортируемся и убиваем всех NPC
            teleportAndKillAllNPCs()
            lastKillTime = currentTime
            updateKillCount()
        end
    else
        ProgressBar.Size = UDim2.new(0, 0, 1, 0)
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
