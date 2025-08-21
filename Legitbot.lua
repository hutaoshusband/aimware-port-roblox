-- ##################################################################################
-- # Legitbot.lua - Version 11 (Mit integriertem AutoFire)
-- # Dieses Skript wird von main.lua geladen und fÃ¼llt NUR den Legitbot-Tab.
-- # Es enthÃ¤lt die Aimbot-Logik und die UI-Elemente fÃ¼r diesen spezifischen Tab.
-- ##################################################################################

-- #####################################################################
-- # 1. GLOBALE SERVICES UND KONFIGURATION
-- #####################################################################
local PLAYER = game:GetService("Players").LocalPlayer
local CurrentCam = game:GetService("Workspace").CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Diese globale Tabelle speichert den Zustand aller Funktionen.
-- Sie wird hier definiert, damit sie im gesamten Skript zugÃ¤nglich ist.
if not _G.AimwareConfig then
    _G.AimwareConfig = {
        Aimbot = {
            Enabled = false,
            Keybind = "MouseButton2",
            IsAimKeyDown = false,
            TeamCheck = false,
            WallCheck = false,
            ShowFov = false,
            Fov = 150,
            Smoothing = 10,
            AimPart = "Head",
            FireOnPress = false,
            AutoFire = false, -- HinzugefÃ¼gt fÃ¼r AutoFire
            FireDelay = 0.1 -- HinzugefÃ¼gt fÃ¼r AutoFire VerzÃ¶gerung (in Sekunden)
        },
        Triggerbot = {
            Enabled = false
        }
    }
end
local Config = _G.AimwareConfig

-- Globale Variable fÃ¼r die letzte Schusszeit (fÃ¼r AutoFire)
local lastFireTime = 0

-- #####################################################################
-- # 2. AIMBOT & TRIGGERBOT FUNKTIONSLOGIK
-- #####################################################################

local function isVisible(part)
    if not Config.Aimbot.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {PLAYER.Character}
    local result = workspace:Raycast(CurrentCam.CFrame.Position, (part.Position - CurrentCam.CFrame.Position).Unit * 1000, params)
    return (result and result.Instance and result.Instance:IsDescendantOf(part.Parent))
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local smallestDistance = Config.Aimbot.Fov
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= PLAYER and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if not (Config.Aimbot.TeamCheck and player.Team == PLAYER.Team) then
                local aimPart = player.Character:FindFirstChild(Config.Aimbot.AimPart)
                if aimPart then
                    local screenPos, onScreen = CurrentCam:WorldToViewportPoint(aimPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - UIS:GetMouseLocation()).Magnitude
                        if distance < smallestDistance and isVisible(aimPart) then
                            smallestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function aimAt(targetPlayer)
    local aimPart = targetPlayer.Character:FindFirstChild(Config.Aimbot.AimPart)
    if aimPart then
        local targetCFrame = CFrame.new(CurrentCam.CFrame.Position, aimPart.Position)
        local newCFrame = CurrentCam.CFrame:Lerp(targetCFrame, 1 / (Config.Aimbot.Smoothing + 1))
        CurrentCam.CFrame = newCFrame
    end
end

-- Hilfsfunktionen fÃ¼r Mausklicks (falls noch nicht global definiert)
local function mouse1press()
    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1)
end

local function mouse1release()
    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function handleTriggerbot()
    if not Config.Triggerbot.Enabled then return end
    local mousePos = UIS:GetMouseLocation()
    local ray = CurrentCam:ViewportPointToRay(mousePos.X, mousePos.Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
    if result and result.Instance and result.Instance.Parent and result.Instance.Parent:FindFirstChild("Humanoid") then
        local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(result.Instance.Parent)
        if targetPlayer and targetPlayer ~= PLAYER and not (Config.Aimbot.TeamCheck and targetPlayer.Team == PLAYER.Team) then
            -- Triggerbot feuert nur, wenn AutoFire im Aimbot nicht aktiv ist
            if not Config.Aimbot.AutoFire then
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
        end
    end
end

-- #####################################################################
-- # 3. ZENTRALE STEUERUNG (RenderStepped, Input)
-- #####################################################################

-- Wir stellen sicher, dass diese Verbindungen nur einmal erstellt werden.
if not _G.AimwareLogicConnected then
    RunService.RenderStepped:Connect(function()
        if Config.Aimbot.Enabled and Config.Aimbot.IsAimKeyDown then
            local target = getClosestPlayerToMouse()
            if target then
                aimAt(target)
                -- AutoFire Logik fÃ¼r Aimbot
                if Config.Aimbot.AutoFire then
                    local currentTime = tick()
                    if currentTime - lastFireTime >= Config.Aimbot.FireDelay then
                        mouse1press()
                        task.wait(0.01) -- Kurze VerzÃ¶gerung, damit das Spiel den Klick registriert
                        mouse1release()
                        lastFireTime = currentTime
                    end
                elseif Config.Aimbot.FireOnPress then
                    mouse1press()
                end
            else
                -- Wenn kein Ziel gefunden wird und FireOnPress aktiv ist, Maus loslassen
                if Config.Aimbot.FireOnPress then
                    mouse1release()
                end
            end
        else
            -- Wenn Aimbot nicht aktiv ist oder Taste nicht gedrÃ¼ckt wird, Maus loslassen
            if Config.Aimbot.FireOnPress then
                mouse1release()
            end
        end
        
        -- Triggerbot wird immer ausgefÃ¼hrt, es sei denn, AutoFire ist aktiv und ein Ziel ist im Aimbot-FOV
        -- Die Logik im Triggerbot selbst verhindert das Feuern, wenn AutoFire aktiv ist.
        handleTriggerbot()
    end)

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local keyName = input.KeyCode.Name
        local typeName = input.UserInputType.Name
        if (keyName == Config.Aimbot.Keybind or typeName == Config.Aimbot.Keybind) and Config.Aimbot.Enabled then
            Config.Aimbot.IsAimKeyDown = true
        end
    end)

    UIS.InputEnded:Connect(function(input)
        local keyName = input.KeyCode.Name
        local typeName = input.UserInputType.Name
        if (keyName == Config.Aimbot.Keybind or typeName == Config.UserInputType.Name) then
            Config.Aimbot.IsAimKeyDown = false
            -- Die mouse1release() fÃ¼r FireOnPress wird jetzt im RenderStepped behandelt
        end
    end)
    _G.AimwareLogicConnected = true
end

-- #####################################################################
-- # 4. UI-ERSTELLUNG FÃœR DEN LEGITBOT-TAB
-- #####################################################################

-- Diese Funktion wird von main.lua aufgerufen. 'parent' ist der Inhaltsbereich des Legitbot-Tabs.
return function(parent)
    -- UI-Hilfsfunktionen
    local function createGroup(p, position, size, title)
        local group = Instance.new("Frame"); group.Position = position; group.Size = size; group.BackgroundColor3 = Color3.fromRGB(35, 35, 35); group.BorderSizePixel = 0; group.Parent = p
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 4); corner.Parent = group
        local titleLabel = Instance.new("TextLabel"); titleLabel.Name = "Title"; titleLabel.Size = UDim2.new(1, 0, 0, 25); titleLabel.Position = UDim2.new(0, 0, 0, 0); titleLabel.BackgroundTransparency = 1; titleLabel.Font = Enum.Font.GothamBold; titleLabel.Text = "  " .. title; titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220); titleLabel.TextSize = 14; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Parent = group
        return group
    end

    local function createCheckbox(p, position, text, description, callback, initial_state)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 30); container.BackgroundTransparency = 1; container.Parent = p
        local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(14, 14); box.Position = UDim2.new(0, 0, 0.5, -7); box.BackgroundColor3 = Color3.fromRGB(50, 50, 50); box.Parent = container
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 3); corner.Parent = box
        local checkmark = Instance.new("TextLabel"); checkmark.Size = UDim2.fromOffset(14, 14); checkmark.BackgroundTransparency = 1; checkmark.Font = Enum.Font.GothamBold; checkmark.Text = "âœ”"; checkmark.TextColor3 = Color3.fromRGB(255, 255, 255); checkmark.TextSize = 12; checkmark.Visible = initial_state; checkmark.Parent = box
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -20, 0, 20); label.Position = UDim2.new(0, 20, 0, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1, -20, 0, 15); desc.Position = UDim2.new(0, 20, 0, 15); desc.BackgroundTransparency = 1; desc.Font = Enum.Font.Gotham; desc.Text = description; desc.TextColor3 = Color3.fromRGB(120, 120, 120); desc.TextSize = 12; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Parent = container
        local button = Instance.new("TextButton"); button.Size = UDim2.new(1, 0, 1, 0); button.BackgroundTransparency = 1; button.Text = ""; button.Parent = container
        local state = initial_state; button.MouseButton1Click:Connect(function() state = not state; checkmark.Visible = state; if callback then callback(state) end end)
        return container, checkmark
    end

    local function createKeySelector(p, position, text, description, defaultKey, callback)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 55); container.BackgroundTransparency = 1; container.Parent = p
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 20); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamBold; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1, 0, 0, 15); desc.Position = UDim2.new(0, 0, 0, 15); desc.BackgroundTransparency = 1; desc.Font = Enum.Font.Gotham; desc.Text = description; desc.TextColor3 = Color3.fromRGB(120, 120, 120); desc.TextSize = 12; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Parent = container
        local keyButton = Instance.new("TextButton"); keyButton.Size = UDim2.new(1, 0, 0, 25); keyButton.Position = UDim2.new(0, 0, 0, 30); keyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50); keyButton.Font = Enum.Font.GothamBold; keyButton.Text = defaultKey; keyButton.TextColor3 = Color3.fromRGB(200, 200, 200); keyButton.TextSize = 14; keyButton.Parent = container
        keyButton.MouseButton1Click:Connect(function()
            keyButton.Text = "[...]"
            local input = UIS.InputBegan:Wait()
            local key = input.KeyCode.Name
            if string.find(key, "MouseButton") then key = input.UserInputType.Name end
            keyButton.Text = key
            if callback then callback(key) end
        end)
        return container
    end

    -- Hauptstruktur mit Sub-Tabs
    local subTabNav = Instance.new("Frame"); subTabNav.Name = "SubTabNav"; subTabNav.Size = UDim2.new(0, 150, 1, 0); subTabNav.BackgroundColor3 = Color3.fromRGB(40, 40, 40); subTabNav.BorderSizePixel = 0; subTabNav.Parent = parent
    local contentArea = Instance.new("Frame"); contentArea.Name = "ContentArea"; contentArea.Size = UDim2.new(1, -150, 1, 0); contentArea.Position = UDim2.new(0, 150, 0, 0); contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = parent
    
    local subTabs = {"Aimbot", "Triggerbot", "Weapon", "Other", "Semirage"}
    local subTabFrames = {}
    local activeSubTabButton = nil

    for i, tabName in ipairs(subTabs) do
        local btn = Instance.new("TextButton"); btn.Name = tabName .. "SubTab"; btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.BorderSizePixel = 0; btn.Font = Enum.Font.Gotham; btn.Text = "  " .. tabName; btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = subTabNav
        local indicator = Instance.new("Frame"); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 3, 1, 0); indicator.BackgroundColor3 = Color3.fromRGB(200, 40, 40); indicator.BorderSizePixel = 0; indicator.Visible = false; indicator.Parent = btn
        local content = Instance.new("Frame"); content.Name = tabName .. "Content"; content.Size = UDim2.new(1, 0, 1, 0); content.BackgroundTransparency = 1; content.Visible = false; content.Parent = contentArea
        subTabFrames[tabName] = content
        btn.MouseButton1Click:Connect(function() if activeSubTabButton then activeSubTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40); activeSubTabButton.TextColor3 = Color3.fromRGB(180, 180, 180); activeSubTabButton.Indicator.Visible = false end; for _, f in pairs(subTabFrames) do f.Visible = false end; content.Visible = true; btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55); btn.TextColor3 = Color3.fromRGB(200, 40, 40); indicator.Visible = true; activeSubTabButton = btn end)
    end

    -- INHALTE FÃœR DIE SUB-TABS
    local aimbotContent = subTabFrames["Aimbot"]
    local toggleGroup = createGroup(aimbotContent, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -15, 0, 130), "Toggle")
    createCheckbox(toggleGroup, UDim2.new(0, 10, 0, 30), "Enable", "Enables legit aimbot", function(state) Config.Aimbot.Enabled = state end, Config.Aimbot.Enabled)
    createKeySelector(toggleGroup, UDim2.new(0, 10, 0, 65), "Aim Key", "Set the aimbot on key", Config.Aimbot.Keybind, function(key) Config.Aimbot.Keybind = key end)

    local weaponGroup = createGroup(aimbotContent, UDim2.new(0, 10, 0, 150), UDim2.new(0.5, -15, 0, 100), "Weapon")
    createCheckbox(weaponGroup, UDim2.new(0, 10, 0, 30), "Auto Fire", "Fires without pressing any key", function(state) Config.Aimbot.AutoFire = state end, Config.Aimbot.AutoFire)
    createCheckbox(weaponGroup, UDim2.new(0, 10, 0, 60), "Fire On Press", "Fires when pressing the aimbot key", function(state) Config.Aimbot.FireOnPress = state end, Config.Aimbot.FireOnPress)

    local triggerbotContent = subTabFrames["Triggerbot"]
    local triggerGroup = createGroup(triggerbotContent, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -15, 0, 100), "Triggerbot")
    createCheckbox(triggerGroup, UDim2.new(0, 10, 0, 30), "Enable Triggerbot", "Fires when your crosshair is on an enemy.", function(state) Config.Triggerbot.Enabled = state end, Config.Triggerbot.Enabled)

    -- Platzhalter fÃ¼r die restlichen Tabs
    local function createPlaceholder(p, text)
        local placeholder = Instance.new("TextLabel"); placeholder.Size = UDim2.new(1, -20, 0, 50); placeholder.Position = UDim2.new(0, 10, 0, 10); placeholder.BackgroundTransparency = 1; placeholder.Font = Enum.Font.GothamBold; placeholder.Text = text; placeholder.TextColor3 = Color3.fromRGB(150, 150, 150); placeholder.TextSize = 20; placeholder.Parent = p
    end
    createPlaceholder(subTabFrames["Weapon"], "Weapon Settings...")
    createPlaceholder(subTabFrames["Other"], "Other Settings...")
    createPlaceholder(subTabFrames["Semirage"], "Semirage Settings...")

    -- Standard-Tab aktivieren
    if subTabNav:FindFirstChild("AimbotSubTab") then
        subTabNav.AimbotSubTab.MouseButton1Click:Fire()
    end
end

