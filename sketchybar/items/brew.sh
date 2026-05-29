#!/bin/bash

# Trigger the brew_udpate event when brew update or upgrade is run from cmdline
# e.g. via function in .zshrc

brew=(
    icon.drawing=off
    label=?
    label.width=0
    label.padding_right=6
    background.image="$HOME/.config/sketchybar/icon/brew.png"
    background.image.scale=0.037
    background.color=0x00000000
    # padding_right=10
    script="$PLUGIN_DIR/brew.sh"
    click_script="$PLUGIN_DIR/brew_click.sh"
    update_freq=300
)

sketchybar --add event brew_update \
    --add item brew right \
    --set brew "${brew[@]}" \
    --subscribe brew brew_update
