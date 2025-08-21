-- main.lua - KORRIGIERTE VERSION (Entfernt die doppelte Keybind-Logik)

-- #####################################################################
-- # GLOBALE STEUERUNG & AUFRÃ„UMFUNKTION
-- #####################################################################
local UserInputService = game:GetService("UserInputService")

-- Eine Tabelle, in der wir alle aktiven Skript-Verbindungen speichern
_G.ActiveConnections = {}

-- Die globale Unload-Funktion
function _G.UnloadAllFeatures()
    -- Trenne alle gespeicherten Verbindungen (von Fly, Spinbot, ESP etc.)
    for _, connection in pairs(_G.ActiveConnections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    _G.ActiveConnections = {} -- Leere die Tabelle

    -- ZerstÃ¶re die Haupt-GUI
    local mainGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ExecutorUI")
    if mainGui then
        mainGui:Destroy()
    end
    
    -- Optional: Setze Spieler-Eigenschaften zurÃ¼ck
    local player = game:GetService("Players").LocalPlayer
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid.WalkSpeed = 16
        player.Character.Humanoid.JumpPower = 50
    end
end

-- ENTFERNT: Die globale Keybind-Logik wird jetzt komplett von Settings.lua Ã¼bernommen

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExecutorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Hauptfenster (startet unsichtbar)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Visible = false -- WICHTIG: Startet unsichtbar
MainFrame.Size = UDim2.new(0, 800, 0, 500)
MainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Lade-Anzeige
local LoadingLabel = Instance.new("TextLabel")
LoadingLabel.Name = "LoadingLabel"
LoadingLabel.Size = UDim2.new(0.5, 0, 0, 35)
LoadingLabel.Position = UDim2.new(1, -15, 1, -35)
LoadingLabel.AnchorPoint = Vector2.new(1, 1)
LoadingLabel.BackgroundTransparency = 1
LoadingLabel.Font = Enum.Font.Gotham
LoadingLabel.Text = "WallBangBros.com initializing..."
LoadingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingLabel.TextSize = 14
LoadingLabel.TextXAlignment = Enum.TextXAlignment.Right
LoadingLabel.Parent = ScreenGui

-- #####################################################################
-- # SAUBERE UI-ERSTELLUNG (DER FIX)
-- #####################################################################

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6) -- Gleicher Radius wie beim MainFrame
headerCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "AIMWARE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(0, 500, 1, 0)
TabContainer.Position = UDim2.new(0.5, -250, 0, 0)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Header

local Tabs = {"Legitbot", "Ragebot", "Visuals", "Misc", "Settings"}
local TabFrames = {}
local activeTabButton = nil
local INACTIVE_TAB_TRANSPARENCY = 0.5
local ACTIVE_TAB_TRANSPARENCY = 0

for i, tabName in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Name = tabName .. "Tab"
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = UDim2.new(0, (i - 1) * 100, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.Gotham
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextTransparency = INACTIVE_TAB_TRANSPARENCY
    btn.TextSize = 16
    btn.Parent = TabContainer

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = tabName .. "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -80)
    contentFrame.Position = UDim2.new(0, 0, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false
    contentFrame.Parent = MainFrame
    TabFrames[tabName] = contentFrame

    btn.MouseButton1Click:Connect(function()
        if activeTabButton then
            activeTabButton.TextTransparency = INACTIVE_TAB_TRANSPARENCY
        end
        for _, frame in pairs(TabFrames) do
            frame.Visible = false
        end
        contentFrame.Visible = true
        btn.TextTransparency = ACTIVE_TAB_TRANSPARENCY
        activeTabButton = btn
    end)
end

local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 35)
Footer.Position = UDim2.new(0, 0, 1, -35)
Footer.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
Footer.BorderSizePixel = 0
Footer.Parent = MainFrame

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Name = "VersionLabel"
VersionLabel.Size = UDim2.new(0.5, -15, 1, 0)
VersionLabel.Position = UDim2.new(0, 15, 0, 0)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.Text = "V5.0.4 for Roblox. Discord.gg/dUCNKkS2Ve"
VersionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
VersionLabel.TextSize = 14
VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
VersionLabel.Parent = Footer

local WebsiteLabel = Instance.new("TextLabel")
WebsiteLabel.Name = "WebsiteLabel"
WebsiteLabel.Size = UDim2.new(0.5, -15, 1, 0)
WebsiteLabel.Position = UDim2.new(1, -15, 0, 0)
WebsiteLabel.AnchorPoint = Vector2.new(1, 0)
WebsiteLabel.BackgroundTransparency = 1
WebsiteLabel.Font = Enum.Font.Gotham
WebsiteLabel.Text = "WallBangBros.com"
WebsiteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
WebsiteLabel.TextSize = 14
WebsiteLabel.TextXAlignment = Enum.TextXAlignment.Right
WebsiteLabel.Parent = Footer

-- #####################################################################
-- # ASYNCHRONES LADESYSTEM
-- #####################################################################

local function LoadTab(tabName, fileName)
    local success, raw = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/hutaoshusband/aimware-port-roblox/refs/heads/main/" .. fileName, true )
    end)
    if not success or not raw then
        warn("HTTP-Fehler bei " .. fileName .. ": " .. tostring(raw))
        return
    end
    local loadSuccess, module = pcall(loadstring(raw))
    if loadSuccess and type(module) == "function" then
        local runSuccess, err = pcall(module, TabFrames[tabName])
        if not runSuccess then
            warn("Laufzeitfehler in " .. fileName .. ": " .. tostring(err))
        end
    else
        warn("Kompilierungsfehler in " .. fileName .. ": " .. tostring(module))
    end
end

spawn(function() LoadTab("Legitbot", "Legitbot.lua") end)
spawn(function() LoadTab("Ragebot", "Ragebot.lua") end)
spawn(function() LoadTab("Visuals", "Visuals.lua") end)
spawn(function() LoadTab("Misc", "Misc.lua") end)
spawn(function() LoadTab("Settings", "Settings.lua") end)

wait(2)

LoadingLabel:Destroy()
MainFrame.Visible = true

if TabContainer:FindFirstChild("LegitbotTab") then
    TabContainer.LegitbotTab.MouseButton1Click:Fire()
end

print("UI V6 (Final) wurde initialisiert.")
