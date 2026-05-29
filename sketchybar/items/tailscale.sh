#!/bin/bash

tailscale=(
    icon.drawing=off
    label.drawing=off
    background.image="$HOME/.config/sketchybar/icon/tailscale.png"
    background.image.scale=0.03
    background.color=0x00000000
    # padding_right=5
    padding_left=5
    update_freq=10
    popup.align=right
    script="$PLUGIN_DIR/tailscale.sh"
    click_script="$PLUGIN_DIR/tailscale.sh"
)

tailscale_server=(
    icon=●
    icon.font="SF Pro:Regular:12.0"
    icon.color=$GREY
    label.color=$WHITE
    label.font="SF Pro:Regular:13.0"
    padding_left=10
    padding_right=10
)

sketchybar --add item tailscale right \
           --set tailscale "${tailscale[@]}" \
           --subscribe tailscale mouse.clicked mouse.entered mouse.exited mouse.exited.global system_woke \
           \
           --add item tailscale.server1 popup.tailscale \
           --set tailscale.server1 "${tailscale_server[@]}" label="headscale.kushvinth.com" \
           \
           --add item tailscale.server2 popup.tailscale \
           --set tailscale.server2 "${tailscale_server[@]}" label="headscale.pranavos.com"