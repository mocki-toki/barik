#!/bin/bash
# inspo: https://github.com/kejadlen/dotfiles/blob/7eac34262edfab1b6774c158de2f83c0b26a363c/.config/sketchybar/plugins/tailscale.sh
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

LOCK_ICON=􀎡
UNLOCK_ICON=􀎥

# Toggle tailscale on click
if [ "$SENDER" = "mouse.clicked" ]; then
	if ! command -v tailscale >/dev/null 2>&1; then
		sketchybar --set "$NAME" icon.drawing=on icon="$UNLOCK_ICON" icon.color=$RED
		exit 0
	fi

	if tailscale status --self &>/dev/null; then
		# Currently connected → disconnect
		sketchybar --set "$NAME" background.image.scale=0 icon.drawing=on icon="$UNLOCK_ICON" icon.color=$RED
		sketchybar --animate sin 15 --set "$NAME" icon.color=$GREY
		tailscale down
		sleep 1
		sketchybar --set "$NAME" icon.drawing=off background.image.scale=0.03
	else
		# Currently disconnected → connect
		tailscale up
		sleep 0.5
		sketchybar --set "$NAME" background.image.scale=0 icon.drawing=on icon="$LOCK_ICON" icon.color=$GREY
		sketchybar --animate sin 15 --set "$NAME" icon.color=$GREEN
		sleep 1
		sketchybar --set "$NAME" icon.drawing=off background.image.scale=0.03
	fi
fi

case "$SENDER" in
"system_woke" | "forced")
	update_icon
	;;
esac

update_icon