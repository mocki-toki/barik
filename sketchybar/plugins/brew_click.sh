#!/bin/bash

click() {
    CURRENT_WIDTH="$(sketchybar --query brew | jq -r .label.width)"

    if [ "$CURRENT_WIDTH" -eq 0 ]; then
        # Show label, hide image
        sketchybar --animate sin 20 --set brew label.width=dynamic background.image.scale=0
    else
        # Hide label, show image
        sketchybar --animate sin 20 --set brew label.width=0 background.image.scale=0.037
    fi
}

click
