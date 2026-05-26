-- Converted from hyprland.conf for Hyprland's Lua config API.
-- See https://wiki.hypr.land/Configuring/Start/

local home = os.getenv("HOME") or "/home/tonio"

local function load_theme_colors()
    local ok, colors = pcall(dofile, home .. "/.cache/matugen/hyprland.lua")
    if ok and type(colors) == "table" then
        return colors
    end

    return {
        primary = "#ffb4a6",
        outline_variant = "#534340",
    }
end

local colors = load_theme_colors()

local function hypr_color(hex)
    return "rgb(" .. hex:gsub("#", "") .. ")"
end

----------------
-- Monitors
----------------

require("monitors")

----------------
-- Programs
----------------

local terminal = "ghostty"
local fileManager = "nautilus"
local menu = "vicinae toggle"
local mainMod = "SUPER"

----------------
-- Autostart
----------------

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("swaync")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("sh -c 'vicinae server --replace >/dev/null 2>&1 &'")
end)

----------------
-- Environment
----------------

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "theme_my_theme")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")

----------------
-- Look And Feel
----------------

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = { top = 0, right = 10, bottom = 10, left = 10 },
        border_size = 2,
        col = {
            active_border = hypr_color(colors.primary),
            inactive_border = hypr_color(colors.outline_variant),
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 4,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = false,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("niercurve", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "niercurve", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "niercurve", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "niercurve", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "niercurve" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "niercurve" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "niercurve" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "niercurve", style = "slidevert" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "niercurve", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "niercurve", style = "slidevert" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
})

----------------
-- Input
----------------

hl.config({
    input = {
        kb_layout = "fr",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
    cursor = {
        no_hardware_cursors = 1,
    },
    render = {
        expand_undersized_textures = true,
        direct_scanout = true,
    },
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

----------------
-- Keybindings
----------------

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.config/hypr/wallpaper.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("vesktop"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd('XDG_CURRENT_DESKTOP="gnome" gnome-control-center'))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("reboot"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("shutdown now"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("pkill quickshell; quickshell"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("steam"))

hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd('grim -g "$(slurp -w 0)" - | wl-copy'))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp -w 0)" - | wl-copy'))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
    hl.bind("left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

local workspace_keys = {
    { key = "ampersand", workspace = "1" },
    { key = "eacute", workspace = "2" },
    { key = "quotedbl", workspace = "3" },
    { key = "apostrophe", workspace = "4" },
    { key = "parenleft", workspace = "5" },
    { key = "minus", workspace = "6" },
    { key = "egrave", workspace = "7" },
    { key = "underscore", workspace = "8" },
    { key = "ccedilla", workspace = "9" },
    { key = "agrave", workspace = "10" },
}

for _, item in ipairs(workspace_keys) do
    hl.bind(mainMod .. " + " .. item.key, hl.dsp.focus({ workspace = item.workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. item.key, hl.dsp.window.move({ workspace = item.workspace, follow = false }))
end

hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.float({ action = "toggle" }), { click = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

----------------
-- Window Rules
----------------

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "nofocus",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_initial_focus = true,
})
