#!/bin/bash
# Smart close: minimize Spotify to tray, kill other windows
class=$(hyprctl activewindow | grep "class:" | cut -d' ' -f2)
# Hyprland >= 0.55 takes Lua dispatchers; older versions only the legacy ones.
if [[ "${class,,}" == "spotify" ]]; then
    hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:spotify", follow = false })' | grep -qx ok \
        || hyprctl dispatch movetoworkspacesilent special:spotify
else
    hyprctl dispatch 'hl.dsp.window.close()' | grep -qx ok || hyprctl dispatch killactive
fi
