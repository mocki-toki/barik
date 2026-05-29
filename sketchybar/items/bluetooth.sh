#!/bin/bash

# Load icons
source "$HOME/.config/sketchybar/icons.sh"

bluetooth=(
  icon="$BLUETOOTH_OFF"
  label.drawing=off
  padding_right=0
  script="$PLUGIN_DIR/bluetooth.sh"
  update_freq=5
  icon.font="$FONT:Bold:19.0"
)

sketchybar --add item bluetooth right \
           --set bluetooth "${bluetooth[@]}" \
           --subscribe bluetooth bluetooth_change mouse.clicked
