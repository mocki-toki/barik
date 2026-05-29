#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

update() {
  # Check if blueutil is installed
  if ! command -v blueutil &> /dev/null; then
    sketchybar --set $NAME icon="$BLUETOOTH_OFF" label="No blueutil"
    return
  fi

  STATE=$(blueutil -p)
  
  if [ "$STATE" = "0" ]; then
    # Bluetooth is OFF
    sketchybar --set $NAME icon="$BLUETOOTH_OFF" icon.color="$GREY" label.drawing=off
  else
    # Bluetooth is ON
    # Check for connected devices
    # blueutil --connected returns a JSON list or list of devices. 
    # We can count lines or check output.
    CONNECTED_DEVICES=$(blueutil --connected | wc -l | tr -d ' ')
    
    if [ "$CONNECTED_DEVICES" -gt "0" ]; then
      # Connected
      sketchybar --set $NAME icon="$BLUETOOTH_CONNECTED" icon.color="$BLUE" label="$CONNECTED_DEVICES" label.drawing=on
    else
      # On but not connected
      sketchybar --set $NAME icon="$BLUETOOTH_ON" icon.color="$WHITE" label.drawing=off
    fi
  fi
}

click() {
  # Toggle bluetooth on click? Or open prefs?
  # Let's toggle for now as it's a common use case, or we could just open settings.
  # "blueutil -p toggle" toggles power.
  
  CURRENT_STATE=$(blueutil -p)
  if [ "$CURRENT_STATE" = "0" ]; then
    blueutil -p 1
  else
    blueutil -p 0
  fi
  
  # Trigger immediate update
  update
}

case "$SENDER" in
  "mouse.clicked") click ;;
  *) update ;;
esac
