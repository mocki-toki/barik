#!/bin/bash

update() {
  source "$HOME/.config/sketchybar/colors.sh"

  if [ "$SELECTED" = "true" ]; then
    sketchybar --animate tanh 20 \
               --set $NAME icon.highlight=true \
                           label.highlight=true \
                           background.color=$BACKGROUND_2
  else
    sketchybar --animate tanh 20 \
               --set $NAME icon.highlight=false \
                           label.highlight=false \
                           background.color=$TRANSPARENT
  fi
}

mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    yabai -m space --destroy $SID
    sketchybar --trigger space_change --trigger windows_on_spaces
  else
    yabai -m space --focus $SID 2>/dev/null
  fi
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac
