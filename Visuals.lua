-- Visuals.lua - Version 8 (Final & Poliert)
-- Kombiniert das Aimware-UI, korrigierte Box-Logik und erweiterte Funktionen (Colorpicker).

return function(parent)
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    -- #####################################################################
    -- # 1. GLOBALE EINSTELLUNGEN
    -- #####################################################################

    _G.Settings = {
        ESP_Enabled = false,
        ESP_Color = Color3.fromRGB(255, 0, 0),
        Chams_Enabled = false,
        Chams_Color = Color3.fromRGB(255, 0, 0),
        Chams_Material = Enum.Material.ForceField,
        Watermark_Enabled = true, -- StandardmÃ¤ÃŸig an
        DebugInfo_Enabled = true,  -- StandardmÃ¤ÃŸig an
        LocalTrails_Enabled = false,
        BulletTracer_Enabled = false
    }
    _G.Settings.Skeleton_Enabled = true

    -- #####################################################################
    -- # 2. HILFSFUNKTIONEN & VARIABLEN (JETZT AN DER RICHTIGEN STELLE)
    -- #####################################################################
    
    local originalMaterials = {}
    local ESPObjects = {} -- Wichtig: Muss hier oben definiert werden
    local NameESPObjects = {}
    local SkeletonObjects = {}
    local localPlayerTrail = nil

    local function newDrawing(type, props)
        local obj = Drawing.new(type)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    local function createESPElements()
        return {
            Box = newDrawing("Square", {Visible = false, Thickness = 1, Filled = false, Color = Color3.new(1,1,1)})
        }
    end
    local function createLine(line, point1, point2, color)
    if point1 and point2 then
        local screenPos1, onScreen1 = Camera:WorldToViewportPoint(point1)
        local screenPos2, onScreen2 = Camera:WorldToViewportPoint(point2)
        
        if onScreen1 and onScreen2 then
            line.From = Vector2.new(screenPos1.X, screenPos1.Y)
            line.To = Vector2.new(screenPos2.X, screenPos2.Y)
            line.Color = color
            line.Visible = true
            return true
        end
    end
    line.Visible = false
    return false
end

    local function createSkeletonElements()
    return {
        -- Torso Verbindungen
        HeadToTorso = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        TorsoToLeftArm = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        TorsoToRightArm = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        TorsoToLeftLeg = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        TorsoToRightLeg = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        
        -- Arm Verbindungen
        LeftArmToHand = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        RightArmToHand = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        
        -- Bein Verbindungen
        LeftLegToFoot = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)}),
        RightLegToFoot = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(1,1,1)})
    }
end

    local function getBoxScreenPoints(cframe, size)
        local half = size / 2
        local points = {}
        local visible = true
        for x = -1,1,2 do
            for y = -1,1,2 do
                for z = -1,1,2 do
                    local corner = cframe * Vector3.new(half.X*x, half.Y*y, half.Z*z)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
                    if not onScreen then visible = false end
                    table.insert(points, Vector2.new(screenPos.X, screenPos.Y))
                end
            end
        end
        return points, visible
    end
    
    local function updateLocalTrail()
    if not _G.Settings.LocalTrails_Enabled then
        if localPlayerTrail then
            localPlayerTrail.Enabled = false
        end
        return
    end

    local character = LocalPlayer.Character
    if not character then
        if localPlayerTrail then localPlayerTrail.Enabled = false end
        return
    end

    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not torso then
        if localPlayerTrail then localPlayerTrail.Enabled = false end
        return
    end

    if not localPlayerTrail or localPlayerTrail.Parent == nil then
        localPlayerTrail = Instance.new("Trail")
        localPlayerTrail.Attachment0 = Instance.new("Attachment", torso)
        localPlayerTrail.Attachment1 = Instance.new("Attachment", torso)
        localPlayerTrail.Attachment0.Position = Vector3.new(0, -2.5, 0)
        localPlayerTrail.Attachment1.Position = Vector3.new(0, -3, 0)
        
        -- KORRIGIERT: Lifetime und Transparency angepasst
        localPlayerTrail.Lifetime = 2.5 -- NEU: Dauer auf 2.5 Sekunden erhÃ¶ht
        localPlayerTrail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),   -- Start: Voll sichtbar (solide)
            NumberSequenceKeypoint.new(0.2, 0), -- Bleibt fÃ¼r 20% der Zeit solide
            NumberSequenceKeypoint.new(1, 1)    -- Ende: Komplett unsichtbar
        })
        localPlayerTrail.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        })
        localPlayerTrail.LightEmission = 1
        localPlayerTrail.Parent = torso
    end

    localPlayerTrail.Color = ColorSequence.new(_G.Settings.ESP_Color)
    localPlayerTrail.Enabled = true
end

local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local function createBulletTracer()
    -- Startpunkt ist die Kameraposition
    local startPosition = Camera.CFrame.Position
    -- Endpunkt ist weit in die Richtung, in die die Kamera schaut
    local endPosition = startPosition + (Camera.CFrame.LookVector * 1000)
    
    -- Erstelle das "Geschoss" (ein einfaches Part)
    local tracerPart = Instance.new("Part")
    tracerPart.Anchored = true
    tracerPart.CanCollide = false
    tracerPart.Material = Enum.Material.Neon
    tracerPart.Color = _G.Settings.ESP_Color -- Verwendet die ESP-Farbe
    tracerPart.Transparency = 0.25 -- Leicht durchsichtig
    
    -- Berechne die GrÃ¶ÃŸe und Position, um eine Linie zwischen Start und Ende zu bilden
    local distance = (startPosition - endPosition).Magnitude
    tracerPart.Size = Vector3.new(0.1, 0.1, distance)
    tracerPart.CFrame = CFrame.new(startPosition, endPosition) * CFrame.new(0, 0, -distance / 2)
    
    tracerPart.Parent = workspace
    
    -- FÃ¼ge einen Trail fÃ¼r den visuellen Effekt hinzu
    local trail = Instance.new("Trail", tracerPart)
    local attachment0 = Instance.new("Attachment", tracerPart)
    local attachment1 = Instance.new("Attachment", tracerPart)
    attachment0.Position = Vector3.new(0, 0, distance / 2)
    attachment1.Position = Vector3.new(0, 0, -distance / 2)
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Color = ColorSequence.new(Color3.new(1, 1, 1)) -- WeiÃŸer Kern
    trail.Lifetime = 0.1
    trail.LightEmission = 1
    trail.Transparency = NumberSequence.new(0.5)
    
    -- FÃ¼ge das Part nach 7 Sekunden zum Debris-Service hinzu, damit es automatisch gelÃ¶scht wird
    Debris:AddItem(tracerPart, 7)
end

-- Event-Handler fÃ¼r den Rechtsklick
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    -- Ignoriere den Klick, wenn er von der UI verarbeitet wurde (z.B. Klick auf einen Button)
    if gameProcessedEvent then return end

    -- PrÃ¼fe, ob die Funktion aktiviert ist und ob es ein Rechtsklick war
    if _G.Settings.BulletTracer_Enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        createBulletTracer()
    end
end)




    local function createNameESPElements()
    return {
        NameLabel = newDrawing("Text", {
            Visible = false,
            Color = Color3.new(1, 1, 1), -- Immer weiÃŸ
            Size = 16,
            Center = true,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Font = Drawing.Fonts.UI,
            Text = ""
        })
    }
end

local function hideAllNameESP(data)
    if data and data.NameLabel then
        data.NameLabel.Visible = false
    end
end

    local function hideAllSkeleton(data)
    for _, line in pairs(data) do
        if line and line.Visible ~= nil then
            line.Visible = false
        end
    end
end

    local function hideAll(data)
        data.Box.Visible = false
    end

    
    function removeChams(player)
        if originalMaterials[player] then
            for part, material in pairs(originalMaterials[player]) do
                if part and part.Parent then part.Material = material; part.Transparency = 0 end
            end
            originalMaterials[player] = nil
        end
    end

    -- Cleanup, wenn Spieler das Spiel verlÃƒÂ¤sst
local originalPlayerRemoving = Players.PlayerRemoving:Connect(function() end)
originalPlayerRemoving:Disconnect()

Players.PlayerRemoving:Connect(function(player)

    if NameESPObjects[player] then
        if NameESPObjects[player].NameLabel and NameESPObjects[player].NameLabel.Remove then
            NameESPObjects[player].NameLabel:Remove()
        end
        NameESPObjects[player] = nil
    end
    -- Bestehender ESP cleanup
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            obj:Remove()
        end
        ESPObjects[player] = nil
    end
    
    -- Skeleton ESP cleanup
    if SkeletonObjects[player] then
        for _, line in pairs(SkeletonObjects[player]) do
            if line and line.Remove then
                line:Remove()
            end
        end
        SkeletonObjects[player] = nil
    end
    
    removeChams(player)
end)

    local originalPlayerRemoving = Players.PlayerRemoving:Connect(function() end)
originalPlayerRemoving:Disconnect()

    -- #####################################################################
    -- # 3. HAUPT-RENDER-LOOP
    -- #####################################################################

    RunService.RenderStepped:Connect(function()
        -- ESP-Logik
        if _G.Settings.ESP_Enabled then
            local baseColor = _G.Settings.ESP_Color
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if character and humanoid and humanoid.Health > 0 then
                        local success, cframe, size = pcall(character.GetBoundingBox, character)
                        if success and cframe and size then
                            local points, visible = getBoxScreenPoints(cframe, size)
                            if not visible then
                                if ESPObjects[player] then hideAll(ESPObjects[player]) end
                            else
                                local data = ESPObjects[player] or createESPElements()
                                ESPObjects[player] = data
                                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                                for _, pt in ipairs(points) do
                                    minX = math.min(minX, pt.X); minY = math.min(minY, pt.Y)
                                    maxX = math.max(maxX, pt.X); maxY = math.max(maxY, pt.Y)
                                end
                                local boxWidth, boxHeight = maxX - minX, maxY - minY
                                data.Box.Visible = true
                                data.Box.Position = Vector2.new(minX, minY)
                                data.Box.Size = Vector2.new(boxWidth, boxHeight)
                                data.Box.Color = baseColor
                            end
                        end
                    else
                        if ESPObjects[player] then hideAll(ESPObjects[player]) end
                    end
                end
            end
        else
            for _, data in pairs(ESPObjects) do
                hideAll(data)
            end
        end

        if _G.Settings.Skeleton_Enabled then
    local skeletonColor = _G.Settings.ESP_Color -- Verwendet dieselbe Farbe wie der ESP
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            if character and humanoid and humanoid.Health > 0 then
                -- Hole die wichtigsten KÃ¶rperteile
                local head = character:FindFirstChild("Head")
                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                local leftArm = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftUpperArm")
                local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightUpperArm")
                local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftUpperLeg")
                local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightUpperLeg")
                local leftHand = character:FindFirstChild("Left Hand") or character:FindFirstChild("LeftHand")
                local rightHand = character:FindFirstChild("Right Hand") or character:FindFirstChild("RightHand")
                local leftFoot = character:FindFirstChild("Left Foot") or character:FindFirstChild("LeftFoot")
                local rightFoot = character:FindFirstChild("Right Foot") or character:FindFirstChild("RightFoot")
                
                if torso then
                    -- Erstelle oder hole Skeleton-Daten
                    local skeletonData = SkeletonObjects[player] or createSkeletonElements()
                    SkeletonObjects[player] = skeletonData
                    
                    -- Zeichne Skeleton-Linien
                    local anyVisible = false
                    
                    -- Kopf zu Torso
                    if head then
                        anyVisible = createLine(skeletonData.HeadToTorso, head.Position, torso.Position, skeletonColor) or anyVisible
                    end
                    
                    -- Torso zu Armen
                    if leftArm then
                        anyVisible = createLine(skeletonData.TorsoToLeftArm, torso.Position, leftArm.Position, skeletonColor) or anyVisible
                    end
                    if rightArm then
                        anyVisible = createLine(skeletonData.TorsoToRightArm, torso.Position, rightArm.Position, skeletonColor) or anyVisible
                    end
                    
                    -- Torso zu Beinen
                    if leftLeg then
                        anyVisible = createLine(skeletonData.TorsoToLeftLeg, torso.Position, leftLeg.Position, skeletonColor) or anyVisible
                    end
                    if rightLeg then
                        anyVisible = createLine(skeletonData.TorsoToRightLeg, torso.Position, rightLeg.Position, skeletonColor) or anyVisible
                    end
                    
                    -- Arme zu HÃ¤nden
                    if leftArm and leftHand then
                        anyVisible = createLine(skeletonData.LeftArmToHand, leftArm.Position, leftHand.Position, skeletonColor) or anyVisible
                    end
                    if rightArm and rightHand then
                        anyVisible = createLine(skeletonData.RightArmToHand, rightArm.Position, rightHand.Position, skeletonColor) or anyVisible
                    end
                    
                    -- Beine zu FÃ¼ÃŸen
                    if leftLeg and leftFoot then
                        anyVisible = createLine(skeletonData.LeftLegToFoot, leftLeg.Position, leftFoot.Position, skeletonColor) or anyVisible
                    end
                    if rightLeg and rightFoot then
                        anyVisible = createLine(skeletonData.RightLegToFoot, rightLeg.Position, rightFoot.Position, skeletonColor) or anyVisible
                    end
                    
                    -- Verstecke alle Linien wenn Spieler nicht sichtbar
                    if not anyVisible then
                        hideAllSkeleton(skeletonData)
                    end
                else
                    -- Verstecke Skeleton wenn kein Torso gefunden
                    if SkeletonObjects[player] then
                        hideAllSkeleton(SkeletonObjects[player])
                    end
                end
            else
                -- Verstecke Skeleton wenn Spieler tot oder nicht vorhanden
                if SkeletonObjects[player] then
                    hideAllSkeleton(SkeletonObjects[player])
                end
            end
        end
    end
else
    -- Verstecke alle Skeleton ESP wenn deaktiviert
    for _, skeletonData in pairs(SkeletonObjects) do
        hideAllSkeleton(skeletonData)
    end
end
if _G.Settings.NameESP_Enabled then
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            if character and humanoid and humanoid.Health > 0 then
                local head = character:FindFirstChild("Head")
                
                if head then
                    -- Berechne Position Ã¼ber dem Kopf
                    local headPosition = head.Position + Vector3.new(0, head.Size.Y/2 + 1, 0)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(headPosition)
                    
                    if onScreen then
                        -- Erstelle oder hole Name ESP Daten
                        local nameData = NameESPObjects[player] or createNameESPElements()
                        NameESPObjects[player] = nameData
                        
                        -- Aktualisiere Name Label
                        nameData.NameLabel.Position = Vector2.new(screenPos.X, screenPos.Y)
                        nameData.NameLabel.Text = player.Name
                        nameData.NameLabel.Color = Color3.new(1, 1, 1) -- Immer weiÃŸ
                        nameData.NameLabel.Visible = true
                    else
                        -- Verstecke Name ESP wenn nicht sichtbar
                        if NameESPObjects[player] then
                            hideAllNameESP(NameESPObjects[player])
                        end
                    end
                else
                    -- Verstecke Name ESP wenn kein Kopf gefunden
                    if NameESPObjects[player] then
                        hideAllNameESP(NameESPObjects[player])
                    end
                end
            else
                -- Verstecke Name ESP wenn Spieler tot oder nicht vorhanden
                if NameESPObjects[player] then
                    hideAllNameESP(NameESPObjects[player])
                end
            end
        end
    end
else
    -- Verstecke alle Name ESP wenn deaktiviert
    for _, nameData in pairs(NameESPObjects) do
        hideAllNameESP(nameData)
    end
end

        -- Chams-Logik
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if _G.Settings.Chams_Enabled and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    if not originalMaterials[player] then originalMaterials[player] = {} end
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            if not originalMaterials[player][part] then originalMaterials[player][part] = part.Material end
                            part.Material = _G.Settings.Chams_Material
                            part.Color = _G.Settings.Chams_Color
                            part.Transparency = 0.5
                        end
                    end
                else
                    removeChams(player)
                end
            end
        end
        updateLocalTrail()
    end)

    -- #####################################################################
    -- # 4. UI-BIBLIOTHEK & ERSTELLUNG
    -- #####################################################################
    
    local function createGroup(p, position, size, title)
        local group = Instance.new("Frame"); group.Position = position; group.Size = size; group.BackgroundColor3 = Color3.fromRGB(35, 35, 35); group.BorderSizePixel = 0; group.Parent = p
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 4); corner.Parent = group
        local titleLabel = Instance.new("TextLabel"); titleLabel.Name = "Title"; titleLabel.Size = UDim2.new(1, 0, 0, 25); titleLabel.Position = UDim2.new(0, 0, 0, 0); titleLabel.BackgroundTransparency = 1; titleLabel.Font = Enum.Font.GothamBold; titleLabel.Text = "  " .. title; titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220); titleLabel.TextSize = 14; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Parent = group
        return group
    end

    local function createCheckbox(p, position, text, description, action)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 30); container.BackgroundTransparency = 1; container.Parent = p
        local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(14, 14); box.Position = UDim2.new(0, 0, 0.5, -7); box.BackgroundColor3 = Color3.fromRGB(50, 50, 50); box.Parent = container
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 3); corner.Parent = box
        local checkmark = Instance.new("TextLabel"); checkmark.Size = UDim2.fromOffset(14, 14); checkmark.BackgroundTransparency = 1; checkmark.Font = Enum.Font.GothamBold; checkmark.Text = "âœ”"; checkmark.TextColor3 = Color3.fromRGB(255, 255, 255); checkmark.TextSize = 12; checkmark.Parent = box
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -20, 0, 20); label.Position = UDim2.new(0, 20, 0, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1, -20, 0, 15); desc.Position = UDim2.new(0, 20, 0, 15); desc.BackgroundTransparency = 1; desc.Font = Enum.Font.Gotham; desc.Text = description; desc.TextColor3 = Color3.fromRGB(120, 120, 120); desc.TextSize = 12; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Parent = container
        local button = Instance.new("TextButton"); button.Size = UDim2.new(1, 0, 1, 0); button.BackgroundTransparency = 1; button.Text = ""; button.Parent = container
        
        if type(action) == "string" then
            checkmark.Visible = _G.Settings[action] or false
            button.MouseButton1Click:Connect(function()
                _G.Settings[action] = not _G.Settings[action]
                checkmark.Visible = _G.Settings[action]
            end)
        elseif type(action) == "function" then
            local state = false
            checkmark.Visible = state
            button.MouseButton1Click:Connect(function()
                state = not state
                checkmark.Visible = state
                action(state)
            end)
        end
    end

    local function createColorPicker(p, position, text, configKey)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 30); container.BackgroundTransparency = 1; container.Parent = p
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.5, 0, 1, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local colorButton = Instance.new("TextButton"); colorButton.Size = UDim2.new(0.4, 0, 1, 0); colorButton.Position = UDim2.new(0.6, 0, 0, 0); colorButton.BackgroundColor3 = _G.Settings[configKey]; colorButton.Text = ""; colorButton.Parent = container
        colorButton.MouseButton1Click:Connect(function()
            local newColor = Color3.new(math.random(), math.random(), math.random())
            _G.Settings[configKey] = newColor
            colorButton.BackgroundColor3 = newColor
        end)
    end

    local function createDropdown(p, position, text, options, configKey)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 50); container.BackgroundTransparency = 1; container.Parent = p
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 20); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local dropdown = Instance.new("TextButton"); dropdown.Size = UDim2.new(1, 0, 0, 25); dropdown.Position = UDim2.new(0, 0, 0, 20); dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50); dropdown.Text = ""; dropdown.Parent = container
        local selectedLabel = Instance.new("TextLabel"); selectedLabel.Size = UDim2.new(1, -20, 1, 0); selectedLabel.Position = UDim2.new(0, 10, 0, 0); selectedLabel.BackgroundTransparency = 1; selectedLabel.Font = Enum.Font.Gotham; selectedLabel.Text = tostring(options[1]); selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200); selectedLabel.TextSize = 14; selectedLabel.TextXAlignment = Enum.TextXAlignment.Left; selectedLabel.Parent = dropdown
        local arrow = Instance.new("TextLabel"); arrow.Size = UDim2.new(0, 20, 1, 0); arrow.Position = UDim2.new(1, -20, 0, 0); arrow.BackgroundTransparency = 1; arrow.Font = Enum.Font.GothamBold; arrow.Text = "Ã¢â€“Â¾"; arrow.TextColor3 = Color3.fromRGB(200, 200, 200); arrow.TextSize = 14; arrow.Parent = dropdown
        local currentIndex = 1
        dropdown.MouseButton1Click:Connect(function()
            currentIndex = (currentIndex % #options) + 1
            local selectedValue = options[currentIndex]
            selectedLabel.Text = tostring(selectedValue)
            _G.Settings[configKey] = selectedValue
        end)
    end

    -- UI-Struktur
    local subTabNav = Instance.new("Frame"); subTabNav.Name = "SubTabNav"; subTabNav.Size = UDim2.new(0, 150, 1, 0); subTabNav.BackgroundColor3 = Color3.fromRGB(40, 40, 40); subTabNav.BorderSizePixel = 0; subTabNav.Parent = parent
    local contentArea = Instance.new("Frame"); contentArea.Name = "ContentArea"; contentArea.Size = UDim2.new(1, -150, 1, 0); contentArea.Position = UDim2.new(0, 150, 0, 0); contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = parent
    local subTabs = {"Overlay", "Chams", "World"}; local subTabFrames = {}; local activeSubTabButton = nil
    for i, tabName in ipairs(subTabs) do
        local btn = Instance.new("TextButton"); btn.Name = tabName .. "SubTab"; btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.BorderSizePixel = 0; btn.Font = Enum.Font.Gotham; btn.Text = "  " .. tabName; btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = subTabNav
        local indicator = Instance.new("Frame"); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 3, 1, 0); indicator.BackgroundColor3 = Color3.fromRGB(200, 40, 40); indicator.BorderSizePixel = 0; indicator.Visible = false; indicator.Parent = btn
        local content = Instance.new("Frame"); content.Name = tabName .. "Content"; content.Size = UDim2.new(1, 0, 1, 0); content.BackgroundTransparency = 1; content.Visible = false; content.Parent = contentArea
        subTabFrames[tabName] = content
        btn.MouseButton1Click:Connect(function() if activeSubTabButton then activeSubTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40); activeSubTabButton.TextColor3 = Color3.fromRGB(180, 180, 180); activeSubTabButton.Indicator.Visible = false end; for _, f in pairs(subTabFrames) do f.Visible = false end; content.Visible = true; btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55); btn.TextColor3 = Color3.fromRGB(200, 40, 40); indicator.Visible = true; activeSubTabButton = btn end)
    end

    -- UI-Inhalte
    local overlayContent = subTabFrames["Overlay"]
    local playerGroup = createGroup(overlayContent, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -15, 0, 240), "Player ESP")
    createCheckbox(playerGroup, UDim2.new(0, 10, 0, 30), "Enable Box ESP", "Draws a box around players", "ESP_Enabled")
    createCheckbox(playerGroup, UDim2.new(0, 10, 0, 90), "Enable Name ESP", "Shows player names in white", "NameESP_Enabled")
    createCheckbox(playerGroup, UDim2.new(0, 10, 0, 120), "Enable Skeleton ESP", "Draws skeleton lines on players", "Skeleton_Enabled")
    createCheckbox(playerGroup, UDim2.new(0, 10, 0, 150), "Enable Local Trails", "Creates a trail behind you", "LocalTrails_Enabled")
    createCheckbox(playerGroup, UDim2.new(0, 10, 0, 180), "Bullet Tracer (buggy)", "Spawns a tracer on right click", "BulletTracer_Enabled")
    createColorPicker(playerGroup, UDim2.new(0, 10, 0, 60), "Box Color", "ESP_Color")

    local uiGroup = createGroup(overlayContent, UDim2.new(0.5, 5, 0, 10), UDim2.new(0.5, -15, 0, 120), "UI Elements")
    createCheckbox(uiGroup, UDim2.new(0, 10, 0, 30), "Enable Watermark", "Shows the aimware watermark", "Watermark_Enabled")
    createCheckbox(uiGroup, UDim2.new(0, 10, 0, 60), "Enable Debug Info", "Shows FPS and other stats", "DebugInfo_Enabled")

    local chamsContent = subTabFrames["Chams"]
    local chamsGroup = createGroup(chamsContent, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -15, 0, 150), "Chams")
    createCheckbox(chamsGroup, UDim2.new(0, 10, 0, 30), "Enable Chams", "See players through walls", "Chams_Enabled")
    createColorPicker(chamsGroup, UDim2.new(0, 10, 0, 60), "Chams Color", "Chams_Color")
    
    local materialOptions = { Enum.Material.ForceField, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Fabric, Enum.Material.Granite }
    createDropdown(chamsGroup, UDim2.new(0, 10, 0, 90), "Chams Material", materialOptions, "Chams_Material")
    
    local worldContent = subTabFrames["World"]
    local worldGroup = createGroup(worldContent, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -15, 0, 80), "World")
    createCheckbox(worldGroup, UDim2.new(0, 10, 0, 30), "FPS Booster", "Reduces graphics for more FPS", function(enabled)
        if enabled then
            spawn(function()
                local success, scriptContent = pcall(game.HttpGet, game, "http://github.com/hutaoshusband/aimware-port-roblox/blob/main/fpsboost.lua"  )
                if success and scriptContent then loadstring(scriptContent)() else warn("FPS Booster script could not be loaded.") end
            end)
        end
    end)
    
-- #####################################################################
-- # 5. WASSERZEICHEN (NEUES AIMWARE-DESIGN)
-- #####################################################################
local function createWatermark()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimwareWatermark"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Hintergrund-Frame fÃƒÂ¼r den Aimware-Look
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Name = "WatermarkBackground"
    backgroundFrame.AnchorPoint = Vector2.new(1, 0) -- Ankerpunkt oben rechts
    backgroundFrame.Position = UDim2.new(1, -10, 0, 10) -- 10px Abstand von oben und rechts
    backgroundFrame.Size = UDim2.new(0, 250, 0, 22) -- GrÃƒÂ¶ÃƒÅ¸e des Kastens
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dunkelgrauer Hintergrund
    backgroundFrame.BorderColor3 = Color3.fromRGB(200, 40, 40) -- Scharfes Rot fÃƒÂ¼r den Rand
    backgroundFrame.BorderSizePixel = 1
    backgroundFrame.Parent = screenGui

    -- Text-Label fÃƒÂ¼r die Informationen
    local textLabel = Instance.new("TextLabel") -- ALT DER GANZE BLOCK
    textLabel.Name = "WatermarkLabel"
    textLabel.Size = UDim2.new(1, -10, 1, 0) -- Kleiner Abstand innerhalb des Frames
    textLabel.Position = UDim2.new(0, 5, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Gotham -- Passend zur restlichen UI
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.fromRGB(220, 220, 220) -- Helles Grau fÃƒÂ¼r den Text
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = backgroundFrame

    -- FPS-Anzeige aktualisieren
    RunService.RenderStepped:Connect(function()
        local fps = workspace:GetRealPhysicsFPS()
        textLabel.Text = string.format("aimware.net | gg/dUCNKkS2Ve | %d fps", math.floor(fps))
    end)

    screenGui.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui
end

local function createAimwareWatermark()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimwareWatermark"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "WatermarkContainer"
    mainFrame.AnchorPoint = Vector2.new(1, 0)
    mainFrame.Position = UDim2.new(1, -10, 0, 10)
    mainFrame.Size = UDim2.new(0, 320, 0, 22)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local topBorder = Instance.new("Frame")
    topBorder.Name = "TopBorder"
    topBorder.Size = UDim2.new(1, 0, 0, 2)
    topBorder.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    topBorder.BorderSizePixel = 0
    topBorder.Parent = mainFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "WatermarkLabel"
    textLabel.Size = UDim2.new(1, -10, 1, 0)
    textLabel.Position = UDim2.new(0, 5, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = mainFrame

    -- Text und Sichtbarkeit aktualisieren
    RunService.RenderStepped:Connect(function()
        -- NEU: PrÃ¼ft die globale Einstellung
        mainFrame.Visible = _G.Settings.Watermark_Enabled
        if not mainFrame.Visible then return end

        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        local user = LocalPlayer.Name
        textLabel.Text = string.format("aimware.net | user: %s | ping: %dms", user, ping)
    end)

    screenGui.Parent = game:GetService("CoreGui") or LocalPlayer.PlayerGui
    return mainFrame
end





-- Ersetze die alte createDebugInfo Funktion mit dieser hier
local function createDebugInfo(parentFrame)
    local screenGui = parentFrame.Parent
    local Stats = game:GetService("Stats")
    
    -- Haupt-Container fÃ¼r die Debug-Infos
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "DebugInfoContainer"
    mainFrame.AnchorPoint = Vector2.new(1, 0)
    mainFrame.Size = UDim2.new(0, 320, 0, 155)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Roter oberer Rand
    local topBorder = Instance.new("Frame")
    topBorder.Name = "TopBorder"
    topBorder.Size = UDim2.new(1, 0, 0, 2)
    topBorder.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    topBorder.BorderSizePixel = 0
    topBorder.Parent = mainFrame

    -- Text-Label fÃ¼r die Debug-Infos
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "DebugInfoLabel"
    textLabel.Size = UDim2.new(1, -10, 1, -5)
    textLabel.Position = UDim2.new(0, 5, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.Parent = mainFrame

    -- Text und Sichtbarkeit aktualisieren
    RunService.RenderStepped:Connect(function()
        -- PrÃ¼ft die globale Einstellung, um die Sichtbarkeit zu steuern
        mainFrame.Visible = _G.Settings.DebugInfo_Enabled
        if not mainFrame.Visible then return end
        
        -- Position relativ zum Wasserzeichen aktualisieren
        local watermarkHeight = parentFrame.AbsoluteSize.Y
        local watermarkVisible = _G.Settings.Watermark_Enabled
        mainFrame.Position = UDim2.new(1, -10, 0, (watermarkVisible and watermarkHeight + 15 or 10))

        -- #################################################################
        -- # FINALE KORREKTUR: Robuste Datensammlung und Formatierung
        -- #################################################################
        
        local function getValue(func)
            local success, result = pcall(func)
            return success and result or "N/A"
        end

        -- Sammle alle Debug-Daten auf sichere Weise
        local fps = getValue(function() return math.floor(workspace:GetRealPhysicsFPS()) end)
        
        -- KORREKTUR: Formatiere den Speicherwert VOR string.format
        local memoryValue = getValue(function() return Stats.ClientMemory.Value end)
        local memory = (type(memoryValue) == "number") and string.format("%.1f MB", memoryValue) or "N/A"
        
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        local walkSpeed = humanoid and humanoid.WalkSpeed or "N/A"
        local jumpPower = humanoid and humanoid.JumpPower or "N/A"
        local position = rootPart and rootPart.Position or Vector3.new(0,0,0)
        
        local humanoidState = humanoid and getValue(function() return humanoid:GetState().Name end) or "N/A"
        local gravity = getValue(function() return workspace.Gravity end)
        local playerCount = getValue(function() return #Players:GetPlayers() end)
        local placeId = getValue(function() return game.PlaceId end)
        
        local cameraMode = getValue(function() return Camera.CameraType.Name end)
        local fov = getValue(function() return math.floor(Camera.FieldOfView) end)

        -- Setze den formatierten Text zusammen
        textLabel.Text = string.format(
            "fps: %s | mem: %s\n" ..
            "walkspeed: %s | jumpower: %s\n" ..
            "position: %.0f, %.0f, %.0f\n" ..
            "state: %s | gravity: %s\n" ..
            "camera: %s | fov: %s\n" ..
            "players: %s | placeid: %s",
            tostring(fps), tostring(memory),
            tostring(walkSpeed), tostring(jumpPower),
            position.X, position.Y, position.Z,
            tostring(humanoidState), tostring(gravity),
            tostring(cameraMode), tostring(fov),
            tostring(playerCount), tostring(placeId)
        )
    end)
end



local watermarkFrame = createAimwareWatermark()
createDebugInfo(watermarkFrame)

    -- Standard-Tab aktivieren
    if subTabNav:FindFirstChild("OverlaySubTab") then
        subTabNav.OverlaySubTab.MouseButton1Click:Fire()
    end
end