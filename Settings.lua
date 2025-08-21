return function(parent)
    -- #####################################################################
    -- # 1. GLOBALE EINSTELLUNGEN & UI-HILFSFUNKTIONEN (VERBESSERT)
    -- #####################################################################

    -- Sicherstellen, dass die globale Tabelle und der spezifische Key existieren.
    -- Wir machen das jetzt noch robuster.
    if not _G.Settings then
        _G.Settings = {}
    end
    if not _G.Settings.MenuKey then
        _G.Settings.MenuKey = Enum.KeyCode.RightShift -- Setze Standardwert, falls nicht vorhanden
    end

    -- UI-Hilfsfunktion zum Erstellen eines einfachen Buttons (UnverÃ¤ndert)
    local function createButton(p, position, text, description, callback)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 35); container.BackgroundTransparency = 1; container.Parent = p
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 120, 1, -5); btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); btn.Font = Enum.Font.Gotham; btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.TextSize = 14; btn.Parent = container
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 3); corner.Parent = btn
        local descLabel = Instance.new("TextLabel"); descLabel.Size = UDim2.new(1, -130, 1, 0); descLabel.Position = UDim2.new(0, 130, 0, 0); descLabel.BackgroundTransparency = 1; descLabel.Font = Enum.Font.Gotham; descLabel.Text = description; descLabel.TextColor3 = Color3.fromRGB(120, 120, 120); descLabel.TextSize = 12; descLabel.TextXAlignment = Enum.TextXAlignment.Left; descLabel.Parent = container
        if callback then btn.MouseButton1Click:Connect(callback) end
        return container, btn
    end

    -- UI-Hilfsfunktion zum Erstellen eines Keybinders (JETZT ABGESICHERT)
    local function createKeybinder(p, position, text, configKey)
        local container = Instance.new("Frame"); container.Position = position; container.Size = UDim2.new(1, -20, 0, 35); container.BackgroundTransparency = 1; container.Parent = p
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.5, 0, 1, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.Text = text; label.TextColor3 = Color3.fromRGB(200, 200, 200); label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
        local keyButton = Instance.new("TextButton"); keyButton.Size = UDim2.new(0.5, 0, 1, 0); keyButton.Position = UDim2.new(0.5, 0, 0, 0); keyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50); keyButton.Font = Enum.Font.Gotham; keyButton.TextColor3 = Color3.fromRGB(200, 200, 200); keyButton.TextSize = 14; keyButton.Parent = container
        
        -- *** WICHTIGE Ã„NDERUNG HIER ***
        -- Wir prÃ¼fen, ob der Key in der Settings-Tabelle existiert und ein gÃ¼ltiges KeyCode-Objekt ist.
        if _G.Settings[configKey] and typeof(_G.Settings[configKey]) == "EnumItem" then
            keyButton.Text = _G.Settings[configKey].Name
        else
            -- Fallback, falls der Wert ungÃ¼ltig oder nicht vorhanden ist.
            keyButton.Text = "[None]"
            _G.Settings[configKey] = Enum.KeyCode.RightShift -- Setze einen sicheren Standardwert
        end

        keyButton.MouseButton1Click:Connect(function()
            keyButton.Text = "[...]"
            local connection
            connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton2) then
                    _G.Settings[configKey] = input.KeyCode
                    keyButton.Text = input.KeyCode.Name -- Sicherer, direkt vom Input-Objekt zu nehmen
                    connection:Disconnect()
                end
            end)
        end)
        return container, keyButton
    end

    -- #####################################################################
    -- # 2. HAUPTSTRUKTUR (UnverÃ¤ndert)
    -- #####################################################################
    local subTabNav = Instance.new("Frame"); subTabNav.Name = "SubTabNav"; subTabNav.Size = UDim2.new(0, 150, 1, 0); subTabNav.BackgroundColor3 = Color3.fromRGB(40, 40, 40); subTabNav.BorderSizePixel = 0; subTabNav.Parent = parent
    local contentArea = Instance.new("Frame"); contentArea.Name = "ContentArea"; contentArea.Size = UDim2.new(1, -150, 1, 0); contentArea.Position = UDim2.new(0, 150, 0, 0); contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0; contentArea.ClipsDescendants = true; contentArea.Parent = parent
    local subTabs = {"GUI", "Configs"}; local subTabFrames = {}; local activeSubTabButton = nil
    for i, tabName in ipairs(subTabs) do
        local btn = Instance.new("TextButton"); btn.Name = tabName .. "SubTab"; btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, (i - 1) * 40); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.BorderSizePixel = 0; btn.Font = Enum.Font.Gotham; btn.Text = "  " .. tabName; btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 14; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = subTabNav
        local indicator = Instance.new("Frame"); indicator.Name = "Indicator"; indicator.Size = UDim2.new(0, 3, 1, 0); indicator.BackgroundColor3 = Color3.fromRGB(200, 40, 40); indicator.BorderSizePixel = 0; indicator.Visible = false; indicator.Parent = btn
        local content = Instance.new("Frame"); content.Name = tabName .. "Content"; content.Size = UDim2.new(1, 0, 1, 0); content.BackgroundTransparency = 1; content.Visible = false; content.Parent = contentArea
        subTabFrames[tabName] = content
        btn.MouseButton1Click:Connect(function() if activeSubTabButton then activeSubTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40); activeSubTabButton.TextColor3 = Color3.fromRGB(180, 180, 180); activeSubTabButton.Indicator.Visible = false end; for _, f in pairs(subTabFrames) do f.Visible = false end; content.Visible = true; btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55); btn.TextColor3 = Color3.fromRGB(200, 40, 40); indicator.Visible = true; activeSubTabButton = btn end)
    end

    -- #####################################################################
    -- # 3. INHALTE FÃœR DIE TABS (UnverÃ¤ndert)
    -- #####################################################################
    local guiContent = subTabFrames["GUI"]
    local guiGroup = Instance.new("Frame"); guiGroup.Position = UDim2.new(0, 10, 0, 10); guiGroup.Size = UDim2.new(0.5, -15, 0, 120); guiGroup.BackgroundColor3 = Color3.fromRGB(35, 35, 35); guiGroup.Parent = guiContent
    local guiTitle = Instance.new("TextLabel"); guiTitle.Size=UDim2.new(1,0,0,25); guiTitle.BackgroundTransparency=1; guiTitle.Font=Enum.Font.GothamBold; guiTitle.Text="  GUI Settings"; guiTitle.TextColor3=Color3.fromRGB(220,220,220); guiTitle.TextSize=14; guiTitle.TextXAlignment=Enum.TextXAlignment.Left; guiTitle.Parent=guiGroup
    
    -- Diese Aufrufe sollten jetzt sicher sein
    createKeybinder(guiGroup, UDim2.new(0, 10, 0, 30), "Open/Close Key", "MenuKey")
    createButton(guiGroup, UDim2.new(0, 10, 0, 65), "Unload Cheat", "Removes the GUI completely.", function()
        local mainGui = parent:FindFirstAncestorOfClass("ScreenGui")
        if mainGui then
            mainGui:Destroy()
        end
    end)
    
    local configsContent = subTabFrames["Configs"]

    -- #####################################################################
    -- # 4. LOGIK FÃœR DAS Ã–FFNEN/SCHLIESSEN (UnverÃ¤ndert, sollte jetzt funktionieren)
    -- #####################################################################
    local mainGui = parent:FindFirstAncestorOfClass("ScreenGui")
    if mainGui then
        mainGui.Enabled = true
        game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if _G.Settings.MenuKey and input.KeyCode == _G.Settings.MenuKey then
                mainGui.Enabled = not mainGui.Enabled
            end
        end)
    else
        warn("Konnte keine Ã¼bergeordnete ScreenGui fÃ¼r die Open/Close-Funktion finden!")
    end

    -- #####################################################################
    -- # 5. STANDARD-TAB AKTIVIEREN (UnverÃ¤ndert)
    -- #####################################################################
    if subTabNav:FindFirstChild("GUISubTab") then
        subTabNav.GUISubTab.MouseButton1Click:Fire()
    end
end