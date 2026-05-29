#!/bin/bash

next ()
{
  osascript -e 'tell application "Music" to play next track' 2>/dev/null
  sleep 0.5
}

back () 
{
  osascript -e 'tell application "Music" to play previous track' 2>/dev/null
  sleep 0.5
}

play () 
{
  osascript -e 'tell application "Music" to playpause'
}

repeat () 
{
  REPEAT=$(osascript -e 'tell application "Music" to get song repeat')
  if [ "$REPEAT" = "off" ]; then
    sketchybar -m --set music.repeat icon.highlight=on
    osascript -e 'tell application "Music" to set song repeat to all'
  else 
    sketchybar -m --set music.repeat icon.highlight=off
    osascript -e 'tell application "Music" to set song repeat to off'
  fi
}

shuffle () 
{
  SHUFFLE=$(osascript -e 'tell application "Music" to get shuffle enabled')
  if [ "$SHUFFLE" = "false" ]; then
    sketchybar -m --set music.shuffle icon.highlight=on
    osascript -e 'tell application "Music" to set shuffle enabled to true'
  else 
    sketchybar -m --set music.shuffle icon.highlight=off
    osascript -e 'tell application "Music" to set shuffle enabled to false'
  fi
}

update ()
{
  PLAYING=1
  
  # Batch all AppleScript calls into one to reduce overhead
  MUSIC_INFO=$(osascript 2>/dev/null << EOF
tell application "Music"
  try
    if player state is playing then
      set trackName to name of current track
      set artistName to artist of current track
      set albumName to album of current track
      set shuffleState to shuffle enabled
      set repeatState to song repeat
      return "playing|" & trackName & "|" & artistName & "|" & albumName & "|" & shuffleState & "|" & repeatState
    else
      return "stopped"
    end if
  on error
    return "error"
  end try
end tell
EOF
)
  
  if [[ "$MUSIC_INFO" == "playing|"* ]]; then
    PLAYING=0
    IFS='|' read -r state TRACK ARTIST ALBUM SHUFFLE REPEAT <<< "$MUSIC_INFO"
    
    # Truncate long strings
    TRACK=$(echo "$TRACK" | sed 's/\(.\{20\}\).*/\1.../')
    ARTIST=$(echo "$ARTIST" | sed 's/\(.\{20\}\).*/\1.../')
    ALBUM=$(echo "$ALBUM" | sed 's/\(.\{25\}\).*/\1.../')
    
    # Get artwork in background to avoid blocking
    (osascript 2>/dev/null << 'EOF'
tell application "Music"
  try
    set artworkData to raw data of artwork 1 of current track
    set artworkFile to open for access POSIX file "/tmp/music_cover.jpg" with write permission
    set eof artworkFile to 0
    write artworkData to artworkFile
    close access artworkFile
  end try
end tell
EOF
    ) &
  fi

  args=()
  if [ $PLAYING -eq 0 ]; then
    if [ "$ARTIST" == "" ]; then
      args+=(--set music.title label="$TRACK"
             --set music.album label="Podcast"
             --set music.artist label="$ALBUM"  )
    else
      args+=(--set music.title label="$TRACK"
             --set music.album label="$ALBUM"
             --set music.artist label="$ARTIST")
    fi
    
    # Check repeat state and set highlight accordingly
    if [ "$REPEAT" = "off" ]; then
      REPEAT_HIGHLIGHT="off"
    else
      REPEAT_HIGHLIGHT="on"
    fi
    
    args+=(--set music.play icon=􀊆
           --set music.shuffle icon.highlight=$SHUFFLE
           --set music.repeat icon.highlight=$REPEAT_HIGHLIGHT
           --set music.cover background.image="/tmp/music_cover.jpg"
                               background.color=0x00000000
           --set music.anchor drawing=on                      )
  else
    args+=(--set music.anchor drawing=off popup.drawing=off
           --set music.play icon=􀊄                         )
  fi
  sketchybar -m "${args[@]}"
}

scrubbing() {
  DURATION=$(osascript -e 'tell application "Music" to get duration of current track')

  TARGET=$((DURATION*PERCENTAGE/100))
  osascript -e "tell application \"Music\" to set player position to $TARGET"
  sketchybar --set music.state slider.percentage=$PERCENTAGE
}

scroll() {
  DURATION=$(osascript -e 'tell application "Music" to get duration of current track')

  FLOAT="$(osascript -e 'tell application "Music" to get player position')"
  TIME=${FLOAT%.*}
  
  sketchybar --animate linear 10 \
             --set music.state slider.percentage="$((TIME*100/DURATION))" \
                                 icon="$(date -r $TIME +'%M:%S')" \
                                 label="$(date -r $DURATION +'%M:%S')"
}

mouse_clicked () {
  case "$NAME" in
    "music.next") next
    ;;
    "music.back") back
    ;;
    "music.play") play
    ;;
    "music.shuffle") shuffle
    ;;
    "music.repeat") repeat
    ;;
    "music.state") scrubbing
    ;;
    *) exit
    ;;
  esac
}

popup () {
  sketchybar --set music.anchor popup.drawing=$1
}

routine() {
  case "$NAME" in
    "music.state") scroll
    ;;
    *) update
    ;;
  esac
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "mouse.entered") popup on
  ;;
  "mouse.exited"|"mouse.exited.global") popup off
  ;;
  "routine") routine
  ;;
  "forced") exit 0
  ;;
  *) update
  ;;
esac
