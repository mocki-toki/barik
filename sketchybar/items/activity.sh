#!/bin/bash
source "$HOME/.config/sketchybar/icons.sh"
POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

activity=(
  icon.drawing=off
  label.drawing=off
  padding.left=1

  background.image="$HOME/.config/sketchybar/icon/Waka.png"
  background.image.scale=0.18
  background.color=0x00000000
  
  update_freq=10
  popup.align=right
  script="$PLUGIN_DIR/activity.sh"
  click_script="$POPUP_CLICK_SCRIPT"
)

activity_template=(
  drawing=off
  background.corner_radius=12
  padding_right=0
  icon.background.height=2
  icon.background.y_offset=-12
)

sketchybar --add item activity right \
  --set activity "${activity[@]}" \
  --subscribe activity mouse.entered \
                        mouse.exited \
                        mouse.exited.global \
  \
  --add item activity.template popup.activity \
  --set activity.template "${activity_template[@]}" \
  \
  --add item activity.time popup.activity \
  --set activity.time label="" \
                      label.font="SF Pro:Regular:13.0" \
                      label.color=$WHITE \
                      padding_left=10 \
                      padding_right=10
