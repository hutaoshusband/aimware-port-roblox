-- #####################################################################
-- # 0. EXPLOIT-FUNKTIONEN & LOGIK (Fly Script Ersatz)
-- #####################################################################
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Globale Einstellungen fÃ¼r den einfachen Zugriff durch das UI
_G.MiscSettings = {
    FlyEnabled = false,
    FlySpeed = 5
}

_G.MiscSettings.FlingEnabled = false

local flingConnection = nil

-- Funktion fÃ¼r den Fling-Effekt
local function updateFling()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if _G.MiscSettings.FlingEnabled and humanoid and humanoid.Health > 0 then
        if flingConnection then return end -- LÃ¤uft schon

        -- Versetze den Spieler in den Ragdoll-Zustand fÃ¼r den "verbuggten" Look
        humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)

        flingConnection = RunService.Heartbeat:Connect(function()
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            if not (rootPart and _G.MiscSettings.FlingEnabled) then
                -- AufrÃ¤umen, wenn die Funktion deaktiviert wird oder der Charakter weg ist
                if flingConnection then
                    flingConnection:Disconnect()
                    flingConnection = nil
                    -- Versuche, den Spieler wieder auf die Beine zu stellen
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
                return
            end

            -- Erzeuge eine extreme, zufÃ¤llige Kraft
            local force = Vector3.new(
                math.random(-20000, 20000),
                math.random(5000, 25000), -- Gib einen leichten Auftrieb, um nicht nur am Boden zu rutschen
                math.random(-20000, 20000)
            )
            
            -- Wende die Kraft auf den Charakter an
            rootPart.Velocity = force
        end)
    else
        -- Stoppe den Effekt, wenn die Checkbox deaktiviert wird
        if flingConnection then
            flingConnection:Disconnect()
            flingConnection = nil
        end
        -- Stelle sicher, dass der Spieler wieder aufsteht
        if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

_G.MiscSettings.SpinbotEnabled = false
_G.MiscSettings.PitchDownEnabled = false

local spinbotConnection = nil
local pitchDownConnection = nil

-- Funktion fÃ¼r den Spinbot
local function updateSpinbot()
    if _G.MiscSettings.SpinbotEnabled then
        if spinbotConnection then return end -- LÃ¤uft schon

        spinbotConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
            -- Rotiert den Charakter kontinuierlich um die Y-Achse
            local currentCFrame = char.HumanoidRootPart.CFrame
            char.HumanoidRootPart.CFrame = currentCFrame * CFrame.Angles(0, math.rad(15), 0)
        end)
    else
        if spinbotConnection then
            spinbotConnection:Disconnect()
            spinbotConnection = nil
        end
    end
end

-- Funktion fÃ¼r Pitch Down
local function updatePitchDown()
    if _G.MiscSettings.PitchDownEnabled then
        if pitchDownConnection then return end -- LÃ¤uft schon

        pitchDownConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not (humanoid and humanoid.Health > 0) then return end
            
            -- Zwingt die Kamera des Humanoiden, nach unten zu schauen
            -- Dies ist effektiver und weniger stÃ¶rend als die CFrame des RootParts zu Ã¤ndern
            humanoid.CameraOffset = Vector3.new(0, 0, -1000) -- Schaut extrem nach unten
        end)
    else
        if pitchDownConnection then
            pitchDownConnection:Disconnect()
            pitchDownConnection = nil
        end
        -- Setze den Kamera-Offset zurÃ¼ck, wenn die Funktion deaktiviert wird
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
    end
end

local originalLighting = {}
local fullbrightActive = false

local function setFullbright(enabled)
    local lighting = game:GetService("Lighting")

    if enabled and not fullbrightActive then
        -- Speichere die originalen Einstellungen, falls noch nicht geschehen
        if next(originalLighting) == nil then
            originalLighting.Brightness = lighting.Brightness
            originalLighting.ClockTime = lighting.ClockTime
            originalLighting.FogEnd = lighting.FogEnd
            originalLighting.GlobalShadows = lighting.GlobalShadows
            originalLighting.Ambient = lighting.Ambient
            originalLighting.ColorCorrection = lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        end

        -- Wende Fullbright-Einstellungen an
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogEnd = 100000
        lighting.GlobalShadows = false
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        
        -- Entferne eventuelle Farbkorrekturen
        if originalLighting.ColorCorrection then
            originalLighting.ColorCorrection.Enabled = false
        end
        
        fullbrightActive = true

    elseif not enabled and fullbrightActive then
        -- Stelle die originalen Einstellungen wieder her, falls vorhanden
        if next(originalLighting) ~= nil then
            lighting.Brightness = originalLighting.Brightness
            lighting.ClockTime = originalLighting.ClockTime
            lighting.FogEnd = originalLighting.FogEnd
            lighting.GlobalShadows = originalLighting.GlobalShadows
            lighting.Ambient = originalLighting.Ambient
            
            if originalLighting.ColorCorrection then
                originalLighting.ColorCorrection.Enabled = true
            end
            
            -- Leere die Tabelle, um fÃ¼r die nÃ¤chste Aktivierung bereit zu sein
            originalLighting = {}
        end
        
        fullbrightActive = false
    end
end

_G.MiscSettings.FlingEnabled = false

-- Ãœberarbeitete und stabile FE Fly-Funktion
local flyConnection = nil
local bodyGyro, bodyVelocity

-- Funktion zum sauberen Beenden des Flugmodus
local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    -- Setze den Zustand des Humanoiden zurÃ¼ck
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
end

-- Funktion zum Starten des Flugmodus
local function startFly()
    stopFly() -- Stellt sicher, dass keine alten Instanzen laufen, bevor neue erstellt werden

    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    -- Beenden, wenn der Charakter oder Humanoid nicht existiert
    if not humanoid or not humanoid.RootPart then return end

    -- Erstelle die notwendigen BodyMover fÃ¼r den Flug
    bodyGyro = Instance.new("BodyGyro", humanoid.RootPart)
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = humanoid.RootPart.CFrame

    bodyVelocity = Instance.new("BodyVelocity", humanoid.RootPart)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.new(0, 0.1, 0) -- Leichtes Schweben, um nicht zu fallen

    -- Die Hauptschleife, die den Flug steuert
    flyConnection = RunService.RenderStepped:Connect(function()
        local currentHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        -- Stoppe den Flug, wenn die Funktion deaktiviert wird oder der Spieler stirbt
        if not _G.MiscSettings.FlyEnabled or not (currentHumanoid and currentHumanoid.Health > 0) then
            stopFly()
            return
        end
        
        local camera = workspace.CurrentCamera
        local speed = _G.MiscSettings.FlySpeed
        local moveVector = Vector3.new()

        -- Tastenabfrage fÃ¼r die Bewegung
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camera.CFrame.RightVector end
        
        -- Setze die Geschwindigkeit und Richtung
        if moveVector.Magnitude > 0 then
            bodyVelocity.Velocity = moveVector.Unit * speed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0.1, 0) -- HÃ¤lt den Spieler in der Luft
        end
        
        -- Richte den Spieler nach der Kamera aus und aktiviere PlatformStand
        bodyGyro.CFrame = camera.CFrame
        currentHumanoid.PlatformStand = true
    end)
end

_G.MiscSettings.SpinbotEnabled = false

return function(parent)
    -- #####################################################################
    -- # 1. UI-BIBLIOTHEK (Finale Version fÃ¼r konsistentes Design)
    -- #####################################################################
    -- NEUE, KORRIGIERTE createGroup FUNKTION
-- FINALE, KORREKTE createGroup FUNKTION
local function createGroup(p, title)
    -- Der Container fÃ¼r die Gruppe. WICHTIG: Feste Breite, damit mehrere nebeneinander passen.
    local groupContainer = Instance.new("Frame")
    groupContainer.BackgroundTransparency = 1
    groupContainer.Size = UDim2.new(0, 220, 0, 0) -- Feste Breite von 220px, HÃ¶he automatisch
    groupContainer.AutomaticSize = Enum.AutomaticSize.Y
    groupContainer.Parent = p

    -- Der sichtbare Hintergrund mit der 1px Outline
    local groupBackground = Instance.new("Frame"); groupBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50); groupBackground.BorderSizePixel = 0; groupBackground.Size = UDim2.new(1, 0, 1, 0); groupBackground.Parent = groupContainer
    local innerFrame = Instance.new("Frame"); innerFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35); innerFrame.BorderSizePixel = 0; innerFrame.Position = UDim2.new(0, 1, 0, 1); innerFrame.Size = UDim2.new(1, -2, 1, -2); innerFrame.Parent = groupBackground
    
    -- Layout und Padding fÃ¼r den INHALT der Gruppe
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 5); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = innerFrame; layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 30); padding.PaddingBottom = UDim.new(0, 10); padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10); padding.Parent = innerFrame
    
    local titleLabel = Instance.new("TextLabel"); titleLabel.Name = "Title"; titleLabel.Size = UDim2.new(1, 0, 0, 25); titleLabel.Position = UDim2.new(0, 0, 0, 0); titleLabel.BackgroundTransparency = 1; titleLabel.Font = Enum.Font.GothamBold; titleLabel.Text = "  " .. title; titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220); titleLabel.TextSize = 14; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Parent = innerFrame
    
    return innerFrame
end



    local function createSlider(p, text, min, max, start, callback)
        local container = Instance.new("Frame"); container.Size = UDim2.new(1, 0, 0, 40); container.BackgroundTransparency = 1; container.Parent = p
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.5, 0, 0, 20); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamBold; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local valueLabel = Instance.new("TextLabel"); valueLabel.Size = UDim2.new(0.5, 0, 0, 20); valueLabel.Position = UDim2.new(0.5, 0, 0, 0); valueLabel.BackgroundTransparency = 1; valueLabel.Font = Enum.Font.GothamBold; valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200); valueLabel.TextSize = 14; valueLabel.TextXAlignment = Enum.TextXAlignment.Right; valueLabel.Parent = container
        local track = Instance.new("Frame"); track.Size = UDim2.new(1, 0, 0, 4); track.Position = UDim2.new(0, 0, 0, 25); track.BackgroundColor3 = Color3.fromRGB(20, 20, 20); track.Parent = container
        local fill = Instance.new("Frame"); fill.BackgroundColor3 = Color3.fromRGB(200, 40, 40); fill.Parent = track
        local thumb = Instance.new("Frame"); thumb.Size = UDim2.fromOffset(12, 12); thumb.Position = UDim2.new(0, -6, 0.5, -6); thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); thumb.Parent = track
        local thumbCorner = Instance.new("UICorner"); thumbCorner.CornerRadius = UDim.new(1, 0); thumbCorner.Parent = thumb
        local dragging = false
        local function updateSlider(inputPos)
            local percent = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * percent + 0.5)
            valueLabel.Text = tostring(value); fill.Size = UDim2.new(percent, 0, 1, 0); thumb.Position = UDim2.new(percent, -6, 0.5, -6)
            if callback then callback(value) end
        end
        track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; updateSlider(input.Position) end end)
        track.InputEnded:Connect(function() dragging = false end)
        game:GetService("UserInputService").InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input.Position) end end)
        local startPercent = (start - min) / (max - min)
        valueLabel.Text = tostring(start); fill.Size = UDim2.new(startPercent, 0, 1, 0); thumb.Position = UDim2.new(startPercent, -6, 0.5, -6)
    end

    local function createCheckbox(p, text, description, callback)
        local container = Instance.new("Frame"); container.Size = UDim2.new(1, 0, 0, 30); container.BackgroundTransparency = 1; container.Parent = p
        local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(14, 14); box.Position = UDim2.new(0, 0, 0.5, -7); box.BackgroundColor3 = Color3.fromRGB(50, 50, 50); box.Parent = container
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 3); corner.Parent = box
        local checkmark = Instance.new("TextLabel"); checkmark.Size = UDim2.fromOffset(14, 14); checkmark.BackgroundTransparency = 1; checkmark.Font = Enum.Font.GothamBold; checkmark.Text = "âœ”"; checkmark.TextColor3 = Color3.fromRGB(255, 255, 255); checkmark.TextSize = 12; checkmark.Visible = false; checkmark.Parent = box
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -20, 0, 20); label.Position = UDim2.new(0, 20, 0, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1, -20, 0, 15); desc.Position = UDim2.new(0, 20, 0, 15); desc.BackgroundTransparency = 1; desc.Font = Enum.Font.Gotham; desc.Text = description; desc.TextColor3 = Color3.fromRGB(120, 120, 120); desc.TextSize = 12; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Parent = container
        local button = Instance.new("TextButton"); button.Size = UDim2.new(1, 0, 1, 0); button.BackgroundTransparency = 1; button.Text = ""; button.Parent = container
        button.MouseButton1Click:Connect(function() checkmark.Visible = not checkmark.Visible; if callback then callback(checkmark.Visible) end end)
        if isRisky then
        local riskyLabel = Instance.new("TextLabel")
        riskyLabel.Name = "RiskyLabel"
        riskyLabel.Size = UDim2.new(0, 100, 1, 0) -- Nimmt den verfÃ¼gbaren Platz ein
        riskyLabel.Position = UDim2.new(1, -100, 0, 0) -- Positioniert sich rechts
        riskyLabel.BackgroundTransparency = 1
        riskyLabel.Font = Enum.Font.GothamBold
        riskyLabel.Text = "(risky)"
        riskyLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Leuchtendes Rot
        riskyLabel.TextSize = 12
        riskyLabel.TextXAlignment = Enum.TextXAlignment.Right
        riskyLabel.Parent = container -- FÃ¼gt es zum Hauptcontainer der Checkbox hinzu
    end
end
    
    local function createButton(p, text, description, callback)
        local container = Instance.new("Frame"); container.Size = UDim2.new(1, 0, 0, 30); container.BackgroundTransparency = 1; container.Parent = p
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 120, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); btn.Font = Enum.Font.Gotham; btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.TextSize = 14; btn.Parent = container
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 3); corner.Parent = btn
        local descLabel = Instance.new("TextLabel"); descLabel.Size = UDim2.new(1, -130, 1, 0); descLabel.Position = UDim2.new(0, 130, 0, 0); descLabel.BackgroundTransparency = 1; descLabel.Font = Enum.Font.Gotham; descLabel.Text = description; descLabel.TextColor3 = Color3.fromRGB(120, 120, 120); descLabel.TextSize = 12; descLabel.TextXAlignment = Enum.TextXAlignment.Left; descLabel.Parent = container
        if callback then btn.MouseButton1Click:Connect(callback) end
    end

    -- #####################################################################
    -- # 2. HAUPTSTRUKTUR (KORRIGIERT FÃœR SCROLLING & LAYOUT)
    -- #####################################################################
    local subTabNav = Instance.new("Frame"); subTabNav.Name = "SubTabNav"; subTabNav.Size = UDim2.new(0, 150, 1, 0); subTabNav.BackgroundColor3 = Color3.fromRGB(40, 40, 40); subTabNav.BorderSizePixel = 0; subTabNav.Parent = parent
    local contentArea = Instance.new("Frame"); contentArea.Name = "ContentArea"; contentArea.Size = UDim2.new(1, -150, 1, 0); contentArea.Position = UDim2.new(0, 150, 0, 0); contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = parent
    
    local subTabs = {"Exploit", "Troll"}; local subTabFrames = {}; local activeSubTabButton = nil

    for i, tabName in ipairs(subTabs) do
        local btn = Instance.new("TextButton"); btn.Name = tabName .. "SubTab"; btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.BorderSizePixel = 0; btn.Font = Enum.Font.Gotham; btn.Text = "  " .. tabName; btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = subTabNav
        local indicator = Instance.new("Frame"); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 3, 1, 0); indicator.BackgroundColor3 = Color3.fromRGB(200, 40, 40); indicator.BorderSizePixel = 0; indicator.Visible = false; indicator.Parent = btn
    
    -- HIER IST DIE Ã„NDERUNG: Wir benutzen einen ScrollingFrame
    -- KORREKTUR: Wir verwenden einen ScrollingFrame, damit der Inhalt scrollbar ist.
        local content = Instance.new("ScrollingFrame"); content.Name = tabName .. "Content"
        content.Size = UDim2.new(1, 0, 1, 0)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Visible = false
        content.Parent = contentArea
        content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80) -- Scrollbar-Farbe
        content.ScrollBarThickness = 6 -- Dicke der Scrollbar
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y -- WICHTIG: Passt die Scroll-GrÃ¶ÃŸe automatisch an

        -- KORREKTUR: Dieses Layout ordnet die Gruppen (Spalten) an.
        local layout = Instance.new("UIListLayout"); 
        layout.Padding = UDim.new(0, 15); -- Abstand zwischen den Gruppen
        layout.FillDirection = Enum.FillDirection.Horizontal -- Gruppen nebeneinander anordnen
        layout.SortOrder = Enum.SortOrder.LayoutOrder; 
        layout.Parent = content; 
        layout.VerticalAlignment = Enum.VerticalAlignment.Top -- Gruppen oben ausrichten

        subTabFrames[tabName] = content
        btn.MouseButton1Click:Connect(function() 
            if activeSubTabButton then 
                activeSubTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40); 
                activeSubTabButton.TextColor3 = Color3.fromRGB(180, 180, 180); 
                activeSubTabButton.Indicator.Visible = false 
            end; 
            for _, f in pairs(subTabFrames) do f.Visible = false end; 
            content.Visible = true; 
            btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55); 
            btn.TextColor3 = Color3.fromRGB(200, 40, 40); 
            indicator.Visible = true; 
            activeSubTabButton = btn 
        end)
    end


    -- #####################################################################
    -- # 2. HAUPTSTRUKTUR (mit Sub-Tabs)
    -- #####################################################################
    local subTabNav = Instance.new("Frame"); subTabNav.Name = "SubTabNav"; subTabNav.Size = UDim2.new(0, 150, 1, 0); subTabNav.BackgroundColor3 = Color3.fromRGB(40, 40, 40); subTabNav.BorderSizePixel = 0; subTabNav.Parent = parent
    local contentArea = Instance.new("Frame"); contentArea.Name = "ContentArea"; contentArea.Size = UDim2.new(1, -150, 1, 0); contentArea.Position = UDim2.new(0, 150, 0, 0); contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = parent
    local subTabs = {"Movement", "Combat", "Utility", "Troll"}; local subTabFrames = {}; local activeSubTabButton = nil
    for i, tabName in ipairs(subTabs) do
        local btn = Instance.new("TextButton"); btn.Name = tabName .. "SubTab"; btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.BorderSizePixel = 0; btn.Font = Enum.Font.Gotham; btn.Text = "  " .. tabName; btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = subTabNav
        local indicator = Instance.new("Frame"); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 3, 1, 0); indicator.BackgroundColor3 = Color3.fromRGB(200, 40, 40); indicator.BorderSizePixel = 0; indicator.Visible = false; indicator.Parent = btn
        local content = Instance.new("Frame"); content.Name = tabName .. "Content"; content.Size = UDim2.new(1, 0, 1, 0); content.BackgroundTransparency = 1; content.Visible = false; content.Parent = contentArea
        local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = content
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- LinksbÃ¼ndige Ausrichtung fÃ¼r die Gruppen
        subTabFrames[tabName] = content
        btn.MouseButton1Click:Connect(function() if activeSubTabButton then activeSubTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40); activeSubTabButton.TextColor3 = Color3.fromRGB(180, 180, 180); activeSubTabButton.Indicator.Visible = false end; for _, f in pairs(subTabFrames) do f.Visible = false end; content.Visible = true; btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55); btn.TextColor3 = Color3.fromRGB(200, 40, 40); indicator.Visible = true; activeSubTabButton = btn end)
    end

    -- #####################################################################
    -- # 3. INHALTE FÃœR DIE SUB-TABS (NEU AUFGETEILT)
    -- #####################################################################
    
    -- -- Inhalt fÃ¼r "Movement" -- --
    local movementContent = subTabFrames["Movement"]
    local movementGroup = createGroup(movementContent, "Movement")
    
    createCheckbox(movementGroup, "Fly", "Allows you to fly.", function(enabled)
        _G.MiscSettings.FlyEnabled = enabled
        if enabled then startFly() else stopFly() end
    end)
    
    createSlider(movementGroup, "Fly Speed", 1, 100, 5, function(value)
        _G.MiscSettings.FlySpeed = value
    end)

    createSlider(movementGroup, "Walk Speed", 16, 200, 16, function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end)

    createSlider(movementGroup, "Jump Power", 50, 300, 50, function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = value
        end
    end)
    
    -- -- Inhalt fÃ¼r "Combat" -- --
    local combatContent = subTabFrames["Combat"]
    local combatGroup = createGroup(combatContent, "Combat")

    createCheckbox(combatGroup, "Spinbot", "Makes your character spin.", function(enabled)
        _G.MiscSettings.SpinbotEnabled = enabled
        updateSpinbot()
    end)
    createCheckbox(combatGroup, "Pitch Down", "Forces your camera to look down.", function(enabled)
        _G.MiscSettings.PitchDownEnabled = enabled
        updatePitchDown()
    end, true)
    createCheckbox(combatGroup, "Fling", "Makes your character fling around.", function(enabled)
        _G.MiscSettings.FlingEnabled = enabled
        updateFling()
    end, true)

    -- -- Inhalt fÃ¼r "Utility" -- --
    local utilityContent = subTabFrames["Utility"]
    local utilityGroup = createGroup(utilityContent, "Utility")

    createButton(utilityGroup, "Infinity Yield", "Run the Infinity Yield admin script.", function()
    -- Diese Funktion wird ausgefÃ¼hrt, wenn der Button geklickt wird
    spawn(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/edgeiy/infiniteyield/master/source" ))()
    end)
end)
    createCheckbox(utilityGroup, "Fullbright", "Maximizes brightness for visibility.", function(enabled)
        setFullbright(enabled)
    end)

    -- -- Inhalt fÃ¼r "Troll" -- --
    local trollContent = subTabFrames["Troll"]
    local trollGroup = createGroup(trollContent, "Trolling")
    createCheckbox(trollGroup, "Fall", "Makes other players trip.", function(enabled) print("Fall: " .. tostring(enabled)) end)


    -- #####################################################################
    -- # 4. STANDARD-TAB AKTIVIEREN
    -- #####################################################################
            if subTabNav:FindFirstChild("MovementSubTab") then
        subTabNav.MovementSubTab.MouseButton1Click:Fire()
    end
end
