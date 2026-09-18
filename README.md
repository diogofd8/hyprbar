# HYPRBAR

A simple QuickShell (QML) status bar for Hyprland.

![preview](preview.png)

I built it for personal use on my side-project laptop, which has two batteries and a single screen. I didn't bother adding multi-monitor support, nor a configuration
option for single-battery laptops. Everything else — glyphs, fonts, colours, module spacing, and settings such as the vitals polling interval — is configurable.

## Modules

Most modules respond to the mouse: scroll to change volume and brightness, left-click to mute, right-click to switch the volume module between output and input, and click the vitals, weather and date segments to open a floating terminal popup.

## Dependencies

### System services

These back the individual modules. Most are already present on a typical Hyprland
desktop, but the matching module will sit empty if one is missing.

| Package | Used for |
| --- | --- |
| `pipewire`, `wireplumber` | volume and mute state |
| `libpulse` | `pactl`, used to detect the analog headphone jack (see notes) |
| `upower` | battery levels and charge state |
| `networkmanager` | Wi-Fi status |
| `bluez`, `bluez-utils` | Bluetooth status |
| `brightnessctl` | setting the backlight |

### Required

| Package | Used for |
| --- | --- |
| `quickshell` | the shell itself |
| `hyprland` | compositor, workspace state |
| `ttf-jetbrains-mono` | label font |
| `ttf-iosevkaterm-nerd` | icon font (Nerd Font glyphs) |

```sh
sudo pacman -S quickshell hyprland ttf-jetbrains-mono ttf-iosevkaterm-nerd
```

### Optional

Only needed by the click actions in `core/Actions.qml`. Drop the ones you don't want
and edit that file. Nothing else depends on them.

| Package | Used for |
| --- | --- |
| `rofi` | app launcher, power menu |
| `alacritty` | floating terminal popups |
| `clipse` (AUR) | clipboard manager |
| `swaync` | notification centre |
| `btop` | vitals popup |
| `curl` | weather popup (`wttr.in`) |
| `util-linux` | `cal`, calendar popup |
| `libnotify` | `notify-send` |
| `network-manager-applet` | `nm-connection-editor` |
| `blueman` | `blueman-manager` |
| `pacman-contrib` | `checkupdates`, for the update script |
| `spotify-bin`, Spotify binary |
| `gtk3` | `gtk-launch`, used by the Spotify module |

## Installation

### 1. Clone

QuickShell looks for configurations under `~/.config/quickshell/`, and the directory
name is what you pass to `qs -c`. Clone it as `hyprbar`:

```sh
git clone https://github.com/diogofd8/hyprbar.git ~/.config/quickshell/hyprbar
```

### 2. Try it

With Hyprland already running:

```sh
qs -c hyprbar
```

Errors and warnings are printed to the terminal, which is the quickest way to find a
missing font or dependency. The bar hot-reloads when you save a file, so you can leave
this running while you tweak things.

### 3. Autostart with Hyprland

**If you use the Lua configuration** (`~/.config/hypr/hyprland.lua`), add it to your
start handler:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c hyprbar")
    -- ... your other autostart commands
end)
```

### 4. Floating popups

The vitals, weather and calendar actions open Alacritty windows with specific titles.
They only float if you have rules for them:

```lua
hl.window_rule({
    name = "hyprbar-vitals",
    match = { class = "Alacritty", title = "^(waybar-vitals)$" },
    float = true, move = "150 35",
})
```

```ini
windowrule = float, class:Alacritty, title:^(waybar-vitals)$
windowrule = move 150 35, class:Alacritty, title:^(waybar-vitals)$
```

The titles used are `waybar-vitals`, `waybar-weather`, `waybar-calendar` and
`waybar-calendar-full` — historical names, kept from my Waybar setup this replaced.
I intend to replace these with proper drop-down QML modules so I didn't bother much here.

## Configuration

Everything user-facing lives in three files at the repository root:

- **`Settings.qml`** — glyphs, fonts and sizes, bar dimensions and padding, module
  spacing, polling intervals, scroll step sizes, and the threshold tables that map a
  value onto a state (`cpuStressThresholds`, `batteryLevelThresholds`,
  `volumeLevelThresholds`, `brightnessLevelThresholds`, …).
- **`Theme.qml`** — the light and dark colour palettes.
- **`WeatherConfig.qml`** — location and units. **Change this before first run**; it
  ships with my coordinates (Porto, PT).

Threshold tables and icon arrays are indexed together, so if you add a state you must
add the icon that goes with it.

### Before it works on your machine

- **Battery device names.** `Settings.qml` maps `internalBatteryPath: "BAT0"` and
  `externalBatteryPath: "BAT1"`. Check yours with `ls /sys/class/power_supply/`.
- **Power menu.** `scripts/powermenu.sh` is a symlink to my own Rofi power menu at
  `~/.config/rofi/powermenu/powermenu.sh`, which is **not** part of this repository —
  it will be a dangling symlink after cloning. Replace it with your own script, or
  point `Actions.powerMenu()` somewhere else.
- **Spotify.** `scripts/spotify_module` is a prebuilt Rust binary. If it doesn't run on
  your system, remove the Spotify module from `bar/RightSection.qml`.

## Notes and limitations

- **Single monitor.** The bar is created once, not per screen.
- **Two batteries.** The battery module shows one icon per pack with a coloured dot
  marking whichever is currently charging or discharging, and a single percentage for
  the active one. On a single-battery laptop the second icon will show as absent.
- **Workspace clicks need the Lua config.** `Actions.focusWorkspace()` dispatches
  `hl.dsp.focus({ workspace = "N" })`, which only works when Hyprland is running a Lua
  configuration. On a classic `hyprland.conf` setup, change it to
  `Hyprland.dispatch("workspace " + target)`.
- **The headphone jack is detected through `pactl`.** Plugging into the built-in
  3.5 mm jack switches the ALSA *route* without changing any PipeWire node property,
  so there is nothing for QuickShell to observe. `core/Audio.qml` therefore keeps a
  `pactl subscribe` process running and re-reads the active port when it fires
  (debounced, so a volume scroll doesn't spawn a process per tick). Bluetooth and USB
  headsets are detected from node properties and don't need this.
- **Arch Linux.** Package names and the update script assume `pacman`.

## In the future

I plan to add:

- Drop-down menus for vitals (with a `btop`-inspired look), battery (KDE-inspired),
  and volume (with MPRIS), among other nice functionality I might remember in the
  meantime
- Theme support, including a theme engine that pulls accent colours from the current
  wallpaper

## License

MIT — see [LICENSE](LICENSE).
