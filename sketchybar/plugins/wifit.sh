#!/bin/bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/icons.sh"

wifi=(
    padding_left=5
    label.width=5
    icon="$WIFI_DISCONNECTED"
    script="$PLUGIN_DIR/wifi.sh"
)

sketchybar --add item wifi right \
    --set wifi "${wifi[@]}" \
    --subscribe wifi wifi_change mouse.clicked

