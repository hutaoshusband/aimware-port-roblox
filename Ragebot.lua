-- Ragebot.lua - Version 12 (Kombiniert UI-Vorlage mit funktionierender Aimbot-Logik)

return function(parent)
    -- #####################################################################
    -- # 1. AIMBOT-LOGIK & EINSTELLUNGEN (Aus dem neuen Skript)
    -- #####################################################################
    local dwCamera = workspace.CurrentCamera
    local dwRunService = game:GetService("RunService")
    local dwUIS = game:GetService("UserInputService")
    local dwEntities = game:GetService("Players")
    local dwLocalPlayer = dwEntities.LocalPlayer
    local dwMouse = dwLocalPlayer:GetMouse()

    -- Globale Einstellungen fÃ¼r den Aimbot, die wir per UI steuern
    _G.RageSettings = {
        Aimbot_Enabled = false,
        Aimbot_Silent = false, -- Platzhalter fÃ¼r Silent Aim
        Aimbot_Aiming = false,
        Aimbot_AimPart = "Head",
        Aimbot_TeamCheck = false,
        Aimbot_VisibleCheck = false,
        Aimbot_Draw_FOV = true,
        Aimbot_FOV_Radius = 200,
        Aimbot_FOV_Color = Color3.fromRGB(255, 255, 255),
        Aimbot_Key = Enum.KeyCode.LeftShift,
        AntiAim_Enabled = false,
        AntiAim_Spinbot = false,
        AntiAim_Jitter = false,
        AntiAim_JitterAngle = 180,
        AntiAim_PitchUp = false,
        Aimbot_AutoFire = false,
        Aimbot_FireDelay = 0.1 -- VerzÃ¶gerung in Sekunden (100ms)
    }

    -- Funktion zur SichtbarkeitsprÃ¼fung
    local function inlos(p, ...)
        return #dwCamera:GetPartsObscuringTarget({p}, {dwCamera, dwLocalPlayer.Character, ...}) == 0
    end

    -- FOV-Kreis erstellen
    local fovcircle = Drawing.new("Circle")
    fovcircle.Visible = false -- Wird nur sichtbar, wenn Aimbot an ist
    fovcircle.Radius = _G.RageSettings.Aimbot_FOV_Radius
    fovcircle.Color = _G.RageSettings.Aimbot_FOV_Color
    fovcircle.Thickness = 1
    fovcircle.Filled = false
    fovcircle.Transparency = 1
    fovcircle.Position = Vector2.new(dwCamera.ViewportSize.X / 2, dwCamera.ViewportSize.Y / 2)
    local lastFireTime = 0

    -- Haupt-Aimbot-Schleife
    dwRunService.RenderStepped:Connect(function()
        -- Nur ausfÃ¼hren, wenn Aimbot aktiviert und die Taste gedrÃ¼ckt wird
        if not _G.RageSettings.Aimbot_Enabled or not _G.RageSettings.Aimbot_Aiming then
            fovcircle.Visible = false
            return
        end

        fovcircle.Visible = _G.RageSettings.Aimbot_Draw_FOV
        fovcircle.Radius = _G.RageSettings.Aimbot_FOV_Radius
        
        
        local dist = math.huge
        local closest_char = nil

        for i, v in next, dwEntities:GetChildren() do
            if v ~= dwLocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                if not _G.RageSettings.Aimbot_TeamCheck or v.Team ~= dwLocalPlayer.Team then
                    local char = v.Character
                                        -- NEUE LOGIK: Priorisierung nach 3D-Distanz
                    local myRoot = dwLocalPlayer.Character and dwLocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end -- SicherheitsprÃ¼fung

                    -- Berechne die physische Distanz zwischen dir und dem Ziel
                    local mag = (myRoot.Position - char.HumanoidRootPart.Position).Magnitude
                    
                    -- PrÃ¼fe, ob das Ziel im FOV-Kreis ist
                    local targetPos, onScreen = dwCamera:WorldToScreenPoint(char[_G.RageSettings.Aimbot_AimPart].Position)
                    local fov_dist = (Vector2.new(dwMouse.X, dwMouse.Y) - Vector2.new(targetPos.X, targetPos.Y)).Magnitude

                    -- Bedingung: Ziel muss auf dem Bildschirm sein, im FOV sein UND nÃ¤her sein als das bisherige Ziel
                    if onScreen and fov_dist < _G.RageSettings.Aimbot_FOV_Radius and mag < dist then
                        dist = mag -- Speichere die 3D-Distanz als neuen Rekord
                        closest_char = char
                    end

                end
            end
        end

        if closest_char and closest_char.Humanoid.Health > 0 then
            local targetPart = closest_char:FindFirstChild(_G.RageSettings.Aimbot_AimPart)
            if not targetPart then return end -- SicherheitsprÃ¼fung

            local isVisible = inlos(targetPart.Position, closest_char)

            if not _G.RageSettings.Aimbot_VisibleCheck or isVisible then
                -- Ziel anvisieren
                dwCamera.CFrame = CFrame.new(dwCamera.CFrame.Position, targetPart.Position)

                -- AUTOFIRE LOGIK
                if _G.RageSettings.Aimbot_AutoFire and isVisible then
                    local currentTime = tick()
                    -- Rechne den Delay von Millisekunden in Sekunden um
                    local fireDelay = _G.RageSettings.Aimbot_FireDelay / 1000 

                    if currentTime - lastFireTime >= fireDelay then
                        -- Feuern!
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1) -- DrÃ¼cken
                        wait(0.01) -- Kurze VerzÃ¶gerung, damit das Spiel den Klick registriert
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1) -- Loslassen
                        
                        lastFireTime = currentTime -- Zeit des letzten Schusses aktualisieren
                    end
                end
            end
        end
    end)

    -- Anti-Aim-Logik (ca. Zeile 102)
    local spinAngle = 0
    dwRunService.RenderStepped:Connect(function()
        if not _G.RageSettings.AntiAim_Enabled then return end
        
        local player = dwEntities.LocalPlayer
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not rootPart then return end

        local currentCFrame = rootPart.CFrame
        
        -- Standard-Winkel definieren
        local pitch = 0 -- Normaler Pitch
        local yaw = currentCFrame.Rotation.Y -- Aktueller Yaw
        local roll = 0 -- Normaler Roll

        -- Pitch-Logik anwenden, falls aktiviert
        if _G.RageSettings.AntiAim_PitchUp then
            pitch = math.rad(-90) -- -90 Grad, um steil nach oben zu schauen
        end

        -- Option 1: Spinbot
        if _G.RageSettings.AntiAim_Spinbot then
            spinAngle = (spinAngle + 45) % 360 -- Schnellere Geschwindigkeit
            yaw = math.rad(spinAngle) -- Ãœberschreibe den Yaw mit dem Spin-Winkel
            rootPart.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(pitch, yaw, roll)
            return
        end

        -- Option 2: Jitter
        if _G.RageSettings.AntiAim_Jitter then
            local jitterAngle = math.rad(_G.RageSettings.AntiAim_JitterAngle)
            
            if tick() % 0.1 < 0.05 then -- Schnellerer Jitter
                yaw = currentCFrame.Rotation.Y + jitterAngle
            else
                yaw = dwCamera.CFrame.Rotation.Y
            end
            rootPart.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(pitch, yaw, roll)
            return
        end

        -- Falls nur Pitch Up an ist, ohne Spin oder Jitter
        if _G.RageSettings.AntiAim_PitchUp then
             rootPart.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(pitch, yaw, roll)
        end
    end)



    -- Tasten-Logik zum Aktivieren des Aimings
    dwUIS.InputBegan:Connect(function(input)
        if input.KeyCode == _G.RageSettings.Aimbot_Key then
            _G.RageSettings.Aimbot_Aiming = true
        end
    end)
    dwUIS.InputEnded:Connect(function(input)
        if input.KeyCode == _G.RageSettings.Aimbot_Key then
            _G.RageSettings.Aimbot_Aiming = false
        end
    end)

    -- #####################################################################
    -- # 2. UI-BIBLIOTHEK (Angepasst fÃ¼r funktionale Checkboxen)
    -- #####################################################################

    local function createCheckbox(p, position, text, description, configKey)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, 0, 0, 35); container.BackgroundTransparency = 1; container.Parent = p
        local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(14, 14); box.Position = UDim2.new(0, 0, 0.5, -7); box.BackgroundColor3 = Color3.fromRGB(50, 50, 50); box.Parent = container
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 3); corner.Parent = box
        local checkmark = Instance.new("TextLabel"); checkmark.Size = UDim2.fromOffset(14, 14); checkmark.BackgroundTransparency = 1; checkmark.Font = Enum.Font.GothamBold; checkmark.Text = "âœ”"; checkmark.TextColor3 = Color3.fromRGB(255, 255, 255); checkmark.TextSize = 12; checkmark.Visible = _G.RageSettings[configKey]; checkmark.Parent = box
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -20, 0, 20); label.Position = UDim2.new(0, 20, 0, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1, -20, 0, 15); desc.Position = UDim2.new(0, 20, 0, 15); desc.BackgroundTransparency = 1; desc.Font = Enum.Font.Gotham; desc.Text = description; desc.TextColor3 = Color3.fromRGB(120, 120, 120); desc.TextSize = 12; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Parent = container
        local button = Instance.new("TextButton"); button.Size = UDim2.new(1, 0, 1, 0); button.BackgroundTransparency = 1; button.Text = ""; button.Parent = container
        
        button.MouseButton1Click:Connect(function()
            _G.RageSettings[configKey] = not _G.RageSettings[configKey]
            checkmark.Visible = _G.RageSettings[configKey]
        end)
        return container
    end
        local function createSlider(p, position, text, min, max, start, configKey)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 40); container.BackgroundTransparency = 1; container.Parent = p
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
            _G.RageSettings[configKey] = value
        end
        track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; updateSlider(input.Position) end end)
        track.InputEnded:Connect(function() dragging = false end)
        game:GetService("UserInputService").InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input.Position) end end)
        local startPercent = (start - min) / (max - min)
        valueLabel.Text = tostring(start); fill.Size = UDim2.new(startPercent, 0, 1, 0); thumb.Position = UDim2.new(startPercent, -6, 0.5, -6)
    end

    local function createKeybinder(p, position, text, configKey)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 35); container.BackgroundTransparency = 1; container.Parent = p
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.5, 0, 1, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local keyButton = Instance.new("TextButton"); keyButton.Size = UDim2.new(0.5, 0, 1, 0); keyButton.Position = UDim2.new(0.5, 0, 0, 0); keyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50); keyButton.Font = Enum.Font.Gotham; keyButton.TextColor3 = Color3.fromRGB(200, 200, 200); keyButton.TextSize = 14; keyButton.Parent = container
        keyButton.Text = tostring(_G.RageSettings[configKey].Name)

        keyButton.MouseButton1Click:Connect(function()
            keyButton.Text = "[...]"
            local connection
            connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    _G.RageSettings[configKey] = input.KeyCode
                    keyButton.Text = tostring(input.KeyCode.Name)
                    connection:Disconnect()
                end
            end)
        end)
    end


    -- #####################################################################
    -- # 3. HAUPTSTRUKTUR (UnverÃ¤ndert)
    -- #####################################################################
    local subTabNav = Instance.new("Frame"); subTabNav.Name = "SubTabNav"; subTabNav.Size = UDim2.new(0, 150, 1, 0); subTabNav.BackgroundColor3 = Color3.fromRGB(40, 40, 40); subTabNav.BorderSizePixel = 0; subTabNav.Parent = parent
    local contentArea = Instance.new("Frame"); contentArea.Name = "ContentArea"; contentArea.Size = UDim2.new(1, -150, 1, 0); contentArea.Position = UDim2.new(0, 150, 0, 0); contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0; contentArea.ClipsDescendants = true; contentArea.Parent = parent
    local subTabs = {"Aimbot", "Accuracy", "Hitscan", "Anti-Aim"}; local subTabFrames = {}; local activeSubTabButton = nil
    for i, tabName in ipairs(subTabs) do
        local btn = Instance.new("TextButton"); btn.Name = tabName .. "SubTab"; btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.BorderSizePixel = 0; btn.Font = Enum.Font.Gotham; btn.Text = "  " .. tabName; btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = subTabNav
        local indicator = Instance.new("Frame"); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 3, 1, 0); indicator.BackgroundColor3 = Color3.fromRGB(200, 40, 40); indicator.BorderSizePixel = 0; indicator.Visible = false; indicator.Parent = btn
        local content = Instance.new("Frame"); content.Name = tabName .. "Content"; content.Size = UDim2.new(1, 0, 1, 0); content.BackgroundTransparency = 1; content.Visible = false; content.Parent = contentArea
        subTabFrames[tabName] = content
        btn.MouseButton1Click:Connect(function() if activeSubTabButton then activeSubTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40); activeSubTabButton.TextColor3 = Color3.fromRGB(180, 180, 180); activeSubTabButton.Indicator.Visible = false end; for _, f in pairs(subTabFrames) do f.Visible = false end; content.Visible = true; btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55); btn.TextColor3 = Color3.fromRGB(200, 40, 40); indicator.Visible = true; activeSubTabButton = btn end)
    end

    -- #####################################################################
    -- # 4. INHALTE FÃœR ALLE TABS ERSTELLEN (Jetzt mit funktionierender Logik)
    -- #####################################################################

    -- -- 4.1 Inhalt fÃ¼r "Aimbot" -- --
    local aimbotContent = subTabFrames["Aimbot"]
    local aimbotGroup = Instance.new("Frame"); aimbotGroup.Position = UDim2.new(0, 10, 0, 10); aimbotGroup.Size = UDim2.new(0.5, -15, 0, 185); aimbotGroup.BackgroundColor3 = Color3.fromRGB(35, 35, 35); aimbotGroup.Parent = aimbotContent
    local agTitle = Instance.new("TextLabel"); agTitle.Size=UDim2.new(1,0,0,25); agTitle.BackgroundTransparency=1; agTitle.Font=Enum.Font.GothamBold; agTitle.Text="  Aimbot"; agTitle.TextColor3=Color3.fromRGB(220,220,220); agTitle.TextSize=14; agTitle.TextXAlignment=Enum.TextXAlignment.Left; agTitle.Parent=aimbotGroup
    createCheckbox(aimbotGroup, UDim2.new(0, 10, 0, 30), "Enable Aimbot", "Master toggle for the aimbot.", "Aimbot_Enabled")
    createCheckbox(aimbotGroup, UDim2.new(0, 10, 0, 65), "Silent Aim", "Aim is not visible on your screen.", "Aimbot_Silent")
    createCheckbox(aimbotGroup, UDim2.new(0, 10, 0, 30), "Enable Aimbot", "Master toggle for the aimbot.", "Aimbot_Enabled")
    createCheckbox(aimbotGroup, UDim2.new(0, 10, 0, 65), "Silent Aim", "Aim is not visible on your screen.", "Aimbot_Silent")

    -- HIER EINFÃœGEN:
    createSlider(aimbotGroup, UDim2.new(0, 10, 0, 100), "FOV Radius", 10, 500, 200, "Aimbot_FOV_Radius")
    createKeybinder(aimbotGroup, UDim2.new(0, 10, 0, 140), "Aimbot Key", "Aimbot_Key")

    -- -- 4.2 Inhalt fÃ¼r "Accuracy" -- --
    local accuracyContent = subTabFrames["Accuracy"]
    local accuracyGroup = Instance.new("Frame"); accuracyGroup.Position = UDim2.new(0, 10, 0, 10); accuracyGroup.Size = UDim2.new(0.5, -15, 0, 195); accuracyGroup.BackgroundColor3 = Color3.fromRGB(35, 35, 35); accuracyGroup.Parent = accuracyContent
    local accTitle = Instance.new("TextLabel"); accTitle.Size=UDim2.new(1,0,0,25); accTitle.BackgroundTransparency=1; accTitle.Font=Enum.Font.GothamBold; accTitle.Text="  Accuracy"; accTitle.TextColor3=Color3.fromRGB(220,220,220); accTitle.TextSize=14; accTitle.TextXAlignment=Enum.TextXAlignment.Left; accTitle.Parent=accuracyGroup
    createCheckbox(accuracyGroup, UDim2.new(0, 10, 0, 30), "Team Check", "Only aim at enemies.", "Aimbot_TeamCheck")
    createCheckbox(accuracyGroup, UDim2.new(0, 10, 0, 65), "Visible Check", "Only aim at visible players.", "Aimbot_VisibleCheck")
    createCheckbox(accuracyGroup, UDim2.new(0, 10, 0, 100), "Auto Fire", "Automatically shoots at the target.", "Aimbot_AutoFire")
    createSlider(accuracyGroup, UDim2.new(0, 10, 0, 135), "Fire Delay (ms)", 50, 500, 100, "Aimbot_FireDelay")

    -- -- 4.3 Inhalt fÃ¼r "Hitscan" (Leer, da keine Logik dafÃ¼r vorhanden war) -- --
    local hitscanContent = subTabFrames["Hitscan"]
    local hitscanGroup = Instance.new("Frame"); hitscanGroup.Position = UDim2.new(0, 10, 0, 10); hitscanGroup.Size = UDim2.new(0.5, -15, 0, 120); hitscanGroup.BackgroundColor3 = Color3.fromRGB(35, 35, 35); hitscanGroup.Parent = hitscanContent
    local hsTitle = Instance.new("TextLabel"); hsTitle.Size=UDim2.new(1,0,0,25); hsTitle.BackgroundTransparency=1; hsTitle.Font=Enum.Font.GothamBold; hsTitle.Text="  Hitscan"; hsTitle.TextColor3=Color3.fromRGB(220,220,220); hsTitle.TextSize=14; hsTitle.TextXAlignment=Enum.TextXAlignment.Left; hsTitle.Parent=hitscanGroup
    -- Hier kÃ¶nnten spÃ¤ter Hitscan-Optionen hinzugefÃ¼gt werden

    -- -- 4.4 Inhalt fÃ¼r "Anti-Aim" -- --
    local antiAimContent = subTabFrames["Anti-Aim"]
    -- HÃ¶he der Box von 150 auf 190 erhÃ¶hen
    local antiAimGroup = Instance.new("Frame"); antiAimGroup.Position = UDim2.new(0, 10, 0, 10); antiAimGroup.Size = UDim2.new(0.5, -15, 0, 225); antiAimGroup.BackgroundColor3 = Color3.fromRGB(35, 35, 35); antiAimGroup.Parent = antiAimContent
    local aaTitle = Instance.new("TextLabel"); aaTitle.Size=UDim2.new(1,0,0,25); aaTitle.BackgroundTransparency=1; aaTitle.Font=Enum.Font.GothamBold; aaTitle.Text="  Anti-Aim"; aaTitle.TextColor3=Color3.fromRGB(220,220,220); aaTitle.TextSize=14; aaTitle.TextXAlignment=Enum.TextXAlignment.Left; aaTitle.Parent=antiAimGroup
    
    createCheckbox(antiAimGroup, UDim2.new(0, 10, 0, 30), "Enable Anti-Aim", "Master toggle for all AA features.", "AntiAim_Enabled")
    createCheckbox(antiAimGroup, UDim2.new(0, 10, 0, 65), "Spinbot", "You spin me right 'round, baby.", "AntiAim_Spinbot")
    createCheckbox(antiAimGroup, UDim2.new(0, 10, 0, 100), "Jitter", "Randomly shakes your character.", "AntiAim_Jitter")
    local pitchUpCheckbox = createCheckbox(antiAimGroup, UDim2.new(0, 10, 0, 180), "Pitch Up", "Forces your character to look up.", "AntiAim_PitchUp")
    
    -- Greife auf das Text-Label innerhalb der Checkbox zu und Ã¤ndere seine Farbe
    -- Das Label hat den Standardnamen "TextLabel", aber wir finden es sicher Ã¼ber seine Klasse.
    local label = pitchUpCheckbox:FindFirstChildOfClass("TextLabel")
    if label then
        label.TextColor3 = Color3.fromRGB(255, 80, 80) -- Ein leuchtendes Rot als Beispiel
    end
    
    -- NEUER SLIDER FÃœR DEN JITTER-WINKEL
    createSlider(antiAimGroup, UDim2.new(0, 10, 0, 135), "Jitter Angle", 0, 360, 180, "AntiAim_JitterAngle")


    -- #####################################################################
    -- # 5. STANDARD-TAB AKTIVIEREN
    -- #####################################################################
    
    if subTabNav:FindFirstChild("AimbotSubTab") then
        subTabNav.AimbotSubTab.MouseButton1Click:Fire()
    end
end