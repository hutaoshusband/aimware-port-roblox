# Aimware v5.4.1 for Roblox

![Aimware GUI](./Pictures/gui.png)

A universal cheat menu for Roblox, inspired by the legendary CS:GO cheat, **Aimware.net**. This is a fan project dedicated to recreating the classic Aimware experience within the Roblox engine. This script is designed to be universal and is not made for one specific game.

---

## ✨ Features

Below is a comprehensive list of all current features, categorized.

### Legitbot
Designed for subtle cheating that appears legitimate to other players and spectators.

*   **Aimbot**: Automatically assists your aim towards enemy players.
*   **AimKey**: Activates the aimbot only when a specific key (e.g., `MouseButton2`) is held down.
*   **Smoothing**: Adjusts the smoothness of the aimbot's targeting for a human-like feel.
*   **AutoFire**: Fires automatically when the aimbot has a target.
*   **Fire On Press**: Fires when the aimbot key is pressed.
*   **Wall Check**: Ensures the aimbot only locks onto visible players.
*   **Semirage**: A more aggressive form of legitbot.
    *   **Silent Aim**: Aims at the target without moving your camera view.
    *   **Aim FOV**: A separate field of view for the semirage aimbot.
*   **Triggerbot**: Automatically fires when your crosshair is over an enemy.

### Ragebot
For aggressive gameplay where stealth is not a priority. Annihilate the entire server.

*   **Aimbot**:
    *   **Silent Aim**: Aim is not visible on your screen.
    *   **FOV Slider**: Adjusts the field of view (FOV) circle.
    *   **Team Check**: Prevents targeting teammates.
    *   **Visible Check**: Locks only onto visible enemies.
    *   **Auto Fire**: Automatically shoots at the target with adjustable delay.
    *   **Auto Stop**: Stops your movement when a target is visible for better accuracy.
*   **Anti-Aim**:
    *   **Spinbot**: Rapidly spins your character to make headshots difficult.
    *   **Jitter**: Randomly shakes your character's rotation.
    *   **Pitch Up**: Forces your character to look up.
*   **Movement**:
    *   **Bunnyhop**: Automatically jumps when hitting the ground.
    *   **AutoStrafer (Subtick)**: Flicks your head and boosts speed in the air.
    *   **Strafer Speed**: Adjustable speed for the autostrafer.

### Visuals
Enhance your in-game awareness by seeing things others can't.

*   **Player ESP**:
    *   **Box ESP**: Draws 2D boxes around players.
    *   **Name ESP**: Displays player names with a **Wave Text Animation**.
    *   **Distance ESP**: Shows distance to players with **Wave Text Animation**.
    *   **Skeleton ESP**: Draws the player's skeleton structure.
    *   **Local Trails**: Creates a trail behind your character.
    *   **Colors**: Fully customizable colors for all ESP elements.
*   **Chams**:
    *   **Global Chams**: See players through walls with customizable materials (ForceField, Neon, etc.).
    *   **Local Chams**: Customize your own character's appearance with materials, transparency, and **Rainbow Overlay**.
*   **Viewmodel**:
    *   **Offsets**: Adjust X, Y, Z positions of your weapon viewmodel.
    *   **FOV**: Change the field of view of the viewmodel.
*   **UI Elements**:
    *   **Watermark**: Displays client info (User, Ping).
    *   **Debug Info**: Shows detailed stats (FPS, Ping, Memory, Player Stats, World Info).

### World
Modify the game world for a tactical or performance advantage.

*   **FPS Booster**: Drastically lowers world graphics and removes textures to provide a massive FPS boost.
*   **World Color**: Change the ambient color of the game world.
*   **No Flash/Smoke**: Removes flashbang and smoke effects.

### Misc
A collection of miscellaneous cheats and trolling features.

> ** Warning:** These features are considered high-risk on servers with a server-sided anticheat. Use them with caution.

#### Movement
*   **Fly**: Fly around the map with adjustable speed.
*   **Walk Speed**: Modify your character's walking speed.
*   **Jump Power**: Modify your character's jump height.
*   **Infinite Jump**: Jump unlimited times in the air.
*   **High Jump**: Perform a single super-high jump.

#### Combat
*   **Spinbot**: Basic spinbot implementation.
*   **Pitch Down**: Forces camera to look down (unsafe).
*   **Fling**: Violently pushes other players away upon collision.
*   **Auto-Clicker**: Automatically clicks your mouse.

#### Troll
*   **Fall**: Makes other players trip (if supported).
*   **Stick to Player**: Follows a target player closely.
*   **Teleport to Player**: Teleports you to a target.
*   **Lag Player**: Attempts to lag a target player.
*   **Orbit Player**: Makes a target player orbit around you.
*   **Invisible**: Makes your character invisible.
*   **Fake Crash**: Shows a fake crash screen.
*   **Confuse Controls**: Inverts movement controls.

#### Utility
*   **Infinity Yield**: Loads the popular Infinity Yield admin script.
*   **Fullbright**: Illuminates the map.
*   **Server Hopper**: Joins a different server.
*   **Script Executor**: Execute custom Lua scripts directly from the menu.

---

## Installation

This script requires a functioning **Roblox Executor** to run.

1.  Open your preferred Roblox Executor.
2.  Paste the script:
    ```lua
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hutaoshusband/aimware-port-roblox/main/Main.lua"))()
    ```

---

## Configuration

*   **Toggle GUI**: Custom keybind to open/close the menu (Default: `RightShift`).
*   **Settings Tab**: Save and load your configurations.
*   **Unload Cheat**: Safely removes the UI and disables all features.

---

## 📜 Disclaimer

*   This script is provided for **educational purposes only**.
*   The use of exploits or cheats is a direct violation of the Roblox Terms of Service.
*   The creator of this project is **not responsible** for any consequences resulting from its use, including but not limited to account suspensions or bans.
*   **Use at your own risk.**
