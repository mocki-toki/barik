#!/bin/bash

#update() {
#  source "$CONFIG_DIR/icons.sh"
#  INFO="$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F ' SSID: '  '/ SSID: / {print $2}')"
#  LABEL="$INFO ($(ipconfig getifaddr en0))"
#  ICON="$([ -n "$INFO" ] && echo "$WIFI_CONNECTED" || echo "$WIFI_DISCONNECTED")"
#
#  sketchybar --set $NAME icon="$ICON" label="$LABEL"
#}
#
#click() {
#  CURRENT_WIDTH="$(sketchybar --query $NAME | jq -r .label.width)"
#
#  WIDTH=0
#  if [ "$CURRENT_WIDTH" -eq "0" ]; then
#    WIDTH=dynamic
#  fi
#
#  sketchybar --animate sin 20 --set $NAME label.width="$WIDTH"
#}
#
#case "$SENDER" in
#  "wifi_change") update
#  ;;
#  "mouse.clicked") click
#  ;;
#esac

update() {
    CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
    source "$CONFIG_DIR/icons.sh"

    # Get SSID reliably (trim spaces)
    #    INFO="$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I |
    #        grep ' SSID:' | sed 's/.*SSID: //')"
    INFO=$(networksetup -listallhardwareports |
        awk '/Wi-Fi|AirPort/{getline; print $2}')
    # Detect active interface IP (en0 or en1 fallback)
    # IP_ADDR=$(ipconfig getifaddr en0)
    IP_ADDR=$(ipconfig getifaddr $(route get default | awk '/interface:/{print $2}'))
    [ -z "$IP_ADDR" ] && IP_ADDR=$(ipconfig getifaddr en1)

    # Set icon based on WiFi connected or not
    if [ -n "$INFO" ]; then
        ICON="$WIFI_CONNECTED"
        LABEL="$INFO ($IP_ADDR)"
    else
        ICON="$WIFI_DISCONNECTED"
        LABEL="Not Connected"
    fi

    sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
}

click() {
    CURRENT_WIDTH="$(sketchybar --query "$NAME" | jq -r .label.width)"

    if [ "$CURRENT_WIDTH" -eq 0 ]; then
        WIDTH="dynamic"
    else
        WIDTH=0
    fi

    sketchybar --animate sin 20 --set "$NAME" label.width="$WIDTH"
}

case "$SENDER" in
"wifi_change") update ;;
"mouse.clicked") click ;;
esac

