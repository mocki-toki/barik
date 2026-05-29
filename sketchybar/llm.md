
# backup/items/apple_music.sh

#!/bin/bash

POPUP_SCRIPT="sketchybar -m --set music.anchor popup.drawing=toggle"

music_anchor=(
  script="$PLUGIN_DIR/apple_music.sh"
  click_script="$POPUP_SCRIPT"
  popup.horizontal=on
  popup.align=center
  popup.height=150
  icon=ô€‘ª
  icon.font="$FONT:Regular:25.0"
  label.drawing=off
  drawing=off
  y_offset=2
  update_freq=5
  updates=on
)

music_cover=(
  script="$PLUGIN_DIR/apple_music.sh"
  click_script="open -a 'Music'; $POPUP_SCRIPT"
  label.drawing=off
  icon.drawing=off
  padding_left=12
  padding_right=10
  background.image.scale=0.2
  background.image.drawing=on
  background.drawing=on
)

music_title=(
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  label.font="$FONT:Heavy:15.0"
  y_offset=55
)

music_artist=(
  icon.drawing=off
  y_offset=30
  padding_left=0
  padding_right=0
  width=0
)

music_album=(
  icon.drawing=off
  padding_left=0
  padding_right=0
  y_offset=15
  width=0
)

music_state=(
  icon.drawing=on
  icon.font="$FONT:Light Italic:10.0"
  icon.width=35
  icon="00:00"
  label.drawing=on
  label.font="$FONT:Light Italic:10.0"
  label.width=35
  label="00:00"
  padding_left=0
  padding_right=0
  y_offset=-15
  width=0
  slider.background.height=6
  slider.background.corner_radius=1
  slider.background.color=$GREY
  slider.highlight_color=$GREEN
  slider.percentage=40
  slider.width=115
  script="$PLUGIN_DIR/apple_music.sh"
  update_freq=1
  updates=when_shown
)

music_shuffle=(
  icon=ô€Š
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$BLACK
  icon.highlight_color=$GREY
  label.drawing=off
  script="$PLUGIN_DIR/apple_music.sh"
  y_offset=-45
)

music_back=(
  icon=ô€Š
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$BLACK
  script="$PLUGIN_DIR/apple_music.sh"
  label.drawing=off
  y_offset=-45
)

music_play=(
  icon=ô€Š”
  background.height=40
  background.corner_radius=20
  width=40
  align=center
  background.color=$POPUP_BACKGROUND_COLOR
  background.border_color=$WHITE
  background.border_width=0
  background.drawing=on
  icon.padding_left=4
  icon.padding_right=5
  icon.color=$WHITE
  updates=on
  label.drawing=off
  script="$PLUGIN_DIR/apple_music.sh"
  y_offset=-45
)

music_next=(
  icon=ô€Š
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$BLACK
  label.drawing=off
  script="$PLUGIN_DIR/apple_music.sh"
  y_offset=-45
)

music_repeat=(
  icon=ô€Š
  icon.highlight_color=$GREY
  icon.padding_left=5
  icon.padding_right=10
  icon.color=$BLACK
  label.drawing=off
  script="$PLUGIN_DIR/apple_music.sh"
  y_offset=-45
)

music_controls=(
  background.color=$GREEN
  background.corner_radius=11
  background.drawing=on
  y_offset=-45
)

sketchybar --add item music.anchor center                       \
           --set music.anchor "${music_anchor[@]}"              \
           --subscribe music.anchor mouse.entered mouse.exited  \
                                      mouse.exited.global       \
                                                                \
           --add item music.cover popup.music.anchor            \
           --set music.cover "${music_cover[@]}"                \
                                                                \
           --add item music.title popup.music.anchor            \
           --set music.title "${music_title[@]}"                \
                                                                \
           --add item music.artist popup.music.anchor           \
           --set music.artist "${music_artist[@]}"              \
                                                                \
           --add item music.album popup.music.anchor            \
           --set music.album "${music_album[@]}"                \
                                                                \
           --add slider music.state popup.music.anchor          \
           --set music.state "${music_state[@]}"                \
           --subscribe music.state mouse.clicked                \
                                                                \
           --add item music.shuffle popup.music.anchor          \
           --set music.shuffle "${music_shuffle[@]}"            \
           --subscribe music.shuffle mouse.clicked              \
                                                                \
           --add item music.back popup.music.anchor             \
           --set music.back "${music_back[@]}"                  \
           --subscribe music.back mouse.clicked                 \
                                                                \
           --add item music.play popup.music.anchor             \
           --set music.play "${music_play[@]}"                  \
           --subscribe music.play mouse.clicked                 \
                                                                \
           --add item music.next popup.music.anchor             \
           --set music.next "${music_next[@]}"                  \
           --subscribe music.next mouse.clicked                 \
                                                                \
           --add item music.repeat popup.music.anchor           \
           --set music.repeat "${music_repeat[@]}"              \
           --subscribe music.repeat  mouse.clicked              \
                                                                \
           --add item music.spacer popup.music.anchor           \
           --set music.spacer width=5                           \
                                                                \
           --add bracket music.controls music.shuffle           \
                                        music.back              \
                                        music.play              \
                                        music.next              \
                                        music.repeat            \
           --set music.controls "${music_controls[@]}"          \



# backup/plugins/apple_music.sh

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
    
    args+=(--set music.play icon=ô€Š†
           --set music.shuffle icon.highlight=$SHUFFLE
           --set music.repeat icon.highlight=$REPEAT_HIGHLIGHT
           --set music.cover background.image="/tmp/music_cover.jpg"
                               background.color=0x00000000
           --set music.anchor drawing=on                      )
  else
    args+=(--set music.anchor drawing=off popup.drawing=off
           --set music.play icon=ô€Š„                         )
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



# colors.sh

#!/bin/bash

# Color Palette
export BLACK=0xff181926
export WHITE=0xffcad3f5
export RED=0xffed8796
export GREEN=0xffa6da95
export BLUE=0xff8aadf4
export YELLOW=0xffeed49f
export ORANGE=0xfff5a97f
export MAGENTA=0xffc6a0f6
export GREY=0xff939ab7
export TRANSPARENT=0x00000000

# General bar colors
export BAR_COLOR=0xa024273a
export ICON_COLOR=$WHITE # Color of all icons
export LABEL_COLOR=$WHITE # Color of all labels
export BACKGROUND_1=0x903c3e4f
export BACKGROUND_2=0x90494d64

export POPUP_BACKGROUND_COLOR=0xff24273a
export POPUP_BORDER_COLOR=$WHITE

export SHADOW_COLOR=$BLACK



# helper/cpu.h

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <mach/mach.h>
#include <stdbool.h>
#include <time.h>

static const char TOPPROC[32] = { "/bin/ps -Aceo pid,pcpu,comm -r" }; 
static const char FILTER_PATTERN[16] = { "com.apple." };

struct cpu {
  host_t host;
  mach_msg_type_number_t count;
  host_cpu_load_info_data_t load;
  host_cpu_load_info_data_t prev_load;
  bool has_prev_load;

  char command[256];
};

static inline void cpu_init(struct cpu* cpu) {
  cpu->host = mach_host_self();
  cpu->count = HOST_CPU_LOAD_INFO_COUNT;
  cpu->has_prev_load = false;
  snprintf(cpu->command, 100, "");
}

static inline void cpu_update(struct cpu* cpu) {
  kern_return_t error = host_statistics(cpu->host,
                                        HOST_CPU_LOAD_INFO,
                                        (host_info_t)&cpu->load,
                                        &cpu->count                );

  if (error != KERN_SUCCESS) {
    printf("Error: Could not read cpu host statistics.\n");
    return;
  }

  if (cpu->has_prev_load) {
    uint32_t delta_user = cpu->load.cpu_ticks[CPU_STATE_USER]
                          - cpu->prev_load.cpu_ticks[CPU_STATE_USER];

    uint32_t delta_system = cpu->load.cpu_ticks[CPU_STATE_SYSTEM]
                            - cpu->prev_load.cpu_ticks[CPU_STATE_SYSTEM];

    uint32_t delta_idle = cpu->load.cpu_ticks[CPU_STATE_IDLE]
                          - cpu->prev_load.cpu_ticks[CPU_STATE_IDLE];

    double user_perc = (double)delta_user / (double)(delta_system
                                                     + delta_user
                                                     + delta_idle);

    double sys_perc = (double)delta_system / (double)(delta_system
                                                      + delta_user
                                                      + delta_idle);

    double total_perc = user_perc + sys_perc;

    FILE* file;
    char line[1024];

    file = popen(TOPPROC, "r");
    if (!file) {
      printf("Error: TOPPROC command errored out...\n" );
      return;
    }

    fgets(line, sizeof(line), file);
    fgets(line, sizeof(line), file);

    char* start = strstr(line, FILTER_PATTERN);
    char topproc[32];
    uint32_t caret = 0;
    for (int i = 0; i < sizeof(line); i++) {
      if (start && i == start - line) {
        i+=9;
        continue;
      }

      if (caret >= 28 && caret <= 30) {
        topproc[caret++] = '.';
        continue;
      }
      if (caret > 30) break;
      topproc[caret++] = line[i];
      if (line[i] == '\0') break;
    }

    topproc[31] = '\0';

    pclose(file);

    char color[16];
    if (total_perc >= .7) {
      snprintf(color, 16, "%s", getenv("RED"));
    } else if (total_perc >= .3) {
      snprintf(color, 16, "%s", getenv("ORANGE"));
    } else if (total_perc >= .1) {
      snprintf(color, 16, "%s", getenv("YELLOW"));
    } else {
      snprintf(color, 16, "%s", getenv("LABEL_COLOR"));
    }

    snprintf(cpu->command, 256, "--push cpu.sys %.2f "
                                "--push cpu.user %.2f "
                                "--set cpu.percent label=%.0f%% label.color=%s "
                                "--set cpu.top label=\"%s\"",
                                sys_perc,
                                user_perc,
                                total_perc*100.,
                                color,
                                topproc                                         );
  }
  else {
    snprintf(cpu->command, 256, "");
  }

  cpu->prev_load = cpu->load;
  cpu->has_prev_load = true;
}



# helper/helper.c

#include "cpu.h"
#include "sketchybar.h"

struct cpu g_cpu;

void handler(env env) {
  // Environment variables passed from sketchybar can be accessed as seen below
  char* name = env_get_value_for_key(env, "NAME");
  char* sender = env_get_value_for_key(env, "SENDER");
  char* info = env_get_value_for_key(env, "INFO");
  char* selected = env_get_value_for_key(env, "SELECTED");

  if ((strcmp(sender, "routine") == 0)
            || (strcmp(sender, "forced") == 0)) {
    // CPU graph updates
    cpu_update(&g_cpu);

    if (strlen(g_cpu.command) > 0) sketchybar(g_cpu.command);
  }
}

int main (int argc, char** argv) {
  cpu_init(&g_cpu);

  if (argc < 2) {
    printf("Usage: provider \"<bootstrap name>\"\n");
    exit(1);
  }

  event_server_begin(handler, argv[1]);
  return 0;
}



# helper/makefile


helper: helper.c cpu.h sketchybar.h
	clang -std=c99 -O3 helper.c -o helper



# helper/sketchybar.h

#pragma once

#include <mach/mach.h>
#include <mach/message.h>
#include <bootstrap.h>
#include <stdlib.h>
#include <pthread.h>
#include <stdio.h>

typedef char* env;

#define MACH_HANDLER(name) void name(env env)
typedef MACH_HANDLER(mach_handler);

struct mach_message {
  mach_msg_header_t header;
  mach_msg_size_t msgh_descriptor_count;
  mach_msg_ool_descriptor_t descriptor;
};

struct mach_buffer {
  struct mach_message message;
  mach_msg_trailer_t trailer;
};

struct mach_server {
  bool is_running;
  mach_port_name_t task;
  mach_port_t port;
  mach_port_t bs_port;

  pthread_t thread;
  mach_handler* handler;
};

static struct mach_server g_mach_server;
static mach_port_t g_mach_port = 0;

static inline char* env_get_value_for_key(env env, char* key) {
  uint32_t caret = 0;
  for(;;) {
    if (!env[caret]) break;
    if (strcmp(&env[caret], key) == 0)
      return &env[caret + strlen(&env[caret]) + 1];

    caret += strlen(&env[caret])
             + strlen(&env[caret + strlen(&env[caret]) + 1])
             + 2;
  }
  return (char*)"";
}

static inline mach_port_t mach_get_bs_port() {
  mach_port_name_t task = mach_task_self();

  mach_port_t bs_port;
  if (task_get_special_port(task,
                            TASK_BOOTSTRAP_PORT,
                            &bs_port            ) != KERN_SUCCESS) {
    return 0;
  }

  mach_port_t port;
  if (bootstrap_look_up(bs_port,
                        "git.felix.sketchybar",
                        &port                  ) != KERN_SUCCESS) {
    return 0;
  }

  return port;
}

static inline void mach_receive_message(mach_port_t port, struct mach_buffer* buffer, bool timeout) {
  *buffer = (struct mach_buffer) { 0 };
  mach_msg_return_t msg_return;
  if (timeout)
    msg_return = mach_msg(&buffer->message.header,
                          MACH_RCV_MSG | MACH_RCV_TIMEOUT,
                          0,
                          sizeof(struct mach_buffer),
                          port,
                          100,
                          MACH_PORT_NULL             );
  else 
    msg_return = mach_msg(&buffer->message.header,
                          MACH_RCV_MSG,
                          0,
                          sizeof(struct mach_buffer),
                          port,
                          MACH_MSG_TIMEOUT_NONE,
                          MACH_PORT_NULL             );

  if (msg_return != MACH_MSG_SUCCESS) {
    buffer->message.descriptor.address = NULL;
  }
}

static inline char* mach_send_message(mach_port_t port, char* message, uint32_t len) {
  if (!message || !port) {
    return NULL;
  }

  mach_port_t response_port;
  mach_port_name_t task = mach_task_self();
  if (mach_port_allocate(task, MACH_PORT_RIGHT_RECEIVE,
                               &response_port          ) != KERN_SUCCESS) {
    return NULL;
  }

  if (mach_port_insert_right(task, response_port,
                                   response_port,
                                   MACH_MSG_TYPE_MAKE_SEND)!= KERN_SUCCESS) {
    return NULL;
  }

  struct mach_message msg = { 0 };
  msg.header.msgh_remote_port = port;
  msg.header.msgh_local_port = response_port;
  msg.header.msgh_id = response_port;
  msg.header.msgh_bits = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND,
                                            MACH_MSG_TYPE_MAKE_SEND,
                                            0,
                                            MACH_MSGH_BITS_COMPLEX       );

  msg.header.msgh_size = sizeof(struct mach_message);
  msg.msgh_descriptor_count = 1;
  msg.descriptor.address = message;
  msg.descriptor.size = len * sizeof(char);
  msg.descriptor.copy = MACH_MSG_VIRTUAL_COPY;
  msg.descriptor.deallocate = false;
  msg.descriptor.type = MACH_MSG_OOL_DESCRIPTOR;

  mach_msg(&msg.header,
           MACH_SEND_MSG,
           sizeof(struct mach_message),
           0,
           MACH_PORT_NULL,
           MACH_MSG_TIMEOUT_NONE,
           MACH_PORT_NULL              );

  struct mach_buffer buffer = { 0 };
  mach_receive_message(response_port, &buffer, true);
  if (buffer.message.descriptor.address)
    return (char*)buffer.message.descriptor.address;
  mach_msg_destroy(&buffer.message.header);

  return NULL;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline bool mach_server_begin(struct mach_server* mach_server, mach_handler handler, char* bootstrap_name) {
  mach_server->task = mach_task_self();

  if (mach_port_allocate(mach_server->task,
                         MACH_PORT_RIGHT_RECEIVE,
                         &mach_server->port      ) != KERN_SUCCESS) {
    return false;
  }

  if (mach_port_insert_right(mach_server->task,
                             mach_server->port,
                             mach_server->port,
                             MACH_MSG_TYPE_MAKE_SEND) != KERN_SUCCESS) {
    return false;
  }

  if (task_get_special_port(mach_server->task,
                            TASK_BOOTSTRAP_PORT,
                            &mach_server->bs_port) != KERN_SUCCESS) {
    return false;
  }

  if (bootstrap_register(mach_server->bs_port,
                         bootstrap_name,
                         mach_server->port    ) != KERN_SUCCESS) {
    return false;
  }

  mach_server->handler = handler;
  mach_server->is_running = true;
  struct mach_buffer buffer;
  while (mach_server->is_running) {
    mach_receive_message(mach_server->port, &buffer, false);
    mach_server->handler((env)buffer.message.descriptor.address);
    mach_msg_destroy(&buffer.message.header);
  }

  return true;
}
#pragma clang diagnostic pop

static inline char* sketchybar(char* message) {
  uint32_t message_length = strlen(message) + 1;
  char formatted_message[message_length + 1];

  char quote = '\0';
  uint32_t caret = 0;
  for (int i = 0; i < message_length; ++i) {
    if (message[i] == '"' || message[i] == '\'') {
      if (quote == message[i]) quote = '\0';
      else quote = message[i];
      continue;
    }
    formatted_message[caret] = message[i];
    if (message[i] == ' ' && !quote) formatted_message[caret] = '\0';
    caret++;
  }

  if (caret > 0 && formatted_message[caret] == '\0'
      && formatted_message[caret - 1] == '\0') {
    caret--;
  }

  formatted_message[caret] = '\0';
  if (!g_mach_port) g_mach_port = mach_get_bs_port();
  char* response = mach_send_message(g_mach_port,
                                     formatted_message,
                                     caret + 1          );

  if (response) return response;
  else return (char*)"";
}

static inline void event_server_begin(mach_handler event_handler, char* bootstrap_name) {
  mach_server_begin(&g_mach_server, event_handler, bootstrap_name);
}



# icon/Waka.png

‰PNG

   IHDR   x   x   ºÆà   ŸPLTE   ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ
wy¸   4tRNS üøôæ9ñ(È>ì½Y¡ ÕŒH.ß$Ìqgk­DtÁÄ©˜]Ø¯•xdL³ƒ{T4¶’Zéİ"  ?IDAThŞ´˜çºÚ0†eã2€,ÂŞ”QÆ9O«û¿¶>¥C•cc é÷ë'z#YÃ9ğªÒ ˜äınæu$¢ìxYw›OŠ …ÿ©vt›e1g³Ó¼ÿEÁôPŞ!â§ˆI?ËÙ4hššL»ê7«¢Õ$b£~|·İïˆûQCØ5§ºÙİ^«>¶7"êóìÑ—šØbCØ×Ğ›yDŞöuôvø.w¬û:±3~;\#ö=ôú§¿vû>ºóõElk‡v®¸‹ımwz÷Re%¡mw‰"U§£$]¶%Y˜<í-øJkw@µ¿äãŞÜÿ>ıyo¼¼ì­ê’èùğ¤×…BaÊpÙÒê¨ì-C‰hyLÏq¿î¬Ø¬©5NƒÕZ’ÛŒ,êc#Ñ[úàŸ{–‡'Îı%ù“åé©1ß^•æç¿¸ö¹(Şğ¤cM&
G°”é¡cû¥ÒÑDV7*ñPT’jäÃ‹ŠF(„Nö’;V¸ˆ×7†z+Çª¥Ğnh‡R¿;>Ã[:Ç:YâÎ:o™À›¢÷Õr«>$jœZ3”ú¬2OÉu…Û‡ZêWÈkãy£ÂİAMí*ä©1ĞL‚ü­ã3wÆì-
ÎA:èV· iÂUun¹;ƒ¨´Î
^¿ChDI¬Şh3X±34¤³n¹Ç"2ÒŞ+‡ÆtÕLØ’¾XƒíN} ©«¥}Ê×Ê´KK‘öNGhTGÍ|d«s¯İ,¸íY:Só…14¬w,Nş+Å¿ÜrQ“Ü§€ÃJN˜šRKàª&÷‹BDÕ³¹Lé(lr‡çˆRHDßºË¨~ÅcŠ¢ÁŞñ}7'ùYšb=c[/ı†&a™Éçu¸‡¡Ô	µôñ×‹xaBe›"¥V#ÃH`ÈV(ôrã‘43ø¥æÁ@²¸Şh‹™ÿcT2LiÈ03€Ö]Yš›Şír¹¹ûÊ@QÅè‘[2L–BÛÆ4i¸GDÌ8DÁ
Æ>yã 
vAfƒRéØ†\‰{ ]Ò^‚}j?½H¼Â#EÄ5t¿”oéröûUQŞ‹ìZdş€ª.”ÃÖ‘[v‰vÄıqû4šì£øLÅ™?jY”²öR£jËÜIMÇ5{°ÛİCİŞÖx<kñä£e	[
ÎØƒ>1š®(w˜‰­e‘|É¾Ş€ıTŸ`Ö†–€YŸŠ¹ü+ràj†÷Zg%ì›şİ`6Ña¨Õ[kSÂ@L)ŠÌ/‹ a©òêÿÿmö1Ì5uËqÇc?8uDÚšl6pb³¬1ë®ÍªiµU3?‰•<1¸ÕŒ5Ÿù“B.4·D¤‚ÔLYøVƒ/—!Í0ÿİì‚¬èğ;RÊÂ_.ü8±Å¢ŒÚ_E Xé0zğ8¡Â˜q`óÆ_øe*<ä8ˆ)''c\ ¤,˜2[FÑ ×,TM‚ÌŠË"VÌ€zÊ"$róÅS$EÔ+)@!EÔ=‘p³å”É^çR†ùj>êÓ¤·aĞC‡
ä€—Hû1}qƒe«`]Ùÿ“È²şkaƒÔ´aÖ¤k]8`Ê’›¶Q¾MÀj7™Ê~¬²0~qOıf´©yi¿IœîS˜Å¡Áw	”&şˆ%)bŒ§wYuùàÃ˜ "CŠ°_^•Úî%¥@)Š/¢Ü”sLD¹‰b7Îñœ¨YRôòÀ”/%¢^^6ÎÙîÉ!T±PNKÏ£âÊkşñ‹œ!‚’Ê4wÆ?s0ğj“ôÁÀ‹ºçñàPsA0„CMêWÏ3Æ½ĞàzpM£zî€˜BH–)\äÍ	õòvŒ¾µV/Ù1®Í€"[n"_–l2RGne“Ñ5ÚªtêdƒòF²D4’][ëÜ¤œu.Ö9³`„Í‚c³ cØ#+™=²ğº;O“i°{¯?CèBY`Ç‡Ø¨„öºM¿®mÎ·aìöieÇ<œbŞÏÂ­¹©¯uŒ‘ı‚F—NÃÜn%¥é€“7G/á,o{íH£ıRvÑ*n“cÔãaOJVü[o×Éj£dø^´L÷­jä¡^œ®¶¬Ö šÒÏ—‘ÎK    IEND®B`‚


# icon/aw.png

‰PNG

   IHDR  Ì  Ì   XÛ˜†  vIDATxœìxUEÚÇÿé¤Ğ!zï½ŠÒA¢XE°¡¸‚»¸+ˆ}õdVQT@À†€R¤C¨*½%Ô:$¤ç{föÄL¹÷Ì¼§Üûşç>’óÎärîùÏ;ó–`0£Šø•m¼J(m|­h¼"D_Cï‰ëJ\eGü9è:ÛÙ .]õwñç, d Hj|M4^â{Œ¯§œ1¾fYô~0ŒO`÷Æ”P@U ÕŒ?‹W= 5‘tB4Øà¸ñ:
à˜ñç³vOaœ&Ãü—@Cë ¨m|m €p»'gÂSİl¼¯C†¨æØ=9†±LÆ_i +€F hal—2&ÃÏ] vX	`±]Ì0~&ãkˆ{º–!„•T0¶Lc T2¾V4Îó±< ÀIãëqãÏâë q rí(Ãè‚“q;Åtp€ŒmÔvOŠ‘\°	ÀF ëŒ×e»'Å0faÁdÜ†ğ;èie[ö]ƒğJ÷X`€… ®Ø=)†ñLÆŞã- 4¶Z÷sÀ ‹Äò™(ãtX0§RŞÊ¹@? eìCJ²Lô€EÆ9(Ã8
LÆIÏñ~C$oäûÓ¯Ùmˆçt ìÃ€HŒ(	à6ãÕ@1»'Ä8Š4C8¿7^—ìã¿°`2veä  ½Y$â¹À\CD“íã_°`2V €»Üaˆ&Ã˜%Íˆ´ıÀl£¸ÃÂ‚ÉP`”—kfTÑih¤‚pt+CÁi#ÇóW ;üÆE
X0T0Àc jÚ=Æ¯9`€÷±{2Ã0yÔ6Î•2U=¿øå”W6€¥ šÚı!aÜÏõ½÷Æª 	às ­Œã$òjßoDdÇ½BÆkxK–ñ–P  <`ñğ¢‹q9 V‹¼¯¹4ã,˜Œ§”ğ„ñrKÃd†)ŒS ¦/nÍ0Œ† HqÀy¿øEñJğ¨İ2†aÜMG#˜'Û5~ñ‹ò•cCèi÷‡a÷hÔr]ï€‡¿øeÇk«qFl÷‡‘q|†Éèdè`´Ñ*e÷¤œN@@ Ê•+‡òåË#**
‘‘‘|Í{+VL~-^¼¸üshh(BBBä+88aaa”ß»ñ}Affæ5ÿ––†œœ¤§§#++K~_¼ÄßÅ÷’““åKü955)))òïâkŞŸÏœ9ƒ³gÏ"77×Ò÷Ë¥\0š_o °ÚèãÉ-ÈüLÿ&Ê(+ÖÏî‰8!€-[¶D:uP»vmùªZµ*ªU«†˜˜)znDˆíÉ“'qôèQùŠ‹‹ÃÁƒåë×_•ÂÊäË î5Îó?„Ó?‰0¢]Ÿ1¢_ıš   ÔªU7FÃ†Ñ¤IùUü]x…şDFFvíÚ…İ»w_ó5>>ÙÙì\eø^7*qJŠŸÁ‚é_„eëPÑîÉØEdd$zõê…¾}ûJRdXX˜İÓr4iiiR8·mÛ†Å‹ãçŸ–Û¼~L€‰ >n÷dk`Áô„›ô€çŒê<~Cpp0š6mŠn¸íÛ·G»víP¯^=éU2æŞæşıû±iÓ&ÄÆÆbÃ†Ø¹s§Üîõ3xÀ§FiHÆ‡aÁômğ"€vOÆ*š5k†ûî»:t@ëÖ­a÷”üáqnİºUŠç¬Y³¤€úq ş	à3#Ò–ñAX0}›ø»İ“ ¦téÒèÖ­:wîŒ.]º yóæ2Š•±œœ@´zõj¬Zµ
+W®ÄÅ‹í–L0ÖîI04ğSÅ7©`‚Ñ¬Ù'iÔ¨n½õVôìÙSŠd^*ãL²³³¥€.[¶?üğƒôB…¨ú(üÀ!»'Âè…Ó7ÿ-ôĞË¨ĞãÎœ‡ë¨T©êÖ­+S;Ä«M›6ò²D‰vOQ %%Û·o—Â¹oß>8p@¦µ$$$Ø=5]dØà{ ‹Œ¦Ö¼UërX0İO{ S¯>ğï¾ûn:Tæ>2şÃ±cÇ°`Á|ıõ×X¿~½/XØfxkìÃø#%Œ ƒ”Óò8p`îşıûsFpäÈ‘ÜG}47  Àö{Sãë®¤å^ØÃt'ÁÆï»'¢J³fÍpÏ=÷`Ğ ArË•a®çÀ˜3gæÎ‹;vØ=üàv ~—ƒãvX0İGk Ÿ ha÷DÌR£F>\
eƒìã"öìÙƒÙ³gãÓO?•eı\ÌV  øÕî‰0Œ/àe ØVòúÛ³gÏÜ¹sçæfeeÙ½ÛÇ¸œìììÜ¥K—æŞ}÷İ¹¶ßß&_™FüA¤İ†ñ%:Øë€¸©Wİºus—,Yb÷3–ñQ–-[–Û¸qcÛïs…×!îÃÉ0ê”ğ¡{ÂÂÂäê_x999v?S?`Ë–-¹#FŒÈˆˆ°ış7ñÊ1‚øÊÚıĞa
†Ï0Ëİ Şv[‘ôúõëcäÈ‘2%¤L™2vO‡ñCÎ;‡Ï?ÿï¿ÿ¾¬wë2NxÀ»'ÂüLçÑ Àÿ¸Óî‰xB@@ zôèñGíÖzõêqY:ÆäææÊ¢6lÀ¼yó°dÉ7Ušo4KØg÷DÆ‰„ voyôŠŠŠÊ=ztîáÃ‡íŞ‰cˆÏ;vln©R¥lÿüxñúŒƒ‚œ»Î €/ Ô³{"EQ±bE<öØc=z4o¹2®äÒ¥K˜1c¦L™"+¹€½ î3ª1Œßd4sv|ªH­ZµrgÌ˜‘›‘‘a·£À0ZHOOÏ>}zn5lÿ|yğJğŒÑ²±	ö0í£ª±İÒÕî‰Å AƒğÙgŸ!,,Ìî©0Œv233å®‰ğ:]À/  pÜî‰ø#ÜvŞå±Ú=‘ÂˆÆ/¼€ÿûßµ{:CBPPú÷ïÊ•+cÛ¶m¸|ù²İS*Œš p€OÔ	tìaZÏ= fÛ=‰ÂB9nÜ8<şøã·{:c©©©˜6m&OŒ3gÎØ=¢àk»'áO°`ZK= k”·{"ùQ¦LŒ5
cÆŒá~“Œ_“’’‚O>ù&LÀéÓ§íNAœ5tvÙ=Ó:ø€âvOäz"""ğ÷¿ÿO?ı4%Ã\ERRşõ¯á7ŞÀ•+WìN~\0À·vOÄ`Á¤%ÂÊGt´{2×ƒ'xO>ù$J•â}S—.]Â|€wŞyÇ;2Şf­± Ÿ+d»'ã«°`ÒÑÊ¨ÖQÃî‰\Ê—_~?ü°x`Æ3rsseÙ½±cÇ"11ÑîéäÇ1c‘¾Éî‰ø"ü´¤á£¤£Î*CCCñ—¿ü,À7ŞˆÀ@Nébo@óæÍe½äÄÆÆ"+ËQ} KÏŸD.t ö0õs;€oìÄõôïßS§NE­Zµì
ÃøÇÃsÏ='½NÂQ´šaÁÔK€Í *Û=‘<jÔ¨!»6ÜrË-vO…a|–üQÆ=zÔî©\Íq mo“Ñ ¦>ÅªÛ=‘<Ú´iƒ+V xqÇæ2ŒÏ‘šš*¦kÖ¬±{*Ws@? ¿Ù=_€±ôĞÀ:'‰e“&MğÍ7ß°X2ŒEDDDà‹/¾@ãÆíÊÕT œ·˜4À‚©Îp ‹ÃvÛ			‘|[¶lA•*UìÃøU«VÅöíÛ1iÒ$'Õ^«æ Œ°{"n‡·dÍ#Ş»—Œ—#¸ñÆññÇ£Q£FvO…aü`ÄˆX¹r¥İS¹š·üÕè€Âx	¦÷3zÓĞÌîÉ/ò{îÁí·ßÎ©"ã@¶nİŠ¹sçböìÙN	
Úeç, ©vOÆM°`zG)  4°{"B_xáùrCñÌÌLYf,ğğpyæÀ· ãdggËÎ?ãÇGNNİÓĞÀy»'âøiåoÛ¶óÌ3Ïàõ×_·{’€;wâàÁƒ8räH¾-“„XFFF¢Zµj¨S§ô¹–-ãëüãÿÂéŞ ğ´İ“p,˜ÓÀ2 ¶Ÿä:TvRpbÊ;v`ùòåØ¿¿××–-[C†AÃ†nÊ0J¤§§côèÑøè£ìŠ @O#ÊŸ)LÏèà{ QvN¢dÉ’²WŸ§!<ÈÙ³gËAUÚ·oÁƒ;)Êa´3ş|tş¼í;¢© î ğ³İq:,˜EÓß(/UÌÎItëÖŸ}ö™#SEÄ~Ò¤IHNNÖf3::ZÖë¬P¡‚6›ã4;†xÀ	‘´ ;±¬§“p~´ˆ½ˆh¶Û°AAA²‰í‡~(=L'2gÎÄÇÇkµ™’’‚Í›7£zõê(W®œVÛãÄgzèĞ¡2zõêÕ²ŠM-¸À>nH]0,˜s?€™ Bìš€Šo¾ùÃ†sl4éä)>è™™™2$¿fÍš,šŒÏˆÎ;Ë×’%KäbÑ&òDó8 õ³„3FøØÎ÷§U«VX¶lZ·nm×Š$11o¿ı¶6*rrrğûï¿ËRAËø25jÔg÷ë×¯Ç‰'ìšF €Û $Øh×$œ
æµÜdt-e×ùnPPşyÙ.¨lÙ²vLÁ#öïß/;Ğë<·,ˆ¬¬,LT±bE>Ód|±(>|8‚ƒƒ±víZ»ò5ŒÚ³]âíqvLÂ‰8sŸÏºXnçªT©‚yóæÉ(Q'séÒ%¼øâ‹ÈÈÈ°tÜÀÀ@Lœ8‘Ê3~Á¶mÛp×]wáğáÃvOE<±{N€ë¨ıgì¼K—.²`ºÓÅRğÓO?Y.–0¶gÍäw2ŒiÕª•|»ùæ›íÊx»'àX0ÿË( ½í|Ì˜12ÙßÛ—/_–[EvqàÀÛÆf«)W®-Z„§zÊÎiôğ¤p
,˜À0 oÙ1pPPŞyçL™2Åõ`kÖ¬!ò)
lO1Œ¥ã­·Ş’©eâÏ6ñ6€GíÜ)ø»`Şà;Ş‡ÈÈH™ñä“îY¸åääØê]
Nœ8agØ=ÃØÆˆ#°páB»Îğ ¼oä¦û-ş,˜·øJ,à¬8&&«V­Â­·ŞjõĞJlß¾/^´uÙÙÙØ¸‘£İÿ¤wïŞr—Ç¦Š_A >à®—FüU0{˜cGQ‚èèhùÀwr~eA‘w6WDa[iŞ¼¹|†T¬XÑáÅ3s‘vâwø£`ŞhÔK´¥6ìk¯½&ÛY¹„„:tÈîiHÎœ9ƒ]»¸zã¿T®\ÿ÷ÿg×ğ¡ æèl×ìÂ‘&z(`"€wDX=x·nİ0uêTYÉÃ©eî
";;[Ø½{5GA›6mÙâŒa¬@xš-[¶Ä©S§ì†æ½ Ê Ød´	óyüE0Ãl6:Xzf)Äñ­·ŞÂûï¿úõë»N,aD¦.Z´Èîi\CJJŠòFÙ=†±ñ,iĞ ¬T¡B,^¼Øê£
ñ,í ` €é ²¬ÜüeKv0€úV$=ÛœC¥ŒSS9Ö¯_´4¿XØ2L¡Œ93gÎ´+í¤¡Ñ¬ÂçñÁ.åŠ%nÜ3fà¡‡²zhí8U0…XnÚ´Éîi0Œ#¸ÿşûeê[,=å¥VıA0_ĞÜÊÃÂÂ0wî\ÙçÎpª`ÂˆÜåˆY†ù/ƒÆ‚P¬˜å1M ¼dõ Vãë‚ù €ç¬P¬î~øáÜqÇVKÆéÓ§qöìY»§Q 'Oärysıû÷—16Ä½hTNóY|Y0»øÀêAyä'KÖ†Sr/cåÊ•vOaE·nİì8
0ú÷´z`«ğUÁldäZZºÄ*]º4Æ÷Âşééé®¨ªóûï¿ãÜ¹svOƒaÅ/¼ ‹·[Lˆ‘£ÙÔê­À3Àb ¥¬´lÙ²Ò³©d	B,¯\¹b÷4ŠÄ	5nÆiTªT	Ë–-C™2e¬º€ï8¿ı’—øš`Şaä[ZVJ'$$?ş¸ôrš6õEÕÙ³g—{Y¿üò‹,fÀ0ÌÿhŞ¼¹|69Òê3ÍÆ³ø6+¥Æ—Â€ğ‘•ŠğÛo¿EŸ>}¬Ö>øàùAsU«VÅ³Ï>k÷4Æ‘oóÖ[oµ#wùa ÿ±zP
|ÅÃl	`ª•
ÏrŞ¼y>)–çÏŸÇÎ;í†×;vqqqvOƒaIÏ=1{öl;ò4ßĞÆêA)ğÁ7™Ã­0((HVÕp[{.OYµj•<t#«W¯¶{
ãX€/¿üÒê†õÅŒg´å5¼uã‚y7€šV ëÂŞ{ï½Vi)™™™Ø°a™ı&MšÙlÛ¶MF÷2“?”%;-®k]ÍxV»_ÌVöïÿ>ú¨•CZÊæÍ›‘œœLb»X±bxğÁeD1YYY8zô(™}†ñ†.»'YÌÃV¨·æ@ 7Y5X÷îİ1fÌ«†³…5kÖÙnß¾=ÂÃÃÑ±cG²1àğR~ãF….]ºX9d'£³‰kq³`Ö7ZÊXÆèÑ£­Îr:DššÑ©S'ùõ¦›n"<`ÁdÏ°¡“ÒçFwWâVÁ¼ÀZ#A–œòåËã£>òÙ ?æÌ™Cf¿V­Z2‘Z…Ûo¿l¬={ö ))‰Ì>Ãø
Íá£££­²8€•Æî ëp£`Ş`6 Kj>ÅÄÄ`Ë–-òÜ20Ğo—g,_¾Ç'³ß¼ùµcºuë&ó&)â¿páBÛãKˆgÚˆ#‹Š+Z5¬Pç¯ÇÇU¸MªXYœ ""B&¨VÍ²ÂA¶uëÖ‘Q½zõ?ı[Ş-›6mBJJ
™}†ñ%jÔ¨!™‘‘‘Vû•UÙtà&Ásı€%…ƒ‚‚d¾R»ví¬ÎV¶oß‹/’Ù«Øüâ½‹
233±~ızÛã‹´nİZËX˜£YÊ8Ó´4)T7	æ8 İ¬ì­·Ş’ûûş u{¬æÍ›çÛĞ644TFÎRáæcıúõÃ{ï½gå¸&õÀ-‚ÙÀËV6fÌ<ùä“Vg+—.]"/'×¹sç¿×¥K²j·–øc;yì±Ç¬ÎxÍ(oêxÜ ˜‘ f}ÖÈéÑ£&OlÅP >>Ô~ÅŠQ¯^½¿]è÷UqCl†qo¼ñzõêeÕp¡ ¾pCé<7æ[FÎ%9ÕªUÃW_}euE[¡®Š#¼Ë¢<HÊäé½{÷"11‘Ì>Ãø"âøùçŸ[Ùß·!€[5˜Yœ.˜ <bÅ@ÁÁÁ²ûHùòå­Î1Pz˜aaaQ6kÖ¥JÑôûÎÍÍå‚ìc‚èèhÌŸ?ßJb¤UÎ‘Yœ.˜ÿgÕ@Ï?ÿ<Ú¶mkÕpàäÉ“8xğ ™ıÊRxEˆ!C†e®]»–ô÷d_¥]»vxî¹ç¬r‚•ƒy‹“s€;­È†›ÂÌ;W+§ víÚ²§4iÒ„,qZü³fÍ’Ş&Ã0ŞñÂ/ MËÚYŞiÕsßNÌ’ Ş´b ²eËÊÜ£àà`+†s‰‰‰Ø¿?™}3ç’5jÔ ™‹àôéÓò<“aïÏÆùóç£\9KŠ«Áh8]ÚªÁ¼Á©‚)Ä²õ yÅ	(ÔNeåÊ•dWTTZ´háõuùUÒ	GÌ2Œ9ªU«†Ù³g[uYÀ$+ò'
f Ã­èµ×^³2tÚ1¤¥¥ÉÒqTtìØÑ”ÇN-˜;vìÀ¹sçHÇ`_¥Gxé¥—¬îQ –öó§	f„Q_¼xçÎñüƒzG²aÃ)šzuvy5•+WÎ·".8b–aÔxî¹çdãğ1€¢£-Äi‚ù
€:Ôƒ”*UJæùS¾eÔ¢Ñ´iSy.lá•R–Ê¬[·¤c0Œ¯"ÄŸ}öÊ”±¤¤w] Ï[1§8I0›°¤›é|àóH
bÏ=8uê™ıÂÊàye©<Ajjªl×Æ0Œ9ªT©"{hZÄ3N*›çÁğ+Êß=ôĞC¸ç×µaÓeàKùòåÑ A%+VD:´›ÔÅæÆ×8p †jÅPB>tJG'f) ? hE9H`` <³œ6må0fëÖ­dÅÈu4héYæñãÇÉÎ3Œ¯óÉ'ŸÈgªõÛø@	êŠÂ	ªı9€Û¨yõÕWåËßò-óÈÌÌÄÔ©SÉÎï:tè€îİ»k±U¢D	9ßh±—hØ°!™}†ñu‚‚‚póÍ7Ë¸R¶êÍ¦PTv{˜7¸‹zjÕªaÜ¸qÔÃ8šM›6!%%…Ì¾êÙåõtêÔ‰4(ëÈ‘#d¶ÆŸxñÅÉSÂ† èhÅ@a§` xÇŠ’{ï½×/#b¯†òÜ®T©RÚƒ¨J–,)‹²S!“ª, ÃøòÅ„VL±b ‚°S0[Zıt×]äN¬£9xğ Nœ8AfŸju©Ûk½šŒŒlß¾Ì>Ãø>cÛ¶`§`ŞbÅ 7Üpƒ•…ƒ	uT(•`Ö¯_111$¶Á¥òFíÚµ3]°Äı­èzìÌ~Ô„……aúôé¤y}N'))	¿ıöé”µx;v¤;²ˆ‹‹ã³L†Ñ€xÆ~òÉ'ò™k½­$?ìÌÚ†kMÊsÏ=‡FQãhV¯^ììl2ûâƒBY¢C‡¤)&ìe2Œ4h€±cÇZ1T+*Âå‡]‚ù†‘JFÓ¦M­úÏs,999²%Mš4‘)T±¤lì½eË\¾|™Ì>Ãø9)B;&R’V¦o2uŞ¥ğJ~üñG„††RãxvïŞK—.‘ÙBiÅa¿~ıPº4M{¼¬¬,|õÕWÜ\ša4 ¹?ıô“<Ó$f !š–·Y-˜Ã¶©^½:~şùgT­Z•rWğûï¿“Úïİ»7¢££IÇ€QÈàöÛo'³ÿë¯¿’Ÿó2Œ¿P¥J,]ºÔŠgğ8 ÷Qr5V
f¨•ç?üğCÙÀ˜âããÉlKOŞ*Z¶l)…“
>Ëd}ˆÏê{ï½gÅP/Qï]•‚ù€š”8Pz=œœŒ“'O’ÙoÓ¦¥!Ğ7Şx#™ı}ûö!!!Ì>Ãø·Şz«|SÀÔƒäa•`†O:@X&N´åØ‘¬]»VıPAYT  :uêDš"ÄÍ¥F/o¾ù¦©&/;˜äX%˜ İĞ~úé§ÉÛB¹!”kÖ¬!³_µjUÒÜË‚(]º4é™ill,®\¹BfŸaüÚµkcÔ¨QÔÃT7v0É±B0‹M@É¨P¡‚ß§\Ío¿ı†.ÙïÚµ+™í¢ ,òœ7’ÙgäÅ_”}n‰y@8õ V¦X^T¦àõ×_'q”¥ğÂÃÃÑºuk2ûEAİA¼wœbÂ0ú(^¼8şùÏRS	ÀêA¨3
Àß)ˆ‰‰±ªó·+8yò¤,¶NÅM7İdk~+õVğ™3g°gÏÒ1Æßxøá‡IëB<gh”‚`6 ÒD½Q£FYÑñÛdffbÖ¬YdRùòåmB®V­¹hÎ;—´w(Ãøâıä“ORSÀ,C{H TšNÔÖÃÃÃ1räHÊ!\ÅêÕ«Is/ˆÈÈH2û„!C†qúôi,Y²„t†ñ7şò—¿–Ñ4 €¬m
¥`’çüãÿÍ‹H¯’22¶L™2hÜ¸1™}o¨R¥
jÖ$MéÅúõëI‹Ö3Œ¿Q²dI<õÔSVÕ‰Ê0¥`Òe™([¶¬L%aşË®]»¤gDE§NµõMzåÊÒ¦ÛãŒ;–¬.ôUiÕ0ˆº}—ğ.92öPFÆ
¡´²'´nİZFßQB¹½Í0şˆğ2ÿö·¿QÓê“J0ï@¶Œ(W®xâ	*ó®ƒ:²3&&Æq‹+jÙrsi†ÑÌòåËS!´‡¤[•`ş•È®düøñäŞ…›Xµjiî uî£Y:wîLºM|øğa2Ûã¯DEEYqœFRÉ†âiÓ@{»áí<öØcTæ]GFFyu§
f™2eH›Õ:u
/^$³Ï0şÊ“O>)+´Ò–â,“B0I—Ï=÷œ¡É®Aˆejj*éNLÿ¯²3Œ~"##­(gª]‹tŒ3êÆ’´”¸ÿşûñê«¯:*ZÓNÎ=‹O?ıTz™TÔ­[½zõ"í¢Btt4ÉZ™=zTz±%K–$±Ï0şJÛ¶mqàÀìÜ¹“jˆ â hë¤¯SyÊxŸJ,kÔ¨éÓ§Ë`æ¿,X° —/_&³/DrÈ!_ <!!!$¶Åbä‹/¾ ±Í0şŒx–Ïœ9“2§ZhÑ Êé2¨óIøÊjñ/½ô’­5LÆ•+WğûïÚNùR¿~}ês-DFF’„?vì 1â™şì³ÏR@[98]‚ªsR×S¥JÜwß}Tæ]É‘#GHDÃ¦&Ñf¡ëªU«Hí3Œ¿òÀP·ÿú‹®ÓºóÊ"ë£G&Ûrs+Ô9‚%K–DÓ¦MIÇĞI5Hƒ“¶nİŠK—.‘ÙgŠfÛ¶mxå•Wp÷İwãæ›o–[ñ'N”yÈŒ{	£.Ì^À­:é:o\ ‡&[×P¼xqxÁ5c¯åÃ?”¢©èß¿?úöíKfŸ‚õë×Ën-TÜzë­èÓ§™}&öìÙ#wÿòË/ù~¿^½zøé§ŸÈ»Ø0t\¸pAv"JNN¦â' ·¨ÑáaÖĞMƒ|yä‘GX,óòL-((Hö½tmÛ¶%í¦²zõj.Èn1ûöí“çÓ‰¥`ÿşıhÑ¢o›»˜Ò¥KãÁ¤âf Ê[P:óªŠAVôPsqqqHJJ"³ß²eKW¦Q„„„–Ëï9u s-&LnE!şoú÷ïO™¢Àó·¿ı2"_~H‡¥:‰‚èİ»7jÕªEeŞ•¤§§cöìÙdö£¢¢0`À 2ûÔˆ{†²°Åüùóù,Ó.\¸€1cÆx•Ò“œœ,Ï6÷îİK:7††š5kÊÿ?Bş
 ¾ŠUÁü ²¢®÷Üs•i×²|ùr?~œÌ¾X¥—-[–Ì>5‘‘‘¤åòÎŸ?…’ÙgşÛL }ûöxóÍ7½ŞOLL”AŒ;4h¥ù ^W1 "˜Ut¢†ÓZJÙMNNÖ®]Kf¿X±bh×´+›%PlÚ´	)))¤cø+©©©2¸êÀ¦mP×Vfè¸ñFÒ6Ê‚~ *™½XE0¢ê9#i¾^½zTæ]ÉöíÛI‹‹U½M·S­Z5RûØ°aéşHVV–ÜUŠU²#¼LÆXğÜ0ÜìÅf3@ÇjaŒ9Ò±õKí‚²I´ S§N¤ö­B&uŞ.uK5ä©§Ò²İNVpŒ!F<ó-èFõˆÙ”J³‚Y[GˆnA„……qeŸë8~ü8:Df_¬ê*U2½Sá(BCCe¤/%çÎã„y¼üòË˜6mš[uêÔÑb‡±‡aÃ†I ¤& Sç6f³¹Éë<â®»îB¹rÚêåúÔŞ¥›Êày‚¿×—ÕÃÇ¬5P§gÏÚl1ÖS¶lYÜ~ûíÔÃ˜Ò0³‚ÙĞäuñè£Ršw©©©Ø²e™ı’%K¢ysÒ5åÔªUU«V%ƒS…â‰'Ğf/$$?ü°6{Œ=X MÌ\dV0ÉŠŒÖ®]]ºt¡2ïJÖ­[GÚó²cÇ²º¯A}&Ë‚©ÆñãÇeOVV–6›O=õ”|†0î¦{÷îÔ[ëÍ\dF0CÄ³ÈÌ`Eˆwß}—ƒ}®"11K–,!³…=HÊ ÛN‡dl*=Jz®ìË¤¤¤ÈRh©©©Zì•/_ï½÷&Mš¤Åc/BŞ~ûmÊÊ?ˆY¯03›;Ä˜¸®Hî¸ãÜrij§ëøúë¯=*f–ÆûD*I~¯ù¾ûî#[€åääÈJ4-ë—/_–gÌË–-Ób¯xñâØ¼y³ÜÚõÅ¥OŸ>2'—ˆJ ¼.ifF0ÉJ1ğÙåµœ>}š¼ÌeK,'Mš×•˜˜(‹3‘™™)ÛsmÛ¶M›Má©úú}ì¯k‚×Zæ­`Âïí P­Z5n»•+W’{/şĞ‰úLœ»dx†¸—GŒ![qé"44TöËe|áe"é Ê›¼Lá“d‹U"o§ü´´4ò_aaa¨\¹2éN Y³f(S¦™ıßÿ]æe2…3~üx|úé§Úìà“O>á &00<ğ •ù£Tçóñr ²jè\hıZ„X
Ñ¤¤]»väqœ€øĞQÖ¨¤®ñë|ğÁÚr¦L™‚¡C‡jµÉ8bmğj[ÖÁ, —÷ó)šæÍ›£aCÒÔN×±zõjò1:vìH>†S¿kp°×Aq³nİ:y>Çü™ï¿ÿ^{_Û§Ÿ~ZöOd|Ÿ&MšÈàD"úÚæŞæ  $á”Ä-]\Ç™3gÈH×®]›<±ßI”(Q‚´8Crr2iq	·‹{ï½×ë6]…!<É“'k³Ç8B(fœez„·‚IÂİwßMeÚ•9r„|,Aı;S—/t»wïFß¾}µåZ
ºvíŠ™3gRæç1„x[Öã:|Şu5¼=õ”x€4¹Üüúë¯¤ö5j„V­Z‘áDêÔ©CÚcõØ±cX±b™}7±zõjyn|şüy-öJ”(‰'bñâÅÔ…¹R¿~}¹SAÄmâñàÉz*˜#(¶c¸;úudffbÇdöÅÊ|È!~»B4hi¡†o¾ù†´g©ÈÈÈQïIIIZì•,YRU7Îg‹l0EóÚk¯Q!+°¿xòƒ>5Ir/Ûµkçy€Ş°iÓ&Òà‘¦M›’¦X8á´oßÌ~vv¶ òWrssñÈ# ..N‹½àà`Y ]Ü·ŒS«V-Ê±Û<ù!O3†ªûü™5kÖÚ÷µ6^f >ËŞÎ‚ânâé§ŸÆçŸ®ÍŞ]wİåWÑÜLájF- Šú!Oó³İ©‹B|˜ÿqèĞ!YĞ›ŠòåË£Aƒ"ï	Ÿ§bÅŠ²çIIIäçĞNdÊ”)xóÍ7µÚäÔæjLi¾wQ?à©`j§R¥J\ÿñ:¨£,…gÅ`şa¹-‰¿•Ë›3gyæ­6ÇOº}Î¸ñ¹‰!éı!¸¹¨(*“; IWŒ½+¼’¬¬,®Hc@]dàĞ¡C2jÖr]ÅBoØ°a²â‘.†"ƒ<æzêÕ«‡“'OR˜îj ¥ôE	f $"ÄÍA]Çš5k´&wçÇ·ß~KjŸ¹áeŞÿıvOƒ”;wÊ¶|éé>c¼¦{÷î˜1cï†0ù"“h'@{ –Y+jK–¬9%æÿğ÷ÈJ_eóæÍ2ÅÂW9~ü¸,L 3¦uëÖøî»ïd†ÉúõëSš/t[¶0Áğ şùü>›ø,Ğ–³Æ8êœZ»¼÷ß_ŠÛ±cÇ´ØŒˆˆÀóÏ?/·w£¢¼ê¸Äø7Üp¥ùaÆ¶l¾¶%ÛÛèJ­€€ ´iÓ†Â´ëœ_~ùÅîi0DüöÛoRX|‰yóæá‰'Ğf/<<K—.%í(ÃøB;BBB¨âªè`q~ß,ÌÃ$KØkÕªŠ/NeŞU°Xú6‡¶{
ÚÑ™:„/¿ü’Å’ñ˜°°0´mÛ–rˆµÏÁìÓ‡¤pëHNNÆÖ­[íCÈÙ³g‘`÷4´1aÂÙDo¿ı6n¿İãÚ×#¹ùæ"3@T(°²IA‚Y@ªÙÜrY,‘«àŠşuõ&«àóÏ?¯Í^×®]µní2şC¯^$­™óhcDÌş‰‚ó&#S;¥K—æ€îÒïWlÜ¸W®\±{J¬X±BTÏÍÍÕf“«ø0fi×®,ÊOD€|#‹
L²âİºu#í|ï~ÿıwœ;wÎîi0®uÓj¶nİŠhM‘é×¯ú÷÷¸o/Ã\ƒĞâºØòûÇ‚“,n—‹ÿn6ì_ˆÿoŞ™UÄÇÇKaKNNÖf³mÛ¶²”¿¶˜côĞ©S¾š¦‹|·Aó»cŒ=\X0!Ë:8pÀîi0rúôiìİ»×îixÅÙ³ge€^bb¢6›µk×–íº"#ó="b!î:tC~MGòÌÚFĞvš6mŠæÍI:…¹†œœ<áFoƒQcîÜ¹HMMµ{E"îÑY³fÉô¯}ûöi±*Ï,ccc­Å&ãß´iÓ6¤2_
@Íëÿ1?Á$›Áı÷ßï÷Û0G‘…¹ÿãÔ©SX²d‰İÓ(’Q£FaèĞ¡Úªø„„„àûï¿Ço¼AÚVñ/„–Üwß}”CüIóS¯ÊT£wèĞÊ´k‚Éø/ëÖ­st}Ù•+WbÚ´iÚìà£>BïŞE¶d¯!Ö”*×ÿC~‚IÒlL¬2}­D˜âããíc#W®\‘EÙŠğu2aÂ>\«M†É£}ûö”YÒBË³iÓ¦²À²¿Ã&ãÔrˆ?şø£|éâñÇÇ¸qã´Ùc˜ë‰ŒŒD£F¨ÌW¼şòÌ?ıˆ+Ì»‚3gÎÈhIÆ¿IHHÀÁƒíÆ5¯÷{îÑÖº~ıúx÷İwµØb˜Â Ô“ÄÃäê> jzÊ¸'İ‡’¹–)))Úl>õÔS²°:ÃPC¨-mÉ’x˜şŞÎ+##ÃÕÕ^½lß¾]kãe³œ9sFæZêÜùhÔ¨Ÿ[2–A(˜Ez˜bIXA÷¨‘‘‘Ô]²K+xÆİ8¡–ğåË—e#E4*Uª„E‹É—cB[ˆî·
×käõáEíÂ³Zéİ»·_oÏœ;wNV7¡",,L?…††’áìÜ¹SN§bùòå²GÕªUÉÆ(ˆà™gÑ–,>ß>ø ^}õUT¬H²IÅ0ù,Û}}ÿı÷ºM‡hà°öë³«î}ûö¥0ëÄÃI¬æ©7Ué§|ùò¤‚™Ù³gãÿøÙùñì³ÏbÒ¤IÚì`ÆŒ²ØÃØĞÁ„¡‰æõ[²$ñ¹-[¶¤0ë
’’’dg*ÄÊ»ÕÓP©R%òš§ñññ–enÙ²E«X
¦L™ÂbÉØ
¡Æ\£‰ä‚)è„õşÏªU«Mf¿E‹(Uª™}FÜ»VxîVææ¾ùæ›Zí=ıôÓÜ×’±&MšP•]-P0ÅŸè­víÚ~ ••…õë×“A\±ßïéÜ¹³Ür¤ÄªêO±±±øúë¯µÙ»ç{0yòdmöÆ,¨^½:…éFWw-¹Z0ÅhÚ•°
ƒãÙºu+.]ºDf?&&F.H:Ê—/O¾Cb…‡¹{÷nyÎ“™™©Å^×®]1sæL¿o¦À8"­‰P)ï/Wßíu(FkÜ¸1…YW@İ$Zx—ÔŞCßÃU¦®
;ù‘ ÅòüùóZìEGGã›o¾‘ÑÙãµæm¼Z0I\õ0>Lê9£]»vdö™ÿÑ´iSÒ¶Tiiida—.]B¿~ı´Ş‹#GässÆqj&5ÔŞe•*UP¬X1Ò1˜ÿ"¼ø;’Aq¿ddd`àÀøõ×_µÙ,Y²¤L†qV{˜Úİ•¨¨(¿Œİµk—ß§¤Y³f¤ö™kéÖ­iıû÷k[²d	Ú¶m‹¥K—j±'C†‘p…
Ú‹1Œ2Mš4¡êˆõG]×ÀüşQ-Z´ğ»sÜÜ\|ñÅ¤gR‚æÍ›“Úg®%44ƒ&cîÜ¹HMMU¶3eÊYVç6ï[o½%ïëjÕªi³É0:)V¬•#Ñ6ïy‚Y€vi®[·®n“'11‘<½dÉ’¼Ê·š5k’
FFF†re¡9sæÈ’w:?~<F­Õ&ÃPP§IìjIãõ‡`’ì5ùcÊÃáÃ‡ÉÇèÔ©‡óÛuÄìªU«ä.…Ä½7lØ0­»C†Ák¯½¦ÍÃPB¨9R#Y05sôèQRû\
Ï^Ú¶mKZ.ïÌ™32gÒo¿ı¶¬O«‹îİ»Ë±œºÄ¸BÍ‘[K¤‚ITyÁÑÄÅÅ‘ÚçRxöB^.ÏLséãÇcúôéÚæĞºuk|÷İwÜ‡q„šCïaÚÑ¶ÈN®\¹"“Ä)áRxöC].o×®]^5tNJJ’…	tU•ªY³¦lG¥ÅÃX¡æ\#˜Ut[ë‹·nİ:ÒBë\
ÏP—ËËÍÍÅêÕ«=úÙ´´4ôïß;vìĞ2vDD/^ìwŸ]Æ7¨\¹2Õböš-Ùzº­—+WNV£ñN:%sß¨ïå!Cø<É!8Pëı‘‘!{¦^¸pA6ÿöÛoe1ƒ#Gè9.Z´­ZµÂÚµkµÌAÜ[ï½÷ì`Ï0n$44”ª*—¿ÍûÄ×Ôm]¬Âı‰¯¿şZK]AtìØ‘½K!<0ñÿ±oß>Ó6Îœ9#ƒÄöïßŸo*Ò_|ñÇŸ4h€ûï¿_æW
‘œ0a{î9ÓcçÇ»ï¾‹áÃ‡kµÉ0V#´çìÙ³ºÍÖ‚!˜âUF·u:ÿ8}ú4öìÙC:ui6Æ{jÔ¨áµ`
Or÷îİØ»w¯ô&=EüüóÏ?/_UªTÁ‰'LÌ¸`^~ùe<ñÄZm2ŒiO9 AB,£ói$­u§z'¡’;ç	õêÕ“İÿgáMD^ff¦¬éºcÇåÔãÇ+]=<ò^zé%­6Æ.ˆ´'@Y!˜$%cüÅÃ?Õê,EÁ‘±ÎÄSÁ<|ø°<g¼|ù2ùœ¼¥_¿~xÿı÷íÃhƒĞY« <K’ÃFñ0ccce:	%K–äBë¥téÒE–Êb¹xñbGŠeÛ¶me)=
Îc|Bí)/³4…eñ0=ÿ7K§NduÆ™V*O,¤¨ï³Ô®][æZúËÂ–ñïéÒyEeuNaÖQìÛ·´P—Ás>•ÊKNN–©!)))¶Ì«0Ê—//½Şèèh»§Â0Ú!jñ%(H!?Lê&Ñ\ÏùäW*/--?üğy×3„††Ê|aì$Äø„Ú#“ƒ~L°}ûv­ı¯G¼·ß~;™}F·ÜrËyÇñññ²¯¥ÅF_ËV­ZÙ=†!ƒP{*’	¦/ŸdeeaöìÙ¤©$ıû÷§ªXÁhFÜëwİu—ğŞ›·a'NÄÈ‘#íÃB(˜1B0I¬ûò–ì¦M›H£ƒƒƒÑ®];2ûŒ~j×®6Ø=yì±Ç0nÜ8»§Á0ä+VŒÊt¤L’R_nDùX¹reÊÿt†€É“';v¶Aƒ²F,ÃøaaaT¦é3$$„Â¬í$&&’7‰öÇ>¢næÒ¥KxçwìFœ:uŠ´Î1Ã8	Bí	‚I²wê«‚¹yófò1jÔ¨A>£>úÈ«º°V#æöñÇÛ=†±JÁfÓ;¶nİJ>{˜îbæÌ™vO¡H¦OŸ1cÆØ=[9ş¼ìsøğa˜•‘‘!¶¢££eÌ@™2$v>x/×­['ß×ÜÜ\/^\vóiÔ¨‘-}U	µ'‚ÓÒÒÒ¼ê„o†’%K¢B’Àe† ±€Ú¹s§İÓ(’İ»wËT¨–-[Ú=[X¼x±¬lTPdû²eËpÛm·É®@Ú{Qø$ééé2ßxíÚµrñ‘uëÖÅwŞi©@)˜âÎ ‰.ñÅú”V¤ğÖ],Z´Èî)xeƒs§"¹Ÿ}ö™|°––šš*SÅ¦L™B¾(öN<){²®X±¢@±8p ÿú×¿¤j„Ú#·dIäØ“2ïFtl=HÇ`ô2kÖ,»§à1Ÿş9}öY»§a	â!.¼Æ•+WÊ2…×^{Mzâıúõãò×‘••%½õåË—*”W“““#›¡‹k­è¼D¨=!T‚é‹Ã©sKÄé$.âÒ¥KòLÌ-ìÙ³Ç‘]S(˜>}ºÜ‚õF,óöÍ›7KŠ s¿«ùæ›o¤`z*–W³hÑ"r§´Ú#“Äz@@ …Y[‰ˆˆ +ìƒ:uêØfh8ş¼İSğ7ÎÙ[vîÜ)u«"Dáë¯¿Ö2'_@Ü;kÖ¬1}½X¬8p@ëœòƒğH+˜L0}ñN,êÕ«Gb»K—.>¹ÈğeÒÒÒì‚×¸qÎŞ²|ùrm¶„ğ<yR›=7³aÃé}«°oß>mó)Âçh{˜^BQ¸ºdÉ’êxÁ83ÛRv“n÷H¹pá‚ömr'—<´9èVlq:kA¾ç#SwÚÇ­·ŞêÓ¥Æ*~ûí7íçdÛ·o×jÏ$&&j‰vû‚Mf6…a+wí@¬^î¸ãmt“&MĞ¡C-¶kqã"‡°Î¦#‚©›sçÎ‘6ŠwºZZÔ˜““Ce:›L0	'm;Íš5C·nİ”íT¬X<ğ€Ïn_û:nŒhvãœ=åÊ•+8xğ ‰m
!v:‚¨¥K—Öb§05:ÁôU3áe¶iÓÆôõB,Ÿzê)Ÿo´íË¸±”š/÷Xİ¹s'²³Ig¤ÍâNFF†ÌOÕA­Zµ´Ø)Bg-+@&…eª×)á¡‡BçÎåÇ¾}û<Ú¶7L÷îİ¥—ê‹Åü‰%J ~ıú–Dşé Q£F>»@IÑ±×säÈ°R®\9²1œJ\\œ
—Ÿjµ'“S‘:uêü‘?yùòeYWñàÁƒHJJBff¦ÌÛHõêÕÑ´iS™oÉø÷ß?^xá»§áC‡µ{
dˆEuÛ=!ş(˜º¼Ëš5kZrî¯šúRR0I³„XøÅ‹GŸ>}ìc!}ûöu`úò½iÅ–é©S§ÈÇp"‰‰‰ZìXÕ¹„P{® é,ë‚Éø­Zµ’‘ÎN§qãÆhŞ¼¹İÓ ÃŠ1ş*˜º~o«v×=ÌTL†QdøğávO¡H~øa»§@FRR’Lı Æ377W[÷«“P{X0F•#FX.o–2eÊà‘G±{dX%dB8|9].?=ª­œ¢U}~yK–aLTT4h`÷4
äé§Ÿ–çë¾ŠU‚)iTyNEWşeÕªU©ÅVQP{˜W(,»±Î&Ãx‹¸Ïï½÷^ÇÖ­]»6ÆŒc÷4H±r«Ôßò1uı¾-[¶ÔbÇËïIÁô¾aœ\¹B¢Ãã„X0 sæÌ±{*ù€÷Ş{Ï§«ûÀbÁô§Š?çÏŸÇ‰'´ØjÑ¢…;@Ø‘'E&Iï3[Æ-$%%aÈ!X²d‰İSÉ—¨¨(Ì=½{÷¶{*¤dffâğáÃ–wîÜ9¿)Æ¾téR-ÛZµjeYJ	Œ|x"„`’,ÏX0_eÏ=²ÅüùóíJ¾”.]ƒ’mã|áñ¥¤¤X:¦_'==ëÖ­Ób«oß¾Zìx
¡ö$
Á¼HaÙÕ2şÇæÍ›e9ÄcÇÙ=•|bÙ¿Ù•DWÀ†“±ãLñÈ‘#¸x‘ä±évîÜ©%Ÿ1::•*UÒ2'O!Ô‹d‚™šJ|Ë0¶±|ùrôèÑÃ’&¸fˆŠŠ’MòêÅÆÇÇãÒ¥KvO‹ŒììlìŞ½Ûòqsss-)”`'º[VûäA¨=„`^ °lõ6	ÃPòå—_ÊÒr„ç#ÊÏ÷ê~—¾ş`?pà€ms_–ÍÉÉÁ®]»´Ø²C0	µGz˜g(,ó&ã+¼ûî»²p¹Ùü.á•Ö¨QCû¼ò(Q¢„Ü†­^½úŸ¾çËÛ²vŠÖŞ½{}öØéĞ¡CZD§lÙ²2ÿÒjµç4YĞ{˜Œ/ğúë¯cÔ¨Q¦+¼´oß^‰ìŞ½ÿüç?µöĞ,V¬˜´?xğàL{öìñÙœh;YYYR4}Û±v4Ç'ÔÓy¦özO,˜ŒÛùşûï1nÜ8Ó×‹‡Å”)Sä×ğğpÙÕäğáÃòßT
¶‹•û7Ş([‹µjÕJöf-!–û÷ï7=–S9~ü¸%õcÃWs2uyîVæ^^‘öd8,K ÎĞÚè·d7#„füøñ¦¯"öá‡â¦›nºæß‹/.+ïˆ×öíÛ±xñbÌš5Kz‚…QºtiÔ«WOn»
Áôá1¸¡£Š78A¬vîÜ)wíŠ6µ[/Uª”ìiD‚yV8–y-ÿéÌ3gHF†ñaûÏşƒ©S§Ê³o)V¬˜<ïüÛßş††ú³-[¶”/!Ì—/_–•UÒÒÒşØBã?şXæÄ…„„˜ş6mÚ$–ÄCÌïÑÚµk•lˆX|ÄÅÅ™¶!î•õë×£cÇJsqË–-Óbç–[n±e;F‘|äÃ O0h¯ÓúÙ³gå>pp°N³CÆáÃ‡ee³[˜+V”£™­(áyæW ½ÿşrkX!¸B`„-_ 66VVZRAüõèÑ“'OV²³téRŸÌäädlÜ¸QÙN‰%l{OÄbS,<	‚™·— =;77			ºÍ2	»víB§NL‹e­Zµ°fÍíç6­ZµÒbÇ—Ò tü.âÿIx˜ª^÷™3gpò$IuQËÙ±c‡–öeÍ›7·m›úØ±cZÊùåÃQP
&ŒÉ3ŒÓK—.]d ‰„¨mØ°uêÔÑ>·èèh-w$£ƒ´´4™©Bpp07n,·›5k¦<'_YŒèŠµ+Ø´š#“
æÑ£G)Ì2Œ6.\ˆîİ»›“®]»bÅŠRØ¨Ğ•üí9™»víR.ÙV¿~ı?:¸oH_L]i228Í.\-˜f‚&Æ*fÍš…;ï¼Ótµñà]´hy‘sÌÿ¡k;6ñpy>¬|¦j7º
1ˆHaiNÔ6ø>LÆ_‰Å°aÃ”º³O˜0AæWRS¹re-İê÷ïßOÙœììlå’m²ÓLâá®šrã%İ\;öj5çó íÉ+„jÏ0¦¸±cÇ*8ˆë…wj:ú	
Áqsº—x¨Ö­U«–Œâ¼gnnŞ–Ÿ‚Y¬X1¹ëb'Dš“@v1¸:”i«îQ~ıõWÒÎ0N ++sæÌA›6m°jÕ*¯¯Ä€dŸÀI“&‘Ì± êÖ­«ÅJŞ¡İèèCÙ«W¯?ı›ğ8óKéñáùš³›Í›7kiW&Ş[•|aUÒÒÒ¨.›óşpµ`nÒ=Jrr²-íwæzÄ½Ø§OYwuÛ¶m^_!„¾ıö[Y–ÎjtEàºU0…©>K*W®|ÍvlAAAÒóT!''G¹Å
Ä{Ø½{w-ó1‹ğ’¯\¹Ba:_Á$ÙüeÁdìæÔ©S²õ•ÙCéÒ¥ñóÏ?KÁµ©%0Ş7¢;Øçz*T¨ l_<°‰r ÉsâÄ	e;ÑÑÑÕ2'³èjI–ìóæ÷:aÁdì$>>^$Ø¾}»©ë…P­\¹òO5a­Fˆ¶x©âÏ‚YX
‰3â””\¸@Ò^˜q?èyïŸ*„Zó‡3yµ`ªe ¡ê3L¡ìÜ¹SŠ¥ÙDw!PkÖ¬Ñ’Ü®9ƒ©©©®«L“””¤œ_*Uªø}&\¸ Ñ5_Ì|=LqGjo_Î&c«W¯–õ,U¶›^|ñEÔ®][ë¼TĞUAÅm¿ıö›²TÔ=&&FK±ğÄÄDeV¢«P¹®#ˆœ³d Ôx½Z0s ìÓ=Z\\ÕA,ÃäË¾}ûd·•dònİºaäÈ‘Zç¥Jİºuÿ”a·0Ğ!ğE	f±bÅ
lÂíD2ÈĞ%ğv{˜)))T•å„Ç÷Çjíú
¹Ú%:;;›½LÆRÆ¯´H»ã;dŸ°°0­óREWíÓøøx\ºtIËœ¨ÉÊÊÒÒ Û“-W¼?z˜AAAÚ¶´Í¢«p|>\£‰×&‰²™¸`o™:u*,X`úzáUÎ›7ïZ£NCG%7U¦9sæŒríXxèé8#v“‡)FÇ|4h`kş%h5æM¼^0WRŒ(VëC…øà÷İwòÌò¯ı«)½{÷–‰ñÓ¦Mstıúõëkéd¿bÅ
¹ûãtt”:'ïYLLŒ²áÂån*V±~ızåR‰òøÃn/^LeúM¼şÉ°	@†îşùgW|8÷‘»ï¾·ß~»¬Àã-¡¡¡øê«¯°dÉôìÙ“d:b®ã•àŠ£…Z´háq%±pREG! +Ğ1ÏzõêÙ—••Eõ§__ïzÁª¦=.:%%EË9Ã\ÍÅ‹¥È™İ‚ŒŒ”éàÁƒµÏ’†j)úî†àg‚ŞlµÖ¨QC¹©ôŞ½{eç'#ŞWÛ±v[‡äGXzêê€ä#˜’SëM›´WŞcüñïÚµ+Ö®]kêz!8K—.uÄv’·+wØ€K*Ó¨æ	zû^é¬ÊÌÌÄ={”lP£#òX¼W:Î}UÙ¸q#•é?%,ç'˜$YÍ±±±f?$..N$øí·ßLÛ5j:tè u^V¢ceŸ””äè&ï			ÊÃÕÍ¢=ÅšJëØ]¨]»6y/XO Ô“ÄÃ$\0~„xˆ
¡SiãÓ°aC™zâf7n¬¥v§“·eUDy˜IÑÑTZ&Qšƒ2ÉÉÉ2µH'lÇ
6lØ@eúOZ˜Ÿ`&PŒ,n ”í-7?ã•W^Q:{iÛ¶­¬ä„•±
!!!R4Uq²'¤:·ë›E{Š¦ÒâY§C”(Ğ‘³è”íØË—/Sn{$˜$Å³³³±u«ö–›Œñİwßá?ÿùéë{ôèåË—£\¹rZçe:VøÇÇ¹sç´ÌG':¶‹ókí)¾¼-«cW¡F(S¦Œ–ù¨°iÓ&Ê“¬*¡ëÌø8Ÿ~ú)h:‰}È!2WKµQ°“Ş“„q'nË
±QHR=[Ş¿şú«ÒõˆÏÏŞ½{•íøÁv,òÓÂü“Ì¿ıâ‹/»¯Ï8“Ÿş7ß|3|ğASbyÓM7áÇÄ¬Y³l¯F¢›°°0YóV••+W*'°ëDü?ÿòË/J6ÄÂH%¨Kˆe—.]”æpæÌ-ç°:YµjÒÒÒ”l¯İ	sBK¾üòKÊ!ş”¨œŸ`p‘bt±’uâª‹qâ¡ùĞCÉDr3IÉAAAøàƒdÚIß¾}µt¢p"âı	V²qúôiGmŠç„jşeçÎe­
½zõR®ú´téR¥ëu"<öåË—+ÛéÚµ«ò{«ƒÍ›7S_ğ§Cè‚î†-T³X½z5•iÆGHMMÅm·İ†3f˜º^ˆ¥Xy>öØcÚçæ4ÂÃÃeT§*NÚ–¥ní)BêÔ©£dÃI…î=*‹}¨¢«Íœ*Â[&$ß´‚“,„“)Œ.È•½JmÈaÃ†aĞ AZçådtœ'	ÁtBùÊœœå¾†eË–EåÊ•µÌGUxTè^Ç¢¨R¥J¶·òÊcÍš5”æó­´S`z_”ÓCV¬Xá¨óÆ9\¾|Yn÷˜©	›‡xX¾òÊ+ZçåtÄŠ_uëğÊ•+Z
«rğàA™'¨‚9][ğb1¢jË)Ûİ:æá”`Ÿ¬¬,jÁÌ×xAŸ²µbN³HJJâª?L¾Lš4IéC]½zuÙ¡J•*Zçåt"##esiUœğ`×1[†¥J•Rn,½gÏÛkË?'NœP¶ãÁ¢Ò ¾2½İ’K<²èœ%K–P™f\Ê–-[ğÖ[o™¾¾Q£F2ÀGÇyÑµ-k7ªÛ—QQQ2ÿR'ªÛ²™™™ZR9TĞ‘¦-·d q0Õf ©ù}£°}²ÃFÂŞeŒY±b…,*ššï=Z$íÛ·—gãşæY^ğªT·Ïœ9#·Åí"!!A¹ƒ†7İıLux¬v{ï:CNñ.a¤›R`4‘-‚¹}ûv[?˜Œsøæ›oĞ¯_?Ó‘„âZ!¸eË–Õ>77Q¢D	å¶TĞĞD§DÇ^OLL*T¨ dCG9:³¤§§kijíÁ¿Ï–-d‰(Lû
L!áê›Şù››+shÿeíÚµRìîºë.S‰ÔÂ«œ7o,—§Z(ÛWĞq©£a³Ä= A_µjUYXŸ‚^½z)]/»b7–/_nºBV7FµjÕ´ÍI¡„£GX5£0Á¼À\"œpà"KcÆŒ‘í¹-Zdê\å¥—^’İo„Ø‘ÌÓ¸Y0…Ç š#xóÍ7“İ7Üpƒ×mÂ®Ç"Â«U­š$èÓ§–ùè€¸ŞLáÄôÍ¢6ûÉ¢sœÂÎXKFFî½÷^¼ùæ›¦mÜvÛmxùå—µÎËWĞ‘g×–¬êv¬Jİ[
"  @½¨˜˜hùû+³ª]¢ÄB¡fÍšÚæ¤Êşıû)Íºª)J07%‚´£ÒÏqB,€9sæ˜¶†‰'j—/£lãìÙ³–§@ˆñöíÛ§d£Aƒ²ê%:$Vÿèö¿·“JKê8-€ËEí)J0³‹R\³şÒŒùè£”Ò‰¢¢¢°páB™>ÂäODD„r¤pvv¶²xyËîİ»•Ï¤¬èÍèFÁÔ1S*ûäAèa®2r0Ä“øk’mÙ„„>|˜Â4ã0=ª´Z¡BÒ³gO­óòEÜ˜©££‡™FÑŞ¢C8âââd”§$''+§é@ÓÎ….âããqòäI*óE:‡
¦ZÆkÌŸ?ŸÂ,ã öìÙƒ;šnR\³fMYË)!íN§uëÖÊ6„`ª&¹{ŠÚ±¥K—FÉ’%µÍ© TSK`½é1OĞu^ê$sîÜ¹”æ‹t=ÌDªª?*çYŒóÙ¼y³l³tìØ1S×7iÒDŠ¥èO!::ZÙ#HJJÂ‘#G´Í©0„Ç¥Z;ÖªºxoU›JÃÂÀ*_LBÍØ È½^OKb”æTşñM–/_.«÷œ={ÖÔõBh×®]«­ë„?á¦mYÛ±:<?O

Bıúõ•íX%˜:<ÙˆˆÇ9tè,zCÄBO~ÈSÁüÈÈËÔ¿u–ğu6mÚ„ÊDo3Õœš7oY³fÉ¦ÑVl³ù":š'¯[·Ît©BOIOO—ù´ª¨ö¬ô†Ş½{+GŒZ•R§cñûê.5h–ç{Êt€÷=ùAOß‰# ~T›Sşˆ‡£İ…‰=¼şúë²ÏüùóM•×Šä}÷İ‡’9ú%J”çÆ*\ºtI.~(9vì˜r ,ÌZµj)ÄÅÅ‘Ÿgee)o«+VL¶ÛsB#·c¿ëO~Ğ›¥ÃwæçS8óæÍ£2ÍX€ÇÇãÆ3mC¬Ú§L™â¨|/7££`8õ¶¬­É²eËÊ‚•¨¦°dddÈhOJ„À¨–ÃkÖ¬™c®Äñ.k›·‚I²-KùÄ#şÿ>üğCÓ×áã?ÆM7İ¤u^şLõêÕQ®\9%û÷ï—¥©Ğ!˜Vä_æ7¦êÂz1¢Ã¾Î¾¢ªjD*€<ıaoó2€ŸÌÍ©pÄîîİ»)L3Ä$''ãùçŸ7}}XX˜ü0<üğÃZçÅ¨‹Ivv6éçR‡`ÚñP/S¦ŒrÁN‘››«,˜¡¡¡)òûï¿SŞ‡‹ŒşÏáíi.™_Ì)&îC<ğºtéb:¸ T©R2¸çÎ;ïÔ>7ÆùÑ²ª‚IÑ,ÚST…:11‘,óèÑ£Ê…ì›4i¢%…FÄÚà•ëê­`
×Uı”>fÌ˜!W´Œ;8|ø°ŒÆÜ¶m›©ë+V¬(»(¨§0S³fM™Ô¯‚LŠÏeFF†éby4kÖÌ¶N'7•ö¥fÑâŞûüóÏ©Ì§¦Çx{·¥Påd;vÌ–ö7Œ÷ìÚµK¶ç2[ÓQxkÖ¬qÔ‰/ ¼-{åÊ’4ˆİ»w+±÷OLLŒr÷*ÁTµBÚùÅ-Zdºğ‰|ï­hfyFvúúñÇS™f4+·a?nêúV­ZÉ~vV¦ø3Nõ„Tm†……i)" ‚êbDG•£ë9ş<NœPëûß°aCåŞŸºøä“O(Í{½×kF0¿@RıöÛo¿UêhÁĞ!pC‡•¥™­´²eËÊÑºuë”WæŒçÔ«WO9opãÆ¦ŠP„¸ÌnåçÑ£GÛSÄÂQ·YrrrdE,,]ºT)Ç3  @+pÂ»\¸Ğ£<f8áiuŸ«1#˜™ V›¸®HÄôä“OZVø™ñáU¶lÙR™0Û†é£>Â#<â˜•«?qË-·(]ŸššŠõë×k›ÏªU«”znIÁ´›2eÊ ]»vJ6~ùåmıGÓÓÓå‚T…F9¢Y´Ğ€Ñ£G›*€â!« x¨jöÄ|§ÉëŠäĞ¡CòÅ8qã;VéÆ×s$¬}/SµTÎhYÕíØúõë“7‹öEtõwÜ¹s§r±§ûÏ›¸„ ©<³‚Iš4Ég™Î ;;=ö˜éL@@ şõ¯aÒ¤IÚçÆxğÈTûEÆÇÇËryªèH§pR°˜ïˆˆ%ºr2U52òØ	X ¦œ>³‚I—ukôÉ4Ûå‚ÑCzz:lúÆÆôéÓñ÷¿ÿ]ûÜïQõrss¥£Šª8ˆE˜Í¢=E,FT#JuôÍÉÉQNî¯[·®Ìmµ›sçÎá»ïÈ*±æaj›Ã¬`ò´X­ÄÃú‹/¾ 2ÏArr2ú÷ïoºÆ¯Xqÿı÷xğÁµÏ1GÃ†•·1ulËªÚ¨U«–ãºØ¨z¼ÂsW-”~èĞ!åˆ[§lÇ~úé§R‰pØÌ…*Y¿Ÿ*\[$ï¿ÿ>ÿØÀ©S§d$ì²eËL]_ºtiüüóÏèÓ§ö¹1æ“&M”lìÙ³G)@åòåËÊEÇí¨[5RØUõ¼U":rvu ù*u©=ä1”™Us ²Ò<ûöíÓvÎx†x˜	±üõ×_M]ƒ•+Wru‡¢êA±ŸK³üşûïÊ‹`§œ±]MXX4h dC5JõúÚµk;Âsß»w/8@9D€™f/VÌTUòĞÊÎÎÎ;¥Xš½YÅnÍš5| 1ÿExBAAAJ6T<Õ‡z¥J•›Ã«ê<yÒt0”@*§lÇZğÌÿ@‚Ù‹U1>@=t® ¸ ;=gÏÅˆ#Ğ¦MÓBî½÷^¹¥$D“q.¡¡¡Ê9v›7oFZZš××‰{K5(E5Ÿ”ñù)[¶¬’³Ç ª%EK—.n¸AÉ†.ˆ[=
­2ß´Wƒ`îğ¢ùùçŸ©sqüÇ{LFÂš=d¿ã;ğÙgŸ)çù1ÖP¯^=¥ëÅ}b&@eÅŠJµcË”)ƒÖ­[›¾±éŞ½»’á]y¸#~>66ViÜnİº9"¯5..ºø› ”Îùt”úŸ€¤Cnn.Şy‡Lı©S§bÁ‚¦¯9r¤Œ¤Ö:/†Š+*Ûğ¶-—øïÚµKiÌ-Z(7m¦Fu[6''Çë÷iÇÊÕpœì#˜2e
e gw£„ÁŒ · âU|òÉ'Êm€˜k7å3Ï<ƒ¿şõ¯¦mŒ;Ó¦M³­½c;SxªEœT¬  „\¢D	%ŞóªFÇŠù–/_^É†ÎŸ?™3MÇâxÂO Ôrw4	¦€¬,CJJ
WşÑHvv6}ôQYÇb•ÿÆopõ—R¡BåoLTƒ}ìlí-ª’İ»w{\¯Yx–{÷îU/&&Féz]¼ûî»òYOˆ–¶'ºó;±ğÔdëO¼óÎ;Ú
û3ééé4h¬Àc†ĞĞP|ùå—øÛßş¦}nŒ5„„„(Ÿczëaª
¦¢½EU0ÅgÔÓÔ³gÏš
Àº;ªˆßaÚ´i”C$Ñ±Êèº…š‘ıÆ			²Sc‹/¢gÏ¦Ï,###e¹ªÁƒkŸc-ª)çÎ“¥=!11Ñk½7lÇæ¡C€<İfU}_ásæÌ™Z~—BxÏè²¥ŒÎeÛ»Şv¯ö†şóŸìešD<´ºvíŠµk×šº><<\F¯99¬Ÿñ!@*[nn®Ç)"ªglAAA¶7Šö†
*(ÛğÔ#×!2v{˜â™N|¼“
à}]Æt
æy #Í–*Š#G`øğá¦û1ú#—/_Æøñãeqh³¥·Ê•+'s£:tè }~Œ=DFFÊ"*,[¶¬ÈèÌôôtåV}µjÕ²½Q´7Ô¨QC©©´ ))	Ç/òçâââ”Æ÷AõêÕ•l¨••%›Ò>lª¬«'ˆt mQ£º>7Î3Iøê«¯ğÁP™÷9şş÷¿câÄ‰2ÍmÛ¶•õCû÷ï¯}nŒ½ôéÓGÉËØƒú3[·n5}ïåá¶báááÊM¥á¡ª
fÇ•Å]…©S§R*X @kŠ“ô)6ÿ`Â„	²<S8ß}÷şóŸÿ˜¾¾G²‰«ğ0ß£D‰ÊUŠÚ:Tö¶Í #¯111±Ğï‹…ˆjªåğRRR0yòdêaŞĞmB0×ØH`W"n¤÷ß×¶%í“|úé§8p éîëC†ÁâÅ‹Q¼xqíscœƒê³0AÌÎÎVNy€¦3A«ÑÑTº¨ÔÕÅHÙ²eQµjU%*¼ıöÛÊõo‹@èĞİF©bµµ+ûÕLš4IÏ1æõ×_—}(ÍŠå_şò|şùç®:7bÌÑªU+¥ê9gÏ•EÃúj˜›SGSé¢zTƒ©ÄbÉ®ÊIÂ3ş÷¿ÿM=ÉN'•`.0‚€HÆwß}—Ê¼+ÉÍÍ•g–ãÆ™¯-<vìXù¾º%çQ£T©RÊAy::"8kÖ¬‰bÅŠ)Û±ÕmÙóçÏ˜ÈŸ®ÜËÎT7ß|Sùl»ÎøÂ0Õ“1€ZEà"˜<y²Ì-dşmöğÃËZŒf+â>ø€«÷ø!ªÛ²y::ÓMù—×#<L•]šÂêïîÜ¹ÓôŒ…’êùµYÄ3{êÔ©ÔÃl ªoNéJ66o¼n½ãIMMÅm·İ†3ÌÕbùå—_Ê®%ŒÿÑªU+¥ëãããó>Ñ!˜nî­ª£©tA©`ªÛ±v²Ÿ8q".\¸@=Œö³Ë<(s¡m‰ğ¨üÙË7^¯^½d€Y†&Ëå1şIÙ²eQ¥JÓ×OHx<×£*˜Nní)ªÛ²ùÕ•ÍÉÉQî+jWt¬x^Yà]
VS¦ÌµTûÈyXPƒĞ±‘lØ°!Ö­[gêú’%KÊ%o¾ù¦ö¹1î¢oß¾J×_ßë2%%ÇS²Ù»wo¥ë€jSéôôt¬Ys­ßa¦gæÕÔ­[uêÔ1}½
ï¾û®é¾»^ğ­[=Lñ	BY”Fav•Æ´ndË–-2mÄì*¾Q£FÒ+xıõ×•Û1î§E‹J5E®ñzÄC]%B¶L™2RlÜNhh¨lÎ¬ÂÒ¥K¯é¹lÙ2%{·Ür‹-Û±âıŞ{ïQsÀ}†ö@™€4;511Qæúb5ß£GÓÅÚ·oÕ«W+mÃ1¾‡ÎàÕA74‹öÕß%))	G•Ï:•ÜÅˆˆéaÚÁ‡~H]`]0Á¨K†ùÓ œ `üøñòÆòu¾ùæôë×Ït…q­\•m"Æ7Ñ!˜ÂJII‘@*¸9:öz„·¬º8Í[€¨.Dš7o®ÜÕ.\ÀK/½D=L s}½À
ÁL@š¯ V]&L Âv¦M›&·aÍö¿»ÿşû¥àªV a|“Ê•++	Ö#GÈ‡zQEÙ#22Ò5Í¢=E5ø'O(u+°ƒW^yEæÎSÀ³s
X•¡ş ²’ô‚·Şzû÷ï§Â6^ıuYÇìƒhôèÑ²çWïa
CÕ³t^¯ÎP}_Oœ8!;z¨xîÅŠ³¥MÚŞ½{­Ì<À’s9«îÌ IÈÈQŸ¾Dnn.ÆŒ£T½ç¥—^’¡Ü¾öbô£ú`ß¾}»ìn£‚ÂåN£R¥J(_¾¼’9sæ(yîM›6µeÁ,_´d|ÙĞr¬|ŠÎ  Ö¦¾ûî;|ÿ=i&‹eˆÀ½÷Ş«”öqÛm·áå—_Ö:/Æw©^½ºÒ–}bb¢Rt¬d§¢º8räˆÒõvlÇ.\¸P)GÜC ˜E=HV
¦Xf¼J=ÈÈ‘#] $:«J³ˆ‡ÏÄ‰¤N=ãƒØYì\µœœ“±3)44T¦’YÉ¥K—ğøã[1”ğÌ×	ô«÷éfxr€„„™ôœŠí6.^¼(Ûk-Y²ÄÔõ‘‘‘5j”Ì‹³úCÂ¸»ÒpóÍ7Û2¶ÔªUõêÕ³eì={JÑ´
áwïŞ]½#<‚¯¨¹«3À8 ßP+KÆ™(µ‹={öÈú™óçÏ7u}Íš5å9ÒÛo¿ís‘†Œ5Ø%˜6TîœâtÄ3Éj„Ç.Ó*ÒÓÓÑ§Olİº•z¨9 ÆšbvE‚üÚŞ·oŸ«ºolŞ¼;w6]R¬I“&²Œ–]<Æ7¨X±¢-ãúb°ÏõÔ¯_ááá–)"V¶H{õÕW•¿< Óp¼,Ç.ÁŒ°‘z‰'Ø"ÇI,_¾\Vï1›«$„víÚµ2—aT(S¦Š/né˜®îLâ):K{‹•Á>;vìm-`=ušbAØ™k°ˆz€ŒŒÙ'R%›šE‹Éâ×—/_6uı€ğÓO?Ébê£Š/«½½š5kúÍıkeğø¿lÚ´©%cåææÊ¤ÈCoÂNÁ´ä—•ÛN$11÷İwŸéPü‡zóæÍsmWzÆ™X‚àK¥ğŠBx˜VåD—+WÎ²Ê^7nÄ†dMB®‡ÜÙ*;ó7 ä'Ã³A4Ô¼ıöÛ¦ûyŞtÓMøä“Ol©Éø6õêÕ“ÑÖVáÛ±y„……I!³•4Şbá3v# µ
Ø)˜¹ FYå4{öldı?{w]eu.|üŸ„!"3EU¾‘À‡
ˆf%JˆBıíÇE•¶kuµ··½ŠµÅ¶zÁUl°×ÊK”xÁ$H	ƒŠÌƒˆaHÊùœ»Şİ+å™Î»÷{Îy~kíubj³3¼ÏÙÓ³kŒÕi°¦êˆˆPk¡r£ƒğ–¨¨(cSy¡pQtc™ÚXeªçÙÚœ3ãàäŠï™èèjl×KsÆğËÜîäØ±c¼øâ‹nwÓhM9§äŒ(.\HRR’+1	ÁiÙpš­j	söìÙ™èj	°ÕDGWc;a:61'íüPøÃš¸ñ»Á³c.::Z-ªïÙ³‡ŒŒWãÂùİtû\¤óæoøğá®öáEñññFúéÙ³§«_¿¢¢BÕŠıÅ/~áj?ÚJà9]‹fâöz¦Ïçãå—_VIÇ+æÌ™Ó iÕo¼‘­[·’™™i­Zˆ/‘‘‘ªb–›ºwï6»c/å$2·—Sœ>Ü^+2eŠªuí÷»¾ªæŒ*ÇM;J@^H˜è"ÿ_HuÕ¢E‹ÈÎ6ZMéªî¾ûn5ê½–„„uÆÒÔš’u]-©f³n­M111®Ÿ™v{J=++‹¥K—ºÚ‡V£g!kMtV¯$LÇNàMŸ>½ÙÕÿå¥—^RWp]i·ëØ±cÙ´i“:§&„iN²tsÑä.N¯0`€k_Ûy–ôïßßµ¯ìØ1uÇ®!¿v˜ê¬>^J˜™À~·;)--%==ÚZûoZ"""Ô\P¯ãÆSÅ××¯_¯vÑ6÷=!šcÔ¨Q®}íîİ»»öµ½îî»ïví<¦“,İšêöù|êÙyöìYW¾şe¿4ÑQCEÙà2NÛd8¹ÄÍ
Uaâ#F¸ÙMƒuèĞA=œ&OÌ„	dT)<¡}ûöêÖü@? ¿½ÔÔÔ½Î«>ÑÑÑj—üÉ“'úu7à®%LçMıâÅ‹]ùÚ—ñéuKWïPn,¯0Ş0ÑÑÌ™3›|–á"---à›T’““"÷šG}4à…G†êÚÈ=77×äñ¼ÀFS5”&ú6×/Sóù|ª4]AAÛ]	´¾ıío3lØ°€}½¸¸8+W]yMçÎÕUXÒ¾}{U[ÚGU³_†–±Nè«»<Ç«	³ÌTE‡3gÎ0~üxSEƒ…J©©©9—yıõ×«›øM^hìecÇÈxçûé|_İ(iXSS£‘§OŸø×¾Šé@Ój†ºÌkk˜—Úôİî¨naôèÑnw%DPŠŠŠbàÀª˜·3Úhl©ÉN:©‹ŒÓÓÓÃòìåÕDDD¨M:]ºtQ›ËÊÊõÿ‰‰QÓ°O<ñ„:¯í†™3gš*}çÈ^0ÕYcy½iO½SÊõ8###Ù°aƒúåB\]QQ‘*üÿõ×_×ûïvíÚUM;4Hj7€ófdåÊ•º„¹W¯^L›6ÍÕÑz~~¾š74ënÓÏ|O
†ßàL}pÕu7ÜpŸ|òIXŸ¢!ü~?‡bçÎ9r„ââb.^¼¨>ïŒzTÙ»ÄÄDI”MğùçŸ³qãFµ“öüùó*a9‰Ñ÷èÑCUürŞ„¸y[‘ó30`@“j^7Ñïô…¿É×é²y·™èlôèÑ¬]»V®Í¢	|>Ÿ±ûÃ‰éïkMMšBÏËË3Õå^` PnªÃ¦ğòfj}«ÉwMÄë¼[.++èî5!Â…Œ&İaúû:cÆrrrLuW	8\#W4G0$Lô6c'q1ÑÙ–-[èØ±£ªÆ!„áä•W^1uI+LvØTÁôv0Èî1ÒYd¤ºEü‘G1ÑBX÷şûï«gÁ²¡Î3}¬®ìãyÁ”07ŸLt£jº<ØDwBaÍöíÛUyÎ.˜êòp;pÜT‡Íl«ó_O™ê¬¼¼\C?|ø°©.…Â¸‚‚zè!“É]  h’%A˜0ï•””¨æ‚ÔN5!„Î3-33S=ãŠ‹‹Mu[¬«ÛU(Á6%{©[õMÜÆÊ†äää¨aB
–/_®ÊŞT
Ü|a²Ó@	ÆfƒÀ“&;œ?¾Éî„ÂUsçÎ5ÙHÖdI+¹šıÀ½@ó«B7À‘#GhÛ¶-III&ºB×¼úê«j©É <à§&;´`O˜èó™ÆæÖ­[G·nİT!j!„Fo¾ù&Ó§O7İíL}Ê!hóf`7ğLuÉ’%Kxì±ÇLu)„‘••¥n71¼‰ñ(ĞÛë¥ïê
	}–çc]wÖˆ¨¨(²³³ÕmôBV¬X¡Y½­™*€¡À§&;uC(LÉ¢·)šœšõûı¼÷Ş{ªšBB‚©n…¢Irss™0a‚Ëò§«Mwê†`Ş%{¹,à“|«ªªHIIáé§Ÿ6yB4XQQ‘Z¯|ğÁ©¬¬4Ùµ3ˆyXh²S7…Ê”ì¥ºéÛMn1ÙiÇU½Ûo¿İd·BqU;vìà{îáìÙ³¦»şÔËx	Å„‰^\Şt0ÙiûöíÙµkqqq&»Bˆÿåøñãôë×Ó§O›îú0İ±ÛBiJöRû€Gõ=kÆ”––2kÖ,“]
!ÄÍ=ÛF²¬Ö¥KC.YÂ#Ì:“ÿ4ùßÙ²eKV­ZÅı÷ßoªK!„økÖ¬áá‡6½Ö<,1Ù©I¡²Köjvëd9ÊT‡>ŸeË–Ñ§Oz÷îmª[!„Pœ7ì©©©jS¢aÿüÎt§&…úıßø™>«iLTTo¼ñ†: ,„&dgg“‘‘azd‰~Æö7İ©i¡>Â¬S¡œSwN³S§N4Èd×Bˆ0ôúë¯3eÊjkkmtÿ34CZ¸$Ì}@
ğ-Ó¯Y³†ØØX†bºk!D˜˜?>Ï>û¬z£nÁ^àyÀø°Ö´pI˜Î[®l p'ĞÂdçk×®%//víÚÑ«W/""Âa&\á&ŸÏ§î³|æ™gøıïo#„r`ŞèsÁF ¦…ã“{0´µÑyff¦ª$„Íá<K¦M›f«û‹ÀıÀG¶°!¦ãàO@´é»téÂÖ­[¹å£…ˆ„!¤  @í8uê”î‘åƒÀ_ltnS¨.¨Ïz½	ÈhaGII‰ZÏÜ¶m›é®…!ÀyÃí<C,%Ëj -“%aœ0 ÙX¨>yò$£FR»h…¢¡–/_ÎèÑ£)..¶Ñ}-®gçÂR¸lú¹š}úbÓÓÓÓÕÕÕ¼ıöÛjW›“<…âZæÍ›§X(H€®âóT(WñiˆpO˜Ïu±àlt——§nHNN&22œüBˆ+©©©áùçŸç…^°ulÄñ,ğº­Î½"\7ı\Éj`¬­ÎGŒ¡Fœİºu³‚ÂcJJJ˜<y2~ø¡Í0ÖÉ6ğ
I˜ß­7YsÓM7‘““#E„lß¾	&PXXh;çÙøWÛAxLÉ~ãˆ~'Õˆ·À¹sçX¸p¡ºİqFEÉGˆpSSSÃÏşsU‡º´´Ôf(kgl$¼DF˜Wæü’Ì·¹‹ø;îàİwß¥G¶BBæŒ&SSSm;óß^µ„É.“+Ë2lÖFÜ±cwİu|ğ­„­^½š;ï¼Óv²¬¦H²¼2™ó»º]úÖğGl}ŸÊËËÕu=6LvÑ
‚jkk™={¶ª	{ñâE›¡TéK÷—ÚÂËdJ¶~ ï 16ƒ<x0YYYÄÇ[Y^B¸àèÑ£¤§§³qãFÛ¡T“ ©¦r2d©ßŸï çl‘ŸŸOÿşıUÒB¿œœ5ëdyxH’eıd„Ùpwy¶Gš´´4-ZDLŒõP„TYYÉÔ©SY²ÄEs*ôe›md³áë‡$÷îİKEE÷İwŸíP„ô£ıˆØ£Î\à¶ƒ’0g+0èb;üü|µ)häÈ‘r^Sˆ PSS£6÷¼ôÒK¶C©³xÒÆ­MÁJ¦d/Zï${`;˜îİ»3iÒ$RRRHJJ’´BxˆßïçÓO?å­·ŞR­¨¨ÈvHÀ< [’eãHÂlïÿî•ïcÿşıùÃş ^…víÚµK­UnÙ²Åv(uüÀl`–í@‚•Ìå5Ï}EØÃ@ÛÁœ8q‚7ß|“.0|øpZ´°’a§ººšßşö·ªhºêÀÖ©¾+	šÇ#£0Xt¶H={²víZ)­'„AN‚;v,ûöí³Ê¥Îã¥€zóIÂœúÌf‚í@ê0€õë×sıõ×ÛEˆWVV¦’e~~¾íP.U ‹¯ì·H("ó08f;:Ÿ|ò	}úôaåÊ•¶C"¤-_¾œÄÄD¯%ËB`°$ËÀ‘„XÅÀ?ÙâREEEjmrr2{öì±!åàÁƒLœ8‘ñãÇsüøqÛá\nğµí B‰lú	¼Ãz´9hi;˜:_~ù¥ÚA{êÔ)uü$::ÚvHB­ÒÒRfÍš¥î¬Ü¹s§íp.W<¼e;P#	Ó»ôzæ}@ÛÁÔñù|j‹»“8[·n­®“s›B4œó7´dÉÆ§6ÕÕÖÖÚér…ºöõŸlŠdÓ»b€	ÀÀ½^û~wîÜ™ç{3fĞ¡ƒgòºSVVÆk¯½Æ¼yó(..¶Î•|, ş(·L¨òÔ<Ä¥ ‹ÏmYæ?øªqÙ¾}{ÛáágÎœá×¿ş5sçÎUEÓ=¨HŞ·H8„iV‚~'ØÕv WËôéÓùÉO~B»víl‡#„5çÏŸgşüùÌ™3G­WzÔ)½3_vÁ"k˜f mr%UUUlÚ´I­q:î¸ãZµje;,!ŒqåË/¿¬v¾®ZµJİ
äaÿO¿"¤=ªßú½Ü:wîìŸ3g¿ªªÊ/D(«©©ñ/X°Àß­[7ëwh%z‰G&S²ö|xSïhó´””uÓ‚E¡¨ªªŠ'Ÿ|’ììlÛ¡4Ä‡záW¶	G2%kÏ}½ó:ÒË?‹••E›6mèÛ·¯u!¡²²’7Şxƒ´´4µáq•ÀéÀßl®d„é}¥ÀÿµH}ºvíÊ´iÓxşùçéÔ©“íp„h´²²2.\Èo~ó¾ú*(jû€ÇÏl"„WDëK]}X#©·EGGûÓÓÓıû÷ï·½ü$Dƒ>|Ø?cÆ›6m¬ÿı4¢-ÚØ~8‰¿“¦÷Ä¿ÒlÒÜ{ï½êî¿¤¤$zõê¥>'„m~¿Ÿıû÷óñÇóî»ï²fÍU©'Hä ?ÚD|ClŞ5øpƒí@ãÖ[oå™g!##C¦l…%%%,^¼˜ÌÌL¾øâÛá4ÖWÀ³À{¶"Ø´ÓÓ´µ˜jTkÕª•?--ÍŸ››ë÷ù|¶gãDˆ«­­õoÜ¸ÑÿÔSOùcbb¬ÿş7¡ùôôkGÛ!‚İ0½ğoûºI-..ÎÿÎ;ïØ~¦Šµzõj||¼õßóf´CÀ=¶2B„’h`–Ş^nû¼Ñ-""Â?fÌÿ²eËüÕÕÕ¶Ÿ±"È9#ÊÜÜ\5‹iı÷»‰­
˜£ÿ¶E5Ìàs;ğÀ@Û4U\\œ:(>iÒ$u®Sˆ†Úµk—*¢±hÑ¢`9r5ùÀT`·í@DÃIÂNQÀ
à!Û4Wbb¢Jœ'Nä¶Ûn³ğ }ûöñöÛo³lÙ2õqxOoêš-»B»X½I (Îm6¤¥¦¦Ê¹Nñ?


üS§Nµş{Àæü­.Ó›ùD’fğ»˜$Ù$PœQgZZ?ş8			¶Ã²|ùrrrrÔùI¿ßo;¤@Ù|øØv ¢é$a†ççØOr „DÁ×o¼Q%Í[o½Uµ!C†0pà@Z·nm;4Ñlß¾Í›7sèĞ!U¯Øy=qâ„íĞ¥Z'ÇÕÀŸ]¶Í'	34Å¿Ô7±‡œ¨¨(uWç˜1cT1b„ÜÛéqµµµìØ±ƒuëÖ©¶aÃuKHˆz˜ØD–$ÌĞö+àŸmá¶víÚ©¤9räH†®F ‘‘‘¶Ã
k>Ÿ­[·²qãF•óòò8wîœí°LpŞ¨şÔvÂ’0C[„¾å`&ĞÓv0¦ôîİ›Ç{Œ¡C‡ªäk;¤°à$ÄmÛ¶©«²–.]ªê¸†‘ƒÀl}ëPÈ,¼Š$	3<´ 2€n±ŒIQQQôéÓ‡Áƒ«6hĞ u|Åù¼hºššµîèŒ"7oŞL~~>{÷îUS¯a¦@'Ê,çÛb;á.I˜á¥0ø½Î–bbbHNNæàÎ;ïT	µM¹AéZ.\¸Àîİ»ùì³ÏX½z5¹¹¹”——ÛË¦cÀ‹Àõ$a†§hài½¾ÙÍv0¶EDDpË-·¨ã,Nò¬{íÛ·/ÑÑáUµ¬¢¢BUÓÙ³g*à¼:#Ç#G„Òæ8¡÷¼®ËTŠ0"	3¼]§×\RlâE×]wıúõ#>>={ª×›o¾Y•ösZ°îÌ­ªª¢¨¨Hµ£Gª+°>¬^dyñâEÛ!zÕr½' ¬‡ÖáL¦ˆ†ÃuñƒÁrÅPÃtîÜYµØØX5¥ë$XçcçÕùggtÚ¶m[ÕœÛºukZ´hAË–-U‹ŠŠRŸ»tW¯óyGuõ73}>ŸÊÊJµFè|ŞIzÎÇÎçœ‘á¹sçÔÔiyy¹JzÎÇçÏŸW¯Î?;ÿû©S§TrØ¬Ûıv‹´Bˆ«sÜy ”˜4i6Úv½INv†	!l€®WtXK“ÖÈæVéÙ!„h²ÉÀy<Ô¤Is£Uè«¶„¸&™r±X œ¶¶" N/é7„ÙFzœ7Ycô5EÕH“Ö˜Väiú\²Bqğcà¬„Ò¤]«ı˜ô°ıG#„oñzÄYå£4i—¶=¢ìkûD?9‡)©ğ„Ş@o;Öé¢¯…¶ƒ¡A¦pC„úêôÑm„Â"Ğ¾6ŸêjŸË]”Â’0…)-€ïèÍ rç–hràC È–èÂI˜Â†ë€‡€I:‰ÆØH'IşY¯—¿HÑ[a”$La[¬.ÅçŒ:Ç­m$<¥BWàY¡_ÏÙH!¼àf½õ¯vWJ³Ûëb½mÿR
QGF˜Â«nÆÉÀH@nxmç<}d5pĞv@B\N¦­€!:yf İm$â°X|,w„×IÂÁ¦•>¢2ì’{<eİ38Ôè#›tíÖUzRˆ  	S»6zôé$Ğ»uë`;(¡œò-:An–­"˜IÂ¡¨‡¾U%NWê
Ü ÜtÑËQ–æ©N%À	à¸bu^¿Ò·¤x€)’0E¸º¥k]•HŠ)\Y¥ŞµºG'Â¿ô¥ËB„I˜Bü]„.İ×S×Áu^ïÒízÛÁRlÓÍI_è×"Û	á’0…¨_;½3÷fıZ×ôôo Òvõğéš«:ê)T§Õ¯³¤^&	Sˆæ‹ÔI³®uĞ­½^C½A—Œ¢õúi[ åe”®»ÂßÊË6ÊœÕÇ/ÎëRqºúÍE½–x(ÕÿŞY½ÆX×d
Uˆføï   ÿÿ«uºP²
Ş	    IEND®B`‚


# icon/brew.png

‰PNG

   IHDR  Ë  Q   *œÿ  ?•IDATxÚít^i]ç¯N£FÙ°™ Q‚ä,¢!H´eÛ=Û[mÖfiq²Nu*NS˜Û3“ãTZi¥ö0å4:u[œrlaÊ6ÜŒ'HÄŒÈ@\³nÜ“•¸öd%‹iûìıŞÜwÈdš4÷¹÷½?Ÿs¾aœ6yßû>Ÿ÷yßó{     Ô¹iq³ÍÍn¸yÒÍU7Ãn®¸9ãÿï{İlqÓì¦–—  òD¥›MnNûòu3íÆ„Ì’ÿçŒ¸yÚÍq7mn*xÉ  T¹Ùãæ¢›…Ä$snÎ»Ùî‹   5hIõA77üYŸIAıÙ¬–pkx‹   	İ<êf,%r¼Û²­–lº©ç­ €rÓà,ïšŒFâT!…B  9’Ëi'=Ë¬Q,ÓªÒ¶š·  ÂRåKe>'’\Ygyy–JZ  Œäñ /S€L¹ÙÍÛ  e»/SÀ¨`©G   ÖBG@F
*ÉÕÑ±ö3 àE´:ÅYrİh&å#2   ŞÁıÅ´Hªªª*MÂTaÓ €â¢"'âOEE…ijj2›7o6ûöí3½½½¦¿¿ß\¾|ÙŒšééiSbiiÉûï###æÒ¥KæÔ©SæğáÃŞ¿×ŞŞnã>›yÇ  xèHÈÕ8f‰æÂ…faaÁDÉÜÜœ9wîœéèè0•••qHó¼Ã €Â .<“å’J]]éîî6CCCfqqÑÄD<88hºººLMMM9…©(ºÿ  ä]™5µDª««½eR-›&–p%ê”kÆ©ëÁšy”  ò‰.Y´]ö!{zz¼%Ñ4¢}Oís–A˜º~l @¾Øµ(µ955e²Àøø¸WXTa2Ã È	:+YoWU£J>YdxxØ477G½$Ë& @ÆQšHŠytìãúõë&¨:·¾¾>Ê¢ªd 2Šğg¢‚öıT8“'TA»uëÖ(•  @9éDPÀ£† yE_ TÅ‘0i\  1p"h(—e×»100à}1pÂwú¡5 @FhsBV¾ªÜää¤)j¹W[[E/Yš¯ ¤œz'äí!:b1??oŠÈÌÌLÕ²*¨âz/ €”¢‚±0½ºŞä­Ç¦ğg×®]QÜ‡	  )do˜^•¡EåJaF0Ãlç‘ H•nfœ{”Qß
’‡%Ù{˜c<–  éâ'Dô¬´­K¢è'd•ìnM €t b«vvnè€õ•„å”Cw €T`İ|àìÙ³Øp„l\@³ €„©w³h3ˆë‚fØx§Ÿ­ñf’  $Êy›¼µµ•ÊW‹
ÙÍ×ğ¨ $C³åÀmFFF°Ÿåm%–¯¹fÿ\å  7lî;v`½„8ù$, @¼´9–Õ¯	‡.vì­×óè Ä‡U,E=Ñ ş¹•±  ©'p·ÊÊJ3;;‹é"`||ÜV–#<º  ñ`UØsôèQ,!ûöí³]Š­á (?G‚ÒêqZÔk·ÊÅôô´7[·æŞˆİ›¹İÿóôLhi^G‰†WäŠÿ¿ôÿ[5 …ñ ô‰'°[Ğ•fN|×w5ûÒ{Ú	yg©›7şŸõ €¼Qo38R[ÔW×±;sY¹Á÷»ÕÍÇ²÷¯lyXG‘rSÇÇ Â¢A®ÁY¾«°´ü¥ósÏ¬ZşZı³Ó+–Âš–«9t Ô¹@(_¼šš9m_ç=®ö¥5QfAŞ­éÿY ¸+µşÀ¦}ŸQÿxTÒ¤ÿçnsSµÁŸg8èßÓÛÛ‹ÕÊHWW—Í{~gí¤cÙë·Œy
iÀjtÒ0›Œq@Zò¿Í?ì¬½Tc#ks€ò188hó~Ï9ß¾º«Ú_¡XH™$W/ŸtØÛ(<Íş`¶p"ªé¢/í•ì	úgÕÕÕa³2£ë–U±mşrk¹F{§†ØF €¢oôÚ—Iroh#—ïõg!Oı÷U­	å§££ÃV<&£™]ñ\@N©ô—;³4XIš»ö¨ZÊÏ¹sç²*½°Ñ:·© äP’3¶ìeêêjî¬Œ‰¹¹¹¢ÊR™ö·1  ì-Š$KÙºu+‹‘ÆÆÆ"SÅI;f ²‹ª÷.â ¦Ş¥íííE–e)3ä dmE›M:4NOËÆêe‰ª «ªª’úû¯:?7KÔKÇÔKRçÂtqeçš§üÿí¸ÿÏUDÓîÄ_f®êé¢Ë?{ö,‹‘Ã‡Çúşª9~gg§÷>ëBjµ4ÔŞéJÔ<_çluôÔ©SæĞ¡Cf×®]¶]‡‚DæÕ™PJ›uæoÚ	wà~ÌY>Ç¸Û)ïmñµNº‚Ä’Q¹ßSí‹ª)şäädè6}ª”Ş¿¿7-ÓÏ«^³-ÜÒäï;L—ùƒ?æ‹8Ê jÉ5™”œ´ìU__ÿ¢$¸fÆÆÆ0XŒ\¾|¹,ïcEE…7ƒÔì±\ŒŒŒ˜¯‚:âŸÿC*ä‰Ò‘ŠñuÍ:ueÑÎËµqìOªSKkk«·œ¥å¯ë×¯›‰‰‰uïŠœ5£££æÂ…Ş¿§_`¹Ö™™#NÔïá;BÏ"ƒ gUÒŒøù|!²N©'eZçÏù?OĞ½¶rşmmmæØ±cŞ7ûÅÅÅÈZ¤i™TE!–­Òîˆ]Õ{§›b$ß¤Ğş§f³~!ŞÄpY•äq'½læHS7¿GŞ€º¡¡Áôõõy`¹Ñ¬T³TN„Õ/ÚŒbÉUUÌii&¡¥ü–––¨>Ó½%T`3ãd£H¥tÓÁZÒ¬zéU=>µdšZª•¨Ãşà ~ÂT™j;7ÄhÄò²;]IG…,¤}«»ád³²sÎß÷XYY§ÿ{4ª¿CÊËY@t†¢ÊÊ0ÅZBƒøijj²z¿6oŞü’ciC+-|ÖN2CšyĞIß…²6÷÷'Åù(şL}›O‹$W£ËÛ,8c™*	ú^uwwg¦‡ïµk×ÂVxkÿ’‹¤!uèpşE'gG¢øs4Hi‰)íh–¤:QKQ"A0T¹ä½’\³†ª¿C65xš¡Ò„
L9Î¿£Lô9K¨Ğb£‡Ç™U&KooonEYB«1!—´2DChwÊP!š‡¨JVÏêÜzË²¼T é]Õ1!­hä¡aDÈ;<G¦!ivúû±Ş›Ç!{'‚
Q	'ë¨‚
x4CÖë®s *¾ˆóğ:ÜUUë­éKšÎê¦½ˆ'=ÚÙÎpIq°ÜË—ê(¢Ş”ê+©ÁyõŸfm:›¨eS•i¹İ;da K¨0I÷¦Z~.µMDïXÈ‡(µO¦=˜0ç¿ôR7ÕJBœúf(Ê·=â˜Ón†nÈôÒ«öÆ4{,ÇKòÕõBqóÄÑ… ÈhÉò3z…áâbS”¢Ô2k]Dt´AÅ(Q¶x»SÁK9„ /ı<[~V!b%Ã8”›&'¢ªW $%-ÑJÒQËR{« !ªc)ô²¢oc¡/9NSãfIÚQˆRmÇ²Ò èófùù}’áÊÉ™(Šw’¼h­åƒ[”Öv yF[+]ïgªb¡,l+J•{§ùÌ—îÓSsi‡&â ™AUç–_tÛÖ!jê÷PJ&YY¢¼téR ²t5yÎj‡€<`ù%—ÛH rB]³•Å~”:ú±ÑhUd  ÉaYè3ÁĞ©Y~ÍrãfÍ„:´f[=-ıĞ@ y´²c9FDBE˜ê×¼ìãéè¼ó™º‹Rÿ©&4 H­­­6ãT-Ã<DÁ^[Qjc ‡¶«šæ!,:S9k#JuÕÈÃM úûûmd¹…¡Âò¨í¬R×9 ÄÉåË—mÆ«½õv¯ÒjV©¥ €¸Q³‹1ëÃ=„a›(µÁÎ>% $
î,Æ­3÷†§Ú½@†Ğu‡ëº FjÜ,:wQ $‰ºi»†òÁ–‡‹[D&&&ø¤@bèB‹™åU†|°e,è×ÕÕÅ' E!8\Õ1Qm³W™¶+·  xè"yªa!.6}ØÔş  iN:e#ËöÁ†‡ƒ>lê‘
 4º/×¡ƒÄDà##j2 $*î±¨„5şÖ@`¦‚<hz8 ’Fg¼-D9Î±÷èrd €¤Ñz²<É°6´}Øº»»ù”@¢,,,˜êêjYngØÚƒ>lGå“
 ‰röìY«Û‘Ø¯d	 …AÛA¢aÈd	 …`llÌvVùC> K (ûöí³å’³|a@<²Ü±cŸV H„ùùySYYIótˆ¦ ]mm-ŸX H„şş~Û%Ø=÷–… :ı Ä‰.znhh°¥Æ¸J†zË _OOŸ\ ˆ•ÛYåi†yˆ‚Çƒ>|Ú3˜åÓ iŸU*ûyÂÍy7Ï¸^•ş?Sõ—m[)
‚•l·y éä ˜UF‘i7İôë<  ÔØ>DºK  Å³ÊrdÆYî1Û†>ŠÇ¨íƒséÒ%>Í ×YåFf°\›oüµùñ0KEE…wU @f•keÑßïl@-rÍÔÔÔx± D‰¶z2 ÊÕ‚$ÍZt“MÚİŒ•ó!Ñ-   Q¡n=–×p¥e¦©“œïÌĞLòJGWWŸn ˆËËÓ–I²)¥Ú¯ÖZŠë¡hooçÓ ‘033ãÕCä@–+#0ËLÎòáÛù¸†]»vñ	€HĞíF9e)ã ¥ù™JêAàÌ% DE[[[eYêS»]%Ç8—\WG›ğÚŒ ˆ‚úúú¼Êre>ˆ™Ç“~ãÏ;Ç§ "£¹¹¹ìã–öDëêê’;Oú[gPfªœå~…‰½Ùj¨®ûå  ¢äğáÃ‘ŒO­­­Ş-I:Ú¦æ)ÓÓÓfaaá§VÇÆÇÇÍåË—Í±cÇ¼‹îu†¼ÌãèÓşXeB^G„–\Uùª‡™›G  LLLXUÃj¦(9EÖ(EUÁQg»Ï0Ã,êz?SN!ª½Tgg§9tè7s¼víš÷ğ®õ  jNœ8±áåTUãKåfllÌ;S®Ykf˜3Bıjª²²··×û Te¿ÖSÿû¾}ûÌÔÔTì?—VÕöïßõYĞ§P\t{”“Q
Rg Ò¾$«qª©©É³ôŸ}}}ŞşcÒHÔ[·nR˜ÇQ]x®F¹ï¨lšŸ „çÂ…QíEwö‰ªTZKsss<İ  ¢}5SXğkS  ;£¥–
&''y¢ Ê„îßÔ„$‚1{Š#%Á+_ÂÎ&µä
  ñ°^aR€\A£Ú	ÙëµªªÊòä ÄŒšh)LúÈn€“a^äÚÚZª\ ddd$¬0gX]]ãbİ½¥¥…î:  )™a†\’=‰×æ¼íÛØØÈ   ù¦&NÍhñ¥4ÛÎ*5İ§â  }„¼ĞúÔøR®Ø¾ êá
  é$d·f—+h·}!õ­  Ò‹Â„¸Øúiùm†m^ÄB €pıúõ0{—hÒq¶ØîSRù
 t¢¥0ŸD•Ë×³°ü
 sÔGVZXö­,²(uéç¼cq{ÇD  ²GˆêØBwõ±*ìQÿA  ÈšèXÎ.}Iôq›vvÜG	 ]zzzXŠHà†égÏåI È0*Î´ìì³­ˆ¢lt,®İâg €ì³yófY/¢,	úBé6n  È>çÎ³‘å"Êr$èÅeÎ  ù@«„K±óE<2¸i:ÍÒ òCss³Íì²Pİ|êƒ¾@<Y  9¢»»ÛF–;‹$Ë¶ /Ğx²  rD¿,-’,w}x²  rÄØØ˜,I–}Ô±  òÃôô´,ÏI–}ÆÇÇy²  rÄÂÂmïîÂù /ºÕ @¾°åp‘dy#è  ùÃ¢©z¡d9äÅ©««ã‰ `f©<S$YNyqtp  ò…¶×(ğ‰P–õõõ<U  9ƒ£#_Í…, ò‡ZÈò¡"Ér8È‹SSSÃS 3ÔlÆB–»‘å:YZZâÉ ÈGµ‘e{‘dy…G  ŠMGG‡,ë‹$Ë'‚¾@×®]ãÉ È	‹‹‹¦ªªÊF–UE’åA_ S§Nñt äËâ§`¾¢«³³“§  'èÚEY>Y4YÖ}‘jkkyº  rBCC?oYŠ|  ŠÇÔÔ”(—Š¶_i]{ìØ12 €ŒÓÓÓÃm#8ôÅ¢G, @¶™5•••6²|¤¨²l¶x±¸  x³J¥É)0sA_0½Ğ  P¨YåŒSpú¢é…Ö  …™U,º,Ûl^¸Ã‡óÔ dm¡YÎ*ıã†…g&è‹W]]í]
  égaaÁö\%³Ê<nóÒÑ  tuuÙŠ’Yå
üÃ¦_Hõ €ôbyg%³Ê58oóBÖÕÕ™¹¹9F €211a{³³Ê5h²ıæ±yóf.† HjOª	MˆYåiÔQû»RtÛ6  ¤G”ºü"„(ı-:Xcv¹dûârß% @òŒ†¥òJ\Ÿ“a^à³gÏò¤ $ÄÈÈH˜=ÊR® Â»Sesî²”ŠŠ
f˜  	Ğßß…(§İT£Â±;ä‹mz{{yr b@û“mmma%Yº¯²ãbØ¾££Ãë  Ñ£S'Nœ°maÇ\.ÇN…}ñÕ^I›Í  CCC¦µµ5*I*Ï ½pÕ±aßíc:tˆY& @½"Ê¦¦¦(%©Lº©AyáØÕ¢Rfµ] €3==íİôTSSµ$•	ºôDÇÁ(ß-ÍJštı x)ºJK•­º¬¢¾¾¾‚,eÄßrƒ´œ¿\«¯¬ªfõ­	  hÌÎÎz—Qè¸İ¼Ö¡ºş°ŒrD”Yf)Ú¨îëëó¾Q äùùyOŒš è¤@™–T7š§e†…é¬¸XzëÖ­ŞC588ÈÌ 2»œª¾Ùš¨Ğ1A9®e*‹‡Gã~ƒõ-lÇŞìsxx˜ÊZ H%SSS U›‘9®lŒş0¢ŒŸü?‘7^ßÒômMbZÚ@ äë¹sç¢ê¢SŒºiD[ÉÑâ„è#[yjéV3OG (c._¾ì­xEØA‡ÙdÑAÖ«i{HÔLXû*¿VßD €(©:Š®®®(–3›,pó‚ù´>8:«´ÿ~síÚ5–l ¯‚Tfı³ñÌ&SL}g™wZ²moo7ÇóúÖÒ V¢=È.˜]»veEÊ¸?i©DEÙa“³ÜB)™ªhßAƒY²(&ªbÕ Æ ):æ±‘+µt¤íd—
ÿ[ÎdV¤é¬èa[’'M ò‰V”T¨KMÆÆ)my÷Wó Gl÷7›M£™§:nhÙvdd„J[€Œ¢'ºµC_†3´¼jüSı½Èfö#ó®ü:æB Deâ:¦ÒÓÓã•ÏÌÌ0
¤tïQÅ9*îËĞìñ–¿ÿ¨±r7³G–hµ¯yÆIÉ9Í(ªmU ¥[Í>©¸ˆ}îÔ¤DÍJRÖb.H†Q¬…Îıc¤¹2ÍÍÍ¦»»Û;ë©½OªnÊ3{Ô—TU¸§¸9 ²„È˜Î›,ï´|ÛÒÒâ-	I cccì„àÒ¥K©ä=÷Üƒ,YF‘¦¦&ïÀ³¾™¹¹9FA€» ^¬işb¬mí—Şwß}È’“å«_ıê,nÜºeEç½TD¤AA³PöA–QQ]ÚªYµ?ªÏ¬>¯+¿ğªYBb²Ô¸úÃ300`:;;“¾Tµ¬Ñ•½«€AF(]˜–Ï¤nÑªĞZUñÈR%ËÕ¨î”ÓƒœÑŠ¸ÀÔ8^3Qí‡ê°õìì,£*äUº¦YÈ2#ËÕÕr*Ø·oŸÍƒ›éh©JU¹Ú?ÑlTKD:Ú‚H!ËÄ½«=H}Õç'è¹jd	™‘åjÔÿU]<´d«î<E-,*‰TËºš‘ê›²öuÌE_0 ÒˆöãªPá¾h‡Ùê@–YY®Fr($"ËÓ¹C›¿Õ2UÇ"-q«m@èù+geºV`´úÕ¹hd	¹‘åZ3ÏİÛî7µ/¿q®“ºº:ïì¨„zàÀÓ××çZiÏT¯#Ë½5Ú“lu¥ò³ógÔ[^-×@d	¹•e‰[Ï˜¥Ávó7i5tèÇÍ¯oûWæ¯©2÷|¢´ª¾µ«ËŠöuÓCI¬jO¦oò¬+ÜuÅ²}õÙ½ÿu/3¿İYo>ûÄO˜Å¿İÜ|¶§¬?/²„ÂÈruæ/½Íõ5›ßyç˜m-¯05/û.„X†%`½ÇšµJ°Ú_–dUá¬H²Š–…5‹-Íd%\Ûç}é
ú<ıÊ;^e>şŞ&ï³»úóŒ,Y–I–wŠfŸ{äæ·vü°y{Sµ·¼ƒôÒ#İR´+ù®LIÄë¥$éõ²Ö¿«ƒê«ÿNEÅ#Zî§åáÆÑÊƒÍRëzŸ]d	È2FYŞ)Ï}ğ'ÍGßİhŞıóuæ­¯ÿSı}ŒÜñŒ¬fÆpwÔˆ#èë«/¯ÈeŠe¹ÖTËAíyÙù–2¯}Õ÷ â5Î¸ví6¼š}mß³óÕÈeÖd¹Öè³¿û&óÁ_ıQ¯ˆèÍßÏ2nA‹ X’]½66Í>yä_gM–cè e€|©ÿ§¼}Ğ÷ıÒ}fûı5ÌBcÇaÅ5Ps€ ¯gå½ßişøg•¥EAÒ’›J” È2DôÁ×^¨$ªjÜwş\­W
OEn~ö/™]ŞJ}=7½ñåwıL•[–j“gñ,ìA	€,Ë”Ù?|«·œ«¢"íÓh6ú†WŸ÷íe':/fbbÂêµüğ¯ıXâ²TE´ÅÏ>ï¦- ²Œ9ÏŸ¹ßÛ»ùÀŞ¾è–7ı ¹ï••È)¥³K®]‹D8fú£?¸,C\R=ïÏ0Y’d™†h@Q7u)zÿ»^ëÉT³R±¼›Lt_#,355euÍŞF–`ãeß—ü¢Ÿá”çª›ó~wó›-nĞ²,D´Oªb£O?öFo‰W­Â´WªÁèuußË2o™’¨Á?ØÏ*ÿà7_Ÿ
Y
İYğgzÑÍ„›§Ü<è¦å!ËBFû¥y²Å;Cª}"	U3TIU‡ÂÕSWË¾ôÕvFÑ‹}lg•Z¹[lœ²Ô>4ÏôK2ëæ¢¿Ô\…‘%¹ÃLUÍ>wâÍ^]ÍVuÆT‚UÏİo{¥'X'}_U³ª"£›ll^·»5"ˆ[–ºîK­äº3OÍ:·»©@‡È’„hÜ ÁjoU‚-I¶íµJ¶ŠJÍhKÑr±ä»r†«Ô½â»31œ8q¢¢TØÊÊà_–´-0sş-©’¥BŠËœ›“nêĞ"²$)ŒX	ùnÙH…åêh¿7Ìş¥nW)jĞ`óz©s÷&.Y†Ù-h–üb!ö7‘%)Rt[a­wlCCCÙg•qËRË±­­­ˆ0x®¸iB“È’ :ë¦rXK’E™aê›×HEeAß—8eYZ^¶èK–gšZ­F–È’ä<j
öH‰z¤æ›ÛETi­/$i—eI˜Ì0Cíi>PdY KR„¨Ğ(ì€Ñ××—[Qj©Òæv‘=oÿVïG²,ıìa†Ê¨SĞ–€ÃÈrÕ‡øúsëÙÍí¿<ln?wÔÜşòûÍí¯wÿóØò{ÄÜú³ÌÍOı;$”±IQtFÒì+mñl«FÕ9K²\ùûr¬Ä:j	¸YQ–×¶š[ş1ÏŸ4fêÃÏW~ÏÜú/ÿÑ,]}BÊ@TEƒ²:¸_ô³•:“kı¥4aY–f™j\@§ëœq
ÔC·Ø²üÄ&skô 1_;L’«óüï»³ÑıîŸù³H)åQ#†(
-YæF–º;èk ½à,Ër%ê%«æëZ¢Õõ^êä¤ñ.­Qãÿ”Síôee©åV-­†’äªÜşâãææ'·!¥”GÕ›Q*üÑ ›u¦§§Ëv»HVd™eT¸¤÷PKËııı¦§§Çttt˜êêê¸„©zÍÈ2‡²¼yã—\¹}(RQ¾¯~ıÌ”gñão7;ßòC‘Y¯”½páBàßY·ã„ú"ËXĞÅ §NòäiÓ™)@Ü´!ËÉòæ]ĞÊ"ÊR&?€0$LBY^’İ¿àßù±=¯A–£´Ô\Æ=ZÉÜ‰,ó Ëk[½ıÅ²Š²´$û•ãŞ(b*ÎSÒÉâ%ÚŸ‹«
Y¦¨éy-Ãl3·Â,”,oá}±ˆ²!¥ôSg£,ô­=KGK$w›övzİe>ö;>õşæR—d#Ëå}ÊÇœ™›Ÿê@JÈoíøáB
sbb"ğï§¡?È2uÒ´éàt—=Ìfd™AYŞ{O²ü°w~e#9ğºÈ.Ênoo÷Îñ¥õ½ú»é‹²Ì'###VËòëTÉ6 Ë,Éò›Ê_Ô³ÖŞå—ßˆ2İÙE§EË[iG-ü‚ş^ºËYæ}É;tèP”ç0+'K%‹²Ô™Ê$DY
~²×ï­¯ÿH‹´WÉÚôI[Üƒ,³Áõë×MMMMT~e&dù§¿œ¨,%k$”½ÂŸ_İú/CêŒ“æ
ÙÍ›7şæş¨Y„™™ÓÒÒ…0w#ËÈRı[•¥+kTÜ£%½½½©ƒ„ª„ä,²Ì*VÓ|Í×ë‘eÚe©&éIÊò³ûO†…¹åM?ºiªÓHĞ‘ï{e%²,è>æ®]»¢¸ŞY"Kd™ga†=Z’ÖÙeĞßC{¹È²¸D Ì%²D–9ÏÇyƒ·i3H¨P"{—Iœ±D–Ùa†\’sS,‘%²Ìy>ûÄO˜ªÊ{rÓp=èï =\dÉfÈ¢Ÿ“ÈY"Ëäãïµ;´­)Y—å;®Y‚W%âX‰Úá5!Kd‰,›*YõßLSW›{,‘%”Ğ9Ì³Ë+ÈY"ËäKı?e5Hè~Á4í?ıùÕtYB‰~‘%²D–È¦7¾<ğ 100@²ÌUÁOˆ^²ç‘%²D–i¼ôóÓÓÓƒ,‘e®Póõ{—uÈY"Ëœç¹şdæ‹|jkk‘%„&Äõ^'‘%²D–ˆÍÕ]i"hd	wBª,/Ö¹Ë
d‰,‘eÎô:¯ÖÖVd‰,s‰®¤³œ]nG–ÈYæ<oxõ÷úüÄq',²„¤f—êƒl!Ë§%²D–TÄÆşbÏ’âÀ6²\tS…,‘%²ÌqtH?ègHİOÒBĞŸ}[Ë+%¬ÉÔÔ”íRìd‰,‘eóÛõ†ÁÁÁTl6|t!6²„õhkk³‘åEd‰,‘eóá_û±Ì±9÷Ø× KX—sçÎÙÈrY"KdISõ¥ªª*=buÇfĞŸı£ïnD–°.sss¶…>ÈY"–œfşÒÛ¬î¸LCÛ»†††À?÷§{c®e©ŠÎ.x=OwìØá‹M[t³ièçÔRzéèè°‘åƒÈY"–GE/A?GªBÕ½€I¡†î6…j Ÿ7YêRî³gÏzg`C4O,úÒ£U×¤…S§NånßY"K’@XåèÑ£™*Â¨{ÅwGöš¥A–Z
ïïï||&­©¨¨ğfÃi¸ÙÆòËØ²D–H%Ç™ıÃ·šŠ{¾ÃjpŠ} ÓòÍ`üîŸ¯Ë,'''3;“ÜÈsÕİİmæçç}-Úß-"Kd‰ThN°f±î8+`õwÚü¬Ÿ;ñæ\ÈòÒ¥KÖ¯A–¢îL£££YÛ·l@–È’ä8ğ›¯·Ô´811Ëlª¦¦Æêg|í«¾'Ò×+)YZî¥e6ªJ½|ùr"¯µ®£³ø™· KdIr77|¿õ ¦™–GË…L[Q*ïû¥û2/Ë¢‰rå²l0´lñó>„,‘%Éy>ûÄO„Ø´×¤ãQ…ĞQƒP³“{¿Ó<æşLËR²(¢(W~‹»ğGûñ?ëãÈY’d÷Û^ÉÒ™–°ÂHS£Äky8¼,]{’’¥Î"ZŞµ˜«455ÅÚÃ¦¢›óÈY’äo>ÒjÕ¤`½û/uÄD…ëU7êŒ
WtëƒÅ¨şş×Õ}¯YüøÛ3-ËÍ›7^”¥h):ÎÈY"K²fŞÿ®×–uÿIU¢ş³ÜUZZ.Çk—,¯]»†$W“Å9»´ø¯¦U–7%²$ÑG·sd}`ı•w¼ªl¯O\²lnnF’«RÎB²d9œVYG–È’D-]Ú´ÁKKŞúúğúŞfY–ÃÃÃQ½ºc:™‹â÷Q—Ÿ¸hiiñV@VçŞ{ïı'd‰,‘%y¡Éz˜ã$ye\²ÔUh!^‡q7ÛİT¦lÌÖÏÓîæ´ßñÆª€Lıpã@bdf‰,‘%¹kfÎ¿Å+’A”ñÊR2±Ÿ+U8é§ÖÍ36¿ãØØ²D–È’¤o†¹ó-?„(c”eˆ%Ø3Nöú{ªa ²D–È’¤2x ÁªázÙ;¼¸?ÓowÖ—åˆHR²ìëë³İ›¬Ì ,÷ı]u_'²D–È’¤ºËOíËïM(ßøš*ó—'[bÊ-ËÎÎN›×ãa'›4ı]õú Kd‰,Iê¯ôÒuWQ6/ÈÂl2NYª
Óâu©Ï¨,+‚ş®íííÈY"K’âŸ¸¥Yó²ï2ïÙùj3ıÑŸNôw/·,-éY'Û,!Kd‰,I!¤)‘•s¹õ#^gşøgRñ;§P–c—å4²D–È’&Ïşî›¼åÑû_÷²pmÍ^~¯Ù~WTôÜ2u¿g
e9Œ,y%²$qşÑ¡7¿óÎ1¿µã‡Í;®Ö¼½©Ú;·yß++½™õßu,EÿL’ığ¯ı˜ùRÿO¥şwC–È2÷²,wçdIHşƒ,‘eîe©;Ê%²$Y"Kd‰,‘%!ÈYò> KdI²D–ÈY"KB%²D–ÈY‚,‘%²D–È’d‰,‘%²D–„ Kid‰,‘%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–ÈY"KdI²D–¼ÈY‚,‘%²D–È’d‰,‘%²D–„ Kd‰,‘%²$Y2H#Kd‰, 	A–ÈY"KdI²D–ÈY"KB%²D–ÈY‚,‘%ï²D–„ Kd‰,‘%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–ÒÈY"KB%²D–ÈY"KB%²D–ÈY‚,‘%²D–È’d‰,y%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–ÈY"KdI²dF–ÈY‚,¤‘e&Ş‡3ÈY‚,‘%ïÃúA–È’d‰,y%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–ÈY"KdI²dF–ÈY2@‚,‘%²D–È’d‰,‘%²D–„ Kd‰,‘%²$Y"KŞd‰,	A–ÈY"KdI²D–È2²œ˜˜@–È’d‰,‘åzF–È’d‰,‘%²D–„ KdÉû€,‘%!ÈY"Kd‰,	A–ÈY"KdI²D–ÈY"KB%ƒ4²D–È’dÉ ,‘%²D–„ Kd‰,‘%²$Y"Kd‰,‘%!ÈYò> KdI²D–¼ÈY‚,‘%²D–È’d‰,‘%²D–„ Kd‰,‘%²$Y2H#Kd‰, 	A–ÈY"KdI²D–ÈY"KB%²D–ÈY‚,‘%ï²D–„ Kd‰,‘%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–ÒÈY"KB²D–ÈY"KB%²D–ÈY‚,‘%²D–È’d‰,y%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–ÈY"KdI²dF–ÈY‚,¤‘e6Ş‡G%²$Y"KŞ‡õÙ‹,‘%!ÈYò> KdI²D–ÈY"KB%²D–ÈY‚,‘%²D–È’dÉ ,‘%²d€$Y"Kd‰,‘%!ÈY"Kd‰,	A–ÈY"KdI²D–¼ÈY‚,‘%²D–È’d‰,‘e
dyıúud‰,	A–ÈY®—d‰,	A–ÈY"KdI²D–¼ÈY‚,‘%²D–È’d‰,‘%²D–„ Kd‰,‘%²$Y2H#Kd‰,	A–ÒÈY"KdI²D–ÈY"KB%²D–ÈY‚,‘%ï²D–„ KdÉû€,‘%!ÈY"Kd‰,	A–ÈY"KdI²D–ÈY"KB%ƒ4²D–È’’d‰,‘%²D–„ Kd‰,‘%²$Y"Kd‰,‘%!ÈYò> KdI²D–ÈY"KB%²D–ÈY‚,‘%²D–È’dÉ ,‘%²$„ Kd‰,‘%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–È’÷Y"KB%²D–ÈY‚,‘%²D–È’d‰,‘%²D–„ Kid‰,‘%!È’AY"Kd‰,	A–È2ïÃ&d‰,	A–È’÷a}Ú‘%²$Y"KŞd‰,	A–ÈY"KdI²D–ÈY"KB%²D–ÈY‚,¤‘%²D–„ Kd‰,‘%²$Y"Kd‰,‘%!ÈY"Kd‰,	A–È’÷Y"KB%²D–ÈY‚,‘%²L,;†,‘%!ÈY"ËõrôèQd‰,	A–ÈY"KdI²D–¼ÈY‚,‘%²D–È’d‰,‘%²D–„ Kd‰,‘%²$Y2H#Kd‰,	A–ÒÈY"KdI²D–ÈY"KB%²D–ÈY‚,‘%ï²D–„ KdÉû€,‘%!ÈY"Kd‰,	A–ÈY"KdI²D–ÈY"KBe²ƒôhÆe9ƒ,‘%²$Y–{É¸,²D–È’dˆæææ ƒ´R‹,‘%²D–„F–»ví²‘åƒecĞßU¯²D–È’‚Ë²··×F–Sn*2(Ë=A×d‰,‘%!E—åõë×md©É ,Çƒş§NB–ÈYRtY.,,˜ÊÊJY.¹yÒM]ÊYåßm¾ŒŒŒ Kd‰,	)º,Å;lg—¥Ìúç‡S”© ÇDV§¢¢Âû2,‘%²$YšÁÁÁ°²Ìe6oŞlâY"KdIHÊe)äªœ={Y"KdI²ü6rEª««Íââbl²¬««C–ÈY’vYŠ––DéGGjâÄâgD–È’’$d9>>n[›«hI4ÎY¥¥,ŸA–È’’€,…öéŠ,JUÀÅúšÏÏÏÛü¬ç‘%²$„$$K¡®5õÄÇôô4²D–È’¬ÉR:t¨p3ÊşşşD^k5>°ø™#KdIIX–¥%Ù"ìaÖÖÖzmÿ’âÜ¹s6?÷ÃÈYBR K199éÎÏ£$õE@KÎÚ3LËYü¶´Ê²Y"KBŠ&ËÃÃÃ¦««+3MİáÙ××gæææRñÚZ¶lL«,ë‘%²$¤¨²\Ùx]K–ßt×c[[›wÔ"­immõ~NÍŞ._¾ìÓ¤-[È²Y"KBHJe	Ñ/s[ˆr2Í×¼ KdI²„4œk½‚,‘%$!È²0tvvÚÈò ²D–„ ËB –zUUU6²lF–È’’dY.\¸`#Êy'å KdI²„¤Œ\A–ÈY‚,Áìì¬×bÏB–!Kd‰,	A–…@~°å’›d‰,‘%!È2÷¨½^uuu®î°D–È’d	‘rêÔ)ÛV}{%²D–„ ËBÌ*-ÛÛ-º©Ê¥,»»»‘%²$YÂ>|ØvVù¤“Ërß¾}ÈY‚,ÁC}`-+`Sßˆ Y"KB%DBˆ{A¯8Y"KB%Ä]Ô£´#Kd‰,	A–¹fll,Ìòë°“1%²$YB tYvCCC˜Yå&d‰,‘%!È2·,--™0¢¼èdd‰,	A–°aºººÂˆrÁM²D–È’d™[zzzÂˆRyÔÉ(ÈY‚,á®:t(¬(§ÜT"Kd‰,	A–¹Ü£¹ôZºY¤ÅÉ0ÈY‚,aÍª×­[·†¥rĞÉ8ÈY‚,á%Œ‡=RÊU' KdI²„Ñßßo*++£åL.vF–È’d	fjj*ªe×Ò1‘V'' KdI²,8‹‹‹¦··7ªÙd© g““#%²$YX’¦¾¾>*I–²ÓÉÈY‚,Æüü¼wcHmmmÔ’ÌEå+²D–„ Ë344dº»»MUUU9$™[Q"KdI²ÌùrppĞ8pÀÔÕÕ•K¥=ÊİNA–È’ÂËrrrÒœ;wÎ“ŠnÔhoo¿côÏ4–²ÿ~sôèÑ¢#ÚT.\¸`†‡‡_ÈÄÄ„™~!êŒ%ú3¯_¿îıêáÚÜÜ\N9®®zİääd‰,	)¤,gggM___TïC§ººÚ+´¹SZ[[_$í¶¶¶ş™ş½îÙ<A–È’d¹biRMÁ#<&QÔ<“—†ÈY‚,W¸”yï®Ñşä#NÁ@–È’BÈR{yÈ.\¦³~{²D–„ Ë5Ğ™BD*‹nw2|%²D–„ Ëu¸ví²¿7Ùàd‰,	É­,UñZSSƒğì2îf‹ÈY’oYj¼Bz3ìf;zD–È’ÈR×MQĞ¨ÂõŠ›v´XdY>û`²²üL$!1ËRİxà†–ZÕÏµ"KOV‰ÊòÓ¿À IHŒ²T+9ö*×œAú•­(Y¾øƒéÊ*IY.]İÂ IHŒ²‰B,3~ßÓ¬ùŸğ‹uªĞ²\;²Ù˜¯NF–_ù=GBb–å±cÇlårÃMÛ]ÆÍ*ì,¥Ùßë+e›½~´ÄydEts~E†WeÔ?ø¿ÑL®øwŸvsÒÍC¾ëQ\tTB–nná}‰ÈòÖèAGBb–å®]»lDù4J€õ(„,oşé/'³_y}ƒ#!1Ë²¥¥ÅF–Íè 
/KovùÜÑxg•cïa`$$Yêê*‹½= dé}@?ÕßŞåó'ÍÒÕw00’Y£@–/9Fò¡òŠò«47oìbP$$;²F€,WP‡ÿCeù!DI²d™}YzÖ¡ï-•F)ÊÛ_9nn~z'ƒ!!Èe>déåê–ˆ”|ÈÜúüÃŞyNBB% Ë|É²ôÁ½¾Ã«\¼—ùµÓæÖçz¼Â!@B% Ë\ËòÛ3Íwxç1oıÅošÛ_|Ü[V}A ®õßo?÷˜¹5úææP'3IB% ËÊ’‚,%!$²üÜ{‘% KdIY÷Ù¿:†,!ß²looG–„p²t?çÈ%²$„¬×§ùë_@–€,‘%!dÍ<óÆÜ¾‰,Y†’åWŸb0!$ÏK°_ûO¦Ü KÈ½,oÿıgPÉkìĞ;İoÄßB–€,CËráïTÉc®ı[ïóÈr/Kqó3ïb`!$gû”·ÿñ‹&.%B–·ÿûuBò²ôú½Æü¿ÿeâYB!d©J¹›Ãİ4„d|òö?|Ş$²„bÈR¾üÆ”·ÇÁ CHö–\oıí•²A–€,KÂüÇ/"LB²’Ov,wæYú¦Id	…’¥'Ìÿó·,É’Işó‚IÈ
'ËÒ¦Î_Şü³_g`"I"K@–wõæÿş²¹ùù#fé›¬IjOrêc©”dYN¢È•,_æ?Íš[ıŞ·[0Bb¨nıÌ»¼c]qtàI@–Ó¨ r)Ëo7“ı–¹=sÃÜüó‡Ğ‰:ŸØä­ä”û–d	È2îÙ¦n-ùô/2Èv©õË1æ›_7YY²Ü¨8İoÂ7Ç3KòoøÙè,òsï5·ÿÇŸ%zFY²L‚^0·şÛ'——i)
"äv¼k³bnI‡,Y¦•o}q¢|ú½9U—çd	È2Â§W¤¥Zº‘"äSÛÍ­ç>ëíÈePEí×¿à$7ÿs'ƒ*É×R‚T5kÆ÷!‘% Ë´-ü×ZÅÌ:Iæö ?û ¹õÕ§¼ËŠ
²d™Ä¬snÜ+£÷Úí±×IRØvNwFj?>«G=% Ë¼±ôMï¾[_ù¨¹ùlGSHüqŸ9={ª`Ík²d™×™§;péÛ½s3 “Èå8òŞê†w™rÚÍ!K@–Èòî{ÿ4ëìVi¾·tËì“¬Zõ–U§>¶<sDÈe1ìyÓ»—SGUn}éÌò9Ow@DDdŞ¬ñ¯ßkR~ûÿş=Ÿd	È^Ä7¿nnÿÏÑå%Ü±Ç–/¹¦ú6ß3F÷‹’¾0iåA_  Y²„0Ë¸*"ú¯—½‡WHÄ^h¶¤¨œç>à½‡úBD•*²d	qVâj9W³Q‰T{¢Ñ»<#å^Ïøk¸¯»··¨™¢–Pµ¿˜â‘‘%²d	â[ß0·çŸ7·gŸ5·¦ÿÄ»®ìÖøq¯¹‚ªsuY°+ªTœ¥åqU¡ªI…¾¤xK§Y²D–Ù+•TÿáóŞŒH"ğÄú×¿onıÕ1o_ME'^ë¿¼"iiÔı}´<êÍİßÓû%Á™ŞñO„9ºyYÛ¦P KÏk/UùÆÔ²\wë-AJºZ–€Jqgµ”Ö‰'f	¬w¼î¿³òÏW´'èÿı/üLúùÜŸ“}Bd Ã¨ %  Kd	È  YBy™E– €,ÖgY ²@– P jjj% K €µ˜œœ*Jd	È ŠEWW—,/¢@– Pz{{mD©<Š
 Y@®™™™ñÆ&KQ*[PD*Ë––>™ 
–––Ì©S§LuuuQ.¸©D©,Ue¦  IFFFLSSSI–ò$€0ôáºtéŸT HU»îØ±#
I–ÒŒ`#<ôáªªªò¾Õ ÄÅÔÔ”Ù·oŸ©¨¨ˆR”O¡ Ø(Ù<df__ŸY\\äS eI–A’Ê¼›: ¥!ÌW[[ëm°#M ˆ­^E¼Üº:Ûş!(ãa<ş=zÔÌÍÍñ) +ô¥[5­­­å”$ç*Áš½Q=„•••Ş’ÉØØŸ| ØÓÓÓæĞ¡C6=]mr’!l©p3õC©3™gÏ5Œ pÇYäÖ­[ã¤²ä×h „b[¹RÍ6wíÚeÙÛ(8CCCŞê“Šc’¤2épD"ä©r?´Zféîîö>047 (ãããŞ2k]]]œ‚,Í&O;tèˆ©r3×ƒ¬Uº!@3N–jòƒ¾«šµ§§Çæ"æ¨2ê¦…aÊE­¿dëƒ­¥ÚoS›ı ½=H}ñÕÊQL…:ëŸ|¡âæX‚»ihh00×®]cÖ	RÔ0 ¿¿ßû¢óä²èæq7Õáw…ìñ„~/êÜ¡ëwtóúõëÈ !æçç½
VÍ\^]k_²–a’DdÃ)ùP¼ OZ>|ø°·ì£0 ”GúŒ©8'†F63Iõ¶n`˜†4ÑîDĞé§\ÑU=*G×’"Pi5+0û÷ï7&¥Ÿ÷yÕ‹™$¤šMi›i®U0¤¦Ú÷¼pá‚™˜˜`$X¶3T±ªŞÎ:­>Ï)ÿ\Ïºy„=IÈâòìE¿Àd!%jªBg=éeEYNÕó~âÄ	OŒ* ËÊçÖÍ7;ı:
€ÌRëÛ›ÎĞ‡ï%7§¨šOû2çÎ3£££H2‹*TµÏxìØ±,ŠqõRk#C,äµÌ»âo¼›¬GgÅTÔ Ê?<€´œË~($A=‹—/_öªÄ;;;Mss³·z’áÏÜ’?‹ÜãĞq
B›ÜŒäAšwŠÊæuœEKº¬T1<<LCˆTˆš%ê¸”šu¨ú[÷;ªğ¦!'t¸ˆ
> º;n,¯âÜ¨L5è©Gæìì,& ™™¯ÈFÏ‡=/mmmIôP;3npÓÄ	pgqô—Z–Š$Ïµ„ªe^ÍTª¿RªÚ7Õ,•Ù• 0©•öÁõŞê=Ö{­÷<EúãAªÃ· X,Õ>í,oæ²¾Xu–T³Um”f¬ªn,	VËÀ:''ÉÒ¨!:´ ×T3@U”êõÖ²¨^…é½ĞŒª´.ÀŒ0h´ó°Cã €HPIx››#ÎòM2v;’hK³XÉV³ğ*\Ò€¯è($PŠŠ™$ßR´|,a”’Vk&^úµßWúùK’SJ3½RôZ(ºG¯¤§×K·âğÎœ³|¤l¯CÓ €²£CÇ»İœq¸…„« .Éy#Q±Š¥”–'ï–ŒW|æ-ª|W“ã:,€„Ñ7TJ>é¤¸å!NqöõYÜâ,ß )ynw–«éT,Ä'!å9>îË‘Vs G%è:Ì¬«zÆœœ4F Ä‰ÏQETµŞêĞb ÷¨ˆöPô:Â”—ˆñª?kÔJM àêå¶|*HĞ±•	MR€Ìø3Æ#ˆ ÂÌBuPz§/Ñ§ü¥\f¢$kÑ5VÏø«)9Ë÷ĞÖğ€r£¦Í_Î=î;×lt™$˜i	UÏ¤š{h‘â H­H[üéÃş·yÉtœY)	™yuãi_ˆú²¦jÔF‡9  gTûË»äÔÑDûEg|¡:¾”D23õŸ…Óş—­íşóÂ àÔŞAªšMœ÷—Ú†ıÁuÉ¤ş>F½O#şŒP|ÔO7ùï1-à  b”k½³\¼±ÍŒñ%{Ú—ìE_²Ê”?ˆ³4¼ñ%P½^cşëwÑM¬ßNÿõoöß:Ù  äŒ
€WZıA¿İÀŞyØÄ‘U">¿jÖ»VÆ|éD‘É»ü]¥¬üù_ñ³?¸â÷Ú¶âwn^ñZ°ü	0ÿräğ‰ñğ~    IEND®B`‚‚™˜˜`$X¶3T±ªŞÎ:­>Ï)ÿ\Ïºy„=IÈâòìE¿Àd!%jªBg=é


# icon/tailscale.png

‰PNG

   IHDR         “   C€IDATxÚíİoheç}/úßÚê(¡[[&¹u¶f¶ÁFfnd—‚BÛDÁù8oêÀÉá¨ërŞ”Œq 9=à?…r{!ÅãW>·Á“ø@¡ÁSâ¼‰k‘’qš]Š™I†ˆ´ã¥™mrfŠ£­]«ØÚë¾Æ™šÑŸıo­ıùÀx¬ÑhÿÖ×Ïz~k=ÏZI mQ«Õj7ÿÖÿ´±Q»å%É-¿×Š+ET¶û{²Ûü™[¿(«Ä¾Çn>–#¹•îû;$ÉN¿G#É²Æ6ÿni›qêæïİˆ¡¡Æ-¿·ùkó¥iê°Âş%JÀ€NÖ¯M7mlüzÂ¼5Á¾~"şá¤ûÖ‰µ	2@oüº9¸±Qi$YÖhE4J+74CCéM¶‘¦iC)Ñ @~'óµ¯²'IíÚ>K’Úu÷›'ğ °Ùl5I–¥×5È²tëîD#6oDhĞ @G'öÓQÙº2$K’JdYíÃI? t_z}ÃK[BªQ@ ;™ào^±?’l^­¯mMì+ª@5®5
Y–¥¥ˆ¥(•ÎÅæÒ£sÊƒ€"Oôk·™äO‡«÷ ¶kÍÁ¹ëšƒsî  OıJDLG«5ŸÌ"®Mò+ª ;Öˆ$9§1@@¿OögÃ} è¤s‘$i’eoj
Ğ Ğ	-66f[IòÉds²?­* Ğû¦ ‹8WÊ²7chèŒw% `şVëñØ¼ºÿxXÆ yF’œKZ­ïiĞ p·	%66ßºÂÿxXÎ …h²ˆ3¥,»Ö4”À`OúkÑj=%ÉF–Íª }æ—œI²ì{Q*ñ(R ƒ3éŸmµZŸI"Wù`¥YÄk¥Ré{išQ ÅœôŸkù€Û7gJ¥Ò‹îh Èï¤¿Òjµ¾’$É¬å= Ànš$Ë·‰X@~&ş³Y–=kÒ ì¦˜œIZ­WÒË—¿­ úkÒ¿yµß  3®-zŞ] ½ø»Ú tUñíR©ôŠÃ Lü€Ár.É²-Ò ĞÉ‰ÿÄÄY’<ß	 ô4É²ç5 Ú5é·¾ Ğ É¿+ş €F À LükµÙ¬Õú–‰?  @Pô‰¿Í½ @ÑRé=5HÀÿZ–eß2ñ Šjëñ¡Ş# ø‰¥Õj=»µÁ @#@Ç)AÏ&ÿ_ÉZ­×’ˆYÕ  E1Yöøx¹¼Òh6Ï©HO]ø[ç °)MJ¥Ïº (êÄßr €Û°,¨»,êÆäbâñ,â‡–û  ÜÊ² ®×›Mü=İ `WÜè<w :7ùÿJÖjımD<   ;³u7à‰ñ±±++*Ò‘Óæ‰¿«ş  m™©&g’$ùcwÚË€öNş]õ hãôÊİ€ôUJĞ–‰¿«ş  do@û¸°ßÉÿæ~^Wı :Æ“‚4 ½Ÿø×j•r¹üG’œŒˆª @ÇU"I«¬¬¬¼¡{n¦ØÃä¿–µZ?Œˆšj  ô„·ïQI	v=ùÿJÖj5ù èí´,kµÎÖ>¡»c	ĞÎ'ş›K~²ì¹°ä  |4"ş³%A»c	ĞÎ&ÿµ¬ÕúnDL« @_²$h‡Ü¸ûäÖz €¾WÙzJĞR£ÙügåĞ ìmòøğ³Y–};,ù ÈG$_‹•••7•C°ó‰ÿæzÿ—"â„j  äK1;66VÿÿÆû*rK}¸iòo½? @1Øpzãäzk½¿É? @¦wY«õÃZ­VS
Àí&ÿd³/ @!›€³µ‰‰Ç•b“= ñáfß“a³/ @}Ôæ`À“ÿˆçüw Pl[›ƒ¾	èàğáÃß
Oú ´& ¶²²ò½®Áà©Õj•,Ë¾Y6ë? €Aœ'g’$ù|š¦À Lş=é €ˆsI©ôùA{Lè@5 [Ïø÷¤  ®¸wÌc@Mş ¸İ4qĞŞ0€É?  š€i Lş ĞH`ò €&`@ “  4Ò ˜ü  	Àä  MÀö
õ “  Ú,MJ¥‡ŠôÆàÂÜØzÃïwMş hç4sëN@EĞg²,ûnDLË(  m6½5×,„¡"|ˆÃ‡+‰x\6 èÚØØXmeeå{€^‰Ã‡Ÿˆ2	 @'%Óccc±²²ò¦ ‡“ÿ,â9q  KMÀlŞ›€Ü6 µ‰‰Ç³$ùŸb @·›€ñññ´Ñhü,§?'ÿ›û<  I©ôÙ4MÏåíÏİS€®{Ö¿É?  ½RÉZ­ïæñEa¹º°õ¬ÿ³áYÿ  ô‡s[wyùsu Õj=kò @™nµZ/äéÎÍ&à­Ç}~]Æ  è'y{<h.– m=ñç»â @ßN¬7—Ñ ìwòÿëM¿5±  5’Ré¡4MÓ~ş!û~€É?  9qíÉ@À>|ø“  rdzëÁ5}«o7×jµ¯D–='C  äI13>6¶ÒXYYèÓŸ¯/'ÿŞô @õí~€¾\äM¿  ä\%kµ~Øûú®°î €‚¨õã~€¾ZT›˜x"K’oÉ
  E‘dÙçÓË—_Ó Ü<ù÷¼  Š©¯öôÍ ­Û#&ÿ  M%Ë²¾YåÒİzäç×e €‚ªõË£A{¾È#? }±¨çK€¶n‡˜ü Pt}±¨§K€¶–şü7Y  `@ô|)PÏ– Yú À€êéR -ÚzêÉ?  ƒ¦§KzÒ Ô&&H"pì HY6[›˜x¼u×— yá  DÄæR ûÒ4mtó/íú /ü €ˆˆ¨lÍ»ª«w ¶®ş¿íX ÀÖ„¼Túlš¦gºõ÷uõÀÖÒ  àÚ9Ëºz kï¨ML<Iò„C  7N•»ùn€®,²ñ  î¨k‚»²ÈÆ_  ¸£®mîø  `‡“óÍ» i'ÿßèÅ£   ºñ†àŞ¨Õj³ü  »˜ wø± ½µZßr `sè?´c@mbâ‰°ñ  vÛÌÖjµÙÜ5 Y’Xû  {™Kwp%MG Wÿ `Sê­9uÛudğ‘Ã‡ßÖ   À¾¤I©ôP»_Öö; ®ş @{¦Ö­VëD»¿iÛ kÿ  =’ˆ¯ôuàê?  ´U¥İ{ÚÚ ¸ú  íÕî9vÛ Wÿ  #jí|/@Û€,I¾âØ  @ûµóíÀmi ¶:’i‡  :Ò´ííÀmi Z­Ö9*  ĞÉ =wöı"°Z­VËZ­·  è¬¤Tßï‹Áö} Õjyò  tA;^¶ï ‰˜u(   óÚñb°}5 ı	  ]UÙïfàıİ(•lş €.Úïfà=o¶ù  zc?›÷~`ccVé  ûö³xÏ@–$ş  =$ÉgºÚ Ôjµé°ù  zcoŞSĞjµ¾¢ê  Ğ;­V«{€gÿ @oíõ »n ¶n5Ô”  zjOïØı€Vëqµ €ŞÛË2 ]7 YÄ*5  ô^±ëóîªğô  è+µZ­¶«ùùnï Ìª1  ô‘].Ñß]e–ÿ  @É’dWsôd§_X«Õ*Y«µ¬Ä  Ğ_’Ri<MÓÆN¾vçw 66f•  úĞÆÆã;ıÒ7 ­]ŞZ   º£•$Ómo ¼ı  úS²‹Gõï¨Øz´PMi  /íøq ;»`ı?  ô·>tG@V*Yÿ  ıí“mk "Ë¦Õ  úWñx[ ëÿ  *;Ùp÷; Öÿ @>ì`î~× •$ŸQI  è;yÀ]€$bZ)  ÿ%;¸xŸÜé_ÖjµJÖj-+%  ä¤	(•ÆÓ4ml÷ïïv`Z	  Wî8‡×   @‘´Z{o ²,³  òå“{n "Ëjê  ù‘EÌŞéßo»	Ø`  È§;m¾Ó€i¥ €\Úv.¯  €¢¹ÃFàÒşPMå   —>¹û I>©n  ?Y’LïºÈ, €œv Û?Íó¶@­V«D–UT  r©R«Õj;n ÂÕ  È»i   ŠmêSÚÍ  9™ÿGì¢ğ   ÈµÒn€ì»† €ş—mó.€íö h    ßjµZ­r× V«M«  Âİ€Û}  KÓ;i ¦Õ	  
à6O÷,íä‹  €Îÿo³·÷– K’#J  ùWÚI
  …p»‹û·6 I¢  €Bt ·^Ü¿¡¨Õj•È²ŠJ @!Tn~ÀÍw jj  ÅjîÔ TÔ  
ezû`c£¦>  P •í €  XnšãÛ   ÅvdûÀKÀ   hÆ·o   €B¹ùe`74 ™·  @Á:€ßóe   [í¶ÀÍo  
Ò\7×/m×   …qÛ ¢.  PHµ[€›Ş  ÄÆÆm€¡¡šÊ  @±ıºhµ*Ê  ”$µ[ {    Z6 Àà(EŒİÚ ÜôŠ`   ²m–   ÅT¹¥È²¬¦.  P@YvkIRQ  (¤Û4 ×u  @€Z­fò  vmÎ_º¹#   
©ñ è?ÃÃÃ1>>ããã122òá¯áááÜğõëëë±¶¶«««şïêêj,//Çòòr¬­­)ªüÈòh  ŸN¸Õj5<‡Š‘‘‘]ıùÄ¶ısËËËÑh4âÊ•+qõêÕxï½÷]~äùm ’ˆˆZ­6›µZ?TèîIwrròÃo7]½z5.^¼èd,?ò#?ò$)•>Ÿ¦ék›w 66j‘$ª]pèĞ¡8zôh×Oº×;xğà‡½^‹/F½^wpäG~äG~ È66*¿^tĞµ«m÷ßÿ®o¯wZµZjµ«««qşüù¸xñ¢&?ò#?ò¶¹èğáç²ˆg•Úïˆ£GŞ²q®_9ËüÈü@a'şÏ§—.=7Q›ˆYeö9tèPü§ÿôŸâÈ‘#144”›ŸûÚ†ÀÉÉÉX__ååeS~äG~äŠÑ ¼ÙXY9s­x<"f”öott4>õ©OÅ'?ùÉÎíç¸v"F£áQ~ò#?ò#?sYÄÏVVVşşZğÅˆ˜VØŸÉÉÉøô§?•J¥0Ÿi||<ªÕª«qò#?ò#?s¥ˆn¬¬|o("b¬Rù£ˆx@Y`o†‡‡czz:¦§§su»}7Ÿ¯Z­Æğğp¼ûî»±±±á ËüÈü@Î$ç>l Æ+•ÿ5eİ¹¹¹øíßşíÂÖ}ìcqäÈ‘xçwÜ’—ù‘ùÜu Iceeå•’JÀŞİsÏ=ñØcõİ£õ:idd$yä‘ ù‘ù‘È¡Í= •Êá ìÊäädÌÎÎò–ûİÇ'>ñ‰X]]µ.W~äG~äòbóÀÿ»¹`lì¹ˆ¨¨
ìÌ<¿û»¿;ğu¨V«±¶¶ï¾û®PÈüÈü@ÿ{eeåÅkO:¡€Ÿ|~øa…Ørï½÷:	ËüÈü@>4VVV^ÜÜ$&ÿ°“““N¾·ñ;¿ó;199©ò#?ò#?›@–i à.î¹ç˜™ñ¾¼íÌÌÌØ˜'?ò#?òı­öë ¸£ÑÑÑøƒ?ø…¸‹Gy$FGGB~äG~äú˜ îbxx8yä‘zÔŞ~k5<<¬ò#?ò#?Ğ¯@­V«)lïèÑ£N¾»022GUù‘ù‘èCµZ­æ ÜÁäädÜÿı
±K÷ß¿Myò#?ò#?Ğ§4 °ÑÑQW’öáá‡èõ¸ò#?ò#?ĞÏ@EàVn½ïÏğğğ@?²P~äG~ä4 #“““qß}÷)Ä>U«Õ8tèü ?ò#?Ğ?ì€Ûqë½}ñÙåò#?ò#?ĞÏ4 p“ÉÉI·ŞÛhddd 62ÊüÈü€ rÆÕ·ÎÔtPÍ-?ò#?òıß llT”6¹úÖÃÃÃ±¦Y~äG~äúŞÆFÍ&`¸«oóÀÈò#?ò}À Ø211áê[ŒŒú‰ò#?ò#? €œq‹¸óŠ|…S~äG~ä4 #£££Q­V¢Ã<XÈÍxò#?ò#?¯ IjÊ€ÃAEè’"^é”ù‘ùÜH/ƒˆÍ§oĞòƒüÈü@i x£££®ÀuQÑnÃËüÈü€ rxB »Š´ŞY~äG~ä4 3gÒ#?ò#?ò  ãããŠ`Ò#?ò#?ò¡Q)EDM)TÃÃÃQ©T¢ËFFF
±W~äG~äò¦1æ ÍÕ7µ—µ÷ä°	 'º¯W>åG~äG~@ 9322¢=2::*?Èò pV{ŸùAíA b#Xïá
œüÈüÈä²È’dLT®õÎäùA~ @QQ•+pNÀò#?ò#?0H²$©Y„“ &?ò#?ò#?0@4       4   € òj}}]zdmmM~ä4 à$ ù’äù 8	Îêêªü ?Èh  »Ş{ï=Eè‘"\ı”ù‘ù äŒ«@j/?jï3È˜J)Ë²š:à$@·áê§üÈüÈäN–UÜ` -//+B4ùA~è  Ô^~ÔŞgĞ À`X[[s¾F!6áÉüÈü€ rèÊ•+ŠĞe¿úÕ¯äù‘ù ôÆÕ«WAÍ}5÷Yä4 0(êõº"tY‘®zÊüÈü€ rfmmÍ¡.ºzõj¡Ö=ËüÈü€ rÈU¸î¹xñ¢ü ?ò#?  '…AQÄÛïò#?ò#? €œq¾;êõz!o¿ËüÈü€ rèüùóŠĞao¿ı¶ü ?ò#? €şpåÊW‡:huu5._¾,?ÈüÈh  \¸pA:d®pÊüÈü€ ræâÅ‹±¾¾®m¶ºº:åG~äG~@ 9³¶¶?ÿùÏ¢Íåê›üÈüÈh  ‡.\¸`-nÚÕ7ù‘ù‘ÈCPS¸ÑÂÂ‚"´É ^}“ù‘ù>Vs nãÊ•+ŞÎÙ/^È«oò#?ò#?ĞÏ4 °·ŞzË†¼}X]]è«oò#?ò#? €@Şzë-…Ø£óçÏôZfù‘ù‘èWC•±±ç”noyy9†‡‡ãcû˜bìÂ…bqqQ~äG~äG~ ¹ wáJÒî¬®®z”¡üÈüÈh  ¿ÖÖÖâ?øõ¸;<ùª•üÈüÈh  0'îìG?ú‘«•ò#?ò#? €bX^^ö|î;XXXˆååe…ù‘ù>g0ìò$¼¶¶÷Ş{¯b\ç­·ŞŠù—Qù‘ù‘Ğ @ñ¼ûî»NÂ7|/\¸ ò#?ò#? €bŸ„WWW£Z­t\y“ù‘ùœI>œ)ìÍøøx|úÓŸ‘‘‘úÜëëëñƒüÀš[ù‘ù‘È!w `Şÿı¨×ë111ÃÃÃñ™WWWã7Şˆf³) ò#?ò#? €Á³¾¾o¿ıvş.\ˆÿøÇñşûï;ğò#?ò#? €Áµ±±¿üå/cuu5ÆÇÇw5n}}=şéŸş)£Õj9àò#?ò#?cö @›ŒŒÄÑ£Gcrr²Ÿ§^¯Ç[o½å;ò#?ò#?  îdrr2=šÛz«««±°°W®\q0åG~äG~@ õD¼¾¾?ÿùÏ=[[~äG~ä4 @‘OÄ«««qáÂ…ø×ı×X__wÀäG~äG~@ ´ÃÄÄDÜwß}}óŸ«W¯Æùóçİj—ù‘ù ĞI###qèĞ¡˜œœŒƒvı¤[¯×]m“ù‘ù ĞË“ñÁƒã{î‰J¥ÒÖï¿ººW®\‰«W¯ÆåË—tåG~Ğ  ıäÀqÏ=÷ÄøøxüæoşfŒÆğğpŒŒŒÄğğp8pà†¯___µµµX__÷Ş{/Ş{ï½øÿøX^^_ıêWN¸ò#?È   €ATR  Ğ       @   h           4   €   Ğ       @      @   h           4   €   Ğ       @   h   @   h           4   €   Ğ       @   h       h           4   €   Ğ       @   h                  Šæ7” úO¹\©©©˜zğÁ¨~üãQ˜ˆjµårùÃ_×k6›Ñl6£^¯oşïåËQçXüÅ/bqq1šÍ¦¢Êü ?@DD$GÎ”zÂ››‹™O}*fff¢Z­¶õû/..Æââb,,,ÄÂOõz]ÑåG~Ğ  İ>é;~|óÄ;3ÓÕ¿{aa!NŸ>íd,?ò#?ò  ÓfffâÄSOuı¤»ùùù8ıê«1??ïàÈüÈü€ h‡kWÛ|òÉ¶ß^o—z½'OŒÓ¯¾ê€ÉüÈü€ Ø«'¿ô¥8qâÄ-çú•±üÈüÈh €=˜™™‰oüÕ_õí7'bù‘ù‘Ğ  mP­Vã™gŸ¹¹¹B|Ó§OÇÉ^°YO~äG~ä
b¨26öœ2@{;~<şú›ßŒ©©©Â|¦©©©˜{ôÑhşû¿Çââ¢ƒ,?ò#?ò  \.Ç×¾şõøÚ×¾ùÈG
ùùæææ¢<6gÏ>øÀA—ù‘ùœ²ö©Z­Æß~ç;¹]k»[õz=¾ø…/¸%/?ò#?ò9URØ»©©©øşë¯ÌÉ÷ú	G‘–ÈüÈü€ ¸«cÇÇ÷_=7×k÷Iøû¯¿Çù‘ù‘È{ `üÒ—â/şâ/¾sssÑl6ãìÙ³B!?ò#?ò (îÉ÷™gQˆ-Ÿ™u–ù‘ù Ó±ãÇ]yÛæ$\çé“ù‘ùğ Ø¡kîØŞç{ÌIX~äG~äúœMÀ°Õj5şú›ßTˆ»¤ÇÊüÈü@^¹ wQ.—îQ{ûQ¯×ãs=ÍfS1äG~äG~ ¹ wqâ©§œ|w¡Z­Æ‰§Rù‘ù‘èS6Ã;v,¾öõ¯+Ä.=ôĞC6åÉüÈü@Ÿ²¶qí“®¾íM³ÙŒÏ=öXÔëuùA~äG~ XÛ8qâ„“ï>”ËåxæÙgåù‘ù ô¿cÇyÍ|ÌÍÍÅÌÌŒü ?ò#?ĞG,‚ÛøñO~âê[›Ôëõøıßû=ùA~äG~ O¸ 79vì˜“oU«ÕxòÉ'åù‘ù>á ÜÄÕ·ök6›ñû¿÷{ñlnù‘ù‘èwî Àu\}ëŒr¹Ç“äG~äú€; pWß:gÖâÊüÈü@¸ [æææœ|;¨Z­ú‰ò#?ò#? €œñØ½Î;ñÔSòƒüÈü@Y±yuèÇ?ù‰BtÁÿyôhá6ãÉüÈü@¸ nwQ7ãÉüÈü€ òvRpû½kæ}T~ù‘Ğ @ïØÖ]333Q.—åù‘ù ôî„@wÍÍÍÉò#?ò p˜šêSòƒüÈü€ zcêÁÁ¤G~äG~ä4 0ÊårLMM)D—U«ÕB¬Ã•ù‘ù äŒ“¯ÚËÚûò p@íåGí}ù QµZUµ—µ÷ä4 00'‰	Ep–ù‘ù 
ÁL~äG~äG~@ ƒtpÈäG~äG~ä4 à$€ÚËÚûò p@íåGí}ù       4   € z¤Ùl*‚ÚËÚûò p@íåGí}ù 8	Ğ6õz]~ä4 à$00Í×ÊŠü ?Èh  Ë'àË—ÁäG~äG~ä4 à$€ÚËÚûò (œÅÅEEP{ùQ{ŸA~@ N¨½ü¨½Ï ? €Âi6›n÷èä[”Ç8ÊüÈü€ rfá§?U„œ€åù‘ù ôæ¼° jî³¨¹Ï"? €A1??¯İ>èª§üÈüÈh  gšÍ¦+Bİ<ù.,jİ³üÈüÈh  ‡æßxCºäôéÓòƒüÈü€ œEo¿ËüÈü€ rÆmøî˜ãBŞ~—ù‘ù äĞÉ^P„;ıw'?ÈüÈh  ?ØÖYõz½ĞkåG~äG~@ 9têå—¡CN<)?ÈüÈôäÈáÃ™2À¦r¹?şÉO¢\.+FÕëõøıßû=ùA~äG~ ¸ ×i6›ÖâvÀ \}“ù‘ù<p nãÇ?ùIT«U…hƒA¼ú&?ò#?òıÌ ¸¯>ı´"´É ^}“ù‘ù äÌÂÂBÌÏÏ+Ä>>}:N¿úªü ?ò#?ĞG,‚mT«Õøşë¯Û·Gõz=¾ø…/ì£åG~äG~ _¹ w8üùóÏ+Ä<yr O¾ò#?ò#?Ğ¯†*ccÏ)ÜŞââb”Ëåxèá‡cN½ür¼ôÒKò#?ò#?ò}È ¸‹r¹ßıuOåØ¡z½Ÿ{ì±h6›Š!?ò#?ò}È ¸‹f³_üÂœPvxòU+ù‘ù‘èoî ÀMMMÅ÷_]!îàs=‹‹‹
!?ò#?ò}Ì Ø¡ÅÅEÏç¾ƒ¯>ı´“¯üÈüÈä€MÀ°Ë“p³ÙŒÏÌÎ*ÆuşüùçãoşæoB~äG~ä4 P<gÏu¾éä{êÔ)…ù‘ù û$\¯×cîÑGº_}úiWŞäG~äG~ gl†}˜ššŠ¿şæ7î}×LbÍ­üÈüÈh `àT«ÕøÛï|g`NÂ×µç-›ò#?ò#?Om8!}î±ÇâÔË/ş³zùåøÜc9ùÊüÈü@Ù mğÁÄ›o¾õz=¦|0Êår¡>_³ÙŒÿñg/½ôR|ğÁ¸üÈüÈh €ˆÍÇôÍÏÏG¹\©,ÄgšŸŸ?ùò—caaÁ–ù‘ù° :äØ±cqâ©§r»6·^¯ÇWŸ~Ú‰W~äG~ä4 @‘OÄÍf3N¾ğ‚gkËüÈü€ (ò‰¸^¯Ç©S§âô«¯F³ÙtÀäG~äG~@ ´ÃÜÜ\;~<æææúâçYXXˆ“/¼àV»üÈüÈh €NªV«133Ç™™™®Ÿtççç]m“ù‘ù ĞË“ñÌÌLL=ø`LMMµõû×ëõXXXˆ…Ÿş4æççtåG~Ğ  ı¤\.ÇÔÔTL=ø`T?şñ¨NLD¹\jµårù–ç|7›ÍÕëõ¨_¾õwŞ‰Å_ü"påG~@   ƒ¨¤      4   €   Ğ       @   h           4   €   4   €   Ğ       @   h           4   €   Ğ   €   Ğ       @   h           4   €   Ğ       Ğ       @   h           4   €   Ğ       @      @   Ío(ôŸáááñññùğ×ğğpÇnøúõõõX[[‹ÕÕÕÿwuu5–——cyy9ÖÖÖu€”Ëå˜ššŠ©ŒêÇ?Õ‰‰¨V«Q.—?üu½f³Íf3êõúæÿ^¾õwŞ‰Å_ü"£Ùl*ªñÇø’9|8Sèı	·Z­ÆÁƒãĞ¡C122ÒÖï¿¼¼F#®\¹W¯^÷Ş{OÑ6áŸ››‹™O}*fff¢Z­¶õû/..Æââb,,,ÄÂOõz]Ñ?ÆĞ  {9éNNN~xâí¦«W¯ÆÅ‹Œs>é?vüøæÄf¦«÷ÂÂBœ>}Z3`ü1ş€ Ø‰C‡ÅÑ£G»~ÒİN½^‹/šÈåÄÌÌLœxê©®Oú·3??§_}5æççãñ4 À5×®¶İÿım¿½Ş.«««qşüù¸xñ¢Ög®]íòÉ'Û¾¼§¹“'OÆéW_uÀŒ?ÆĞ À`{àâèÑ£·lœëWNÄıåÉ/})Nœ8qËÆİ~¥0ş@ ëĞ¡C133Ó·WÜœˆûÛÌÌL|ã¯şªo¯økŒ?ÆĞ  [FGGãw~çwâãÿx!>ÏÛo¿çÏŸ·Y¯KªÕj<óì³177WˆÏsúôé8ùÂÖxŒ?ĞG†*ccÏ)´Çääd|úÓŸJ¥R˜Ï4>>Õj5Ö××cyyÙAî cÇÇ_ó›155U˜Ï455s>Íÿ÷X\\t?ÆĞ @1ÇôôtLOOÇĞĞP!?_µZáááx÷İwcccÃAo£r¹_ûú×ãk_ûZ|ä#)äç›››‹òØXœ={6>øàİøcü²öitt4yä‘Ü®µİ­ÕÕÕø‡ø·äÛ¤Z­Æß~ç;¹]ë¿[õz=¾ø…/Xdü1ş@¹ ûpÏ=÷ÄÜÜ\|ô£˜Ï|íjÜÕ«Wãı÷ß‚}˜ššŠï¾öZüÖoıÖÀ|ær¹s>ñoÿöoB`ü1ş€ òcrr2fggyË}''áO|â±ººj]î;~<^ù_ÿ«K~vÒü_ÿõ¿Fıwì0ş@ ùğÀÄïşîï|ªÕj¬­­Å»ï¾+»ğä—¾ñ1ğu˜››‹f³gÏ
ãñ4 Ğß'ß‡~X!¶Ü{ï½NÂ»œü?óÌ3
±å3³³š ãñ4 Ğ¿&'']yÛæ$ìvüİ;~Ü•ÿmš ËŒ?Æè’ÀÎÜsÏ=133£Û˜™™‰ññq…ØÆÔÔT|ãßPˆm|ãß(ÔûŒ?ÆĞ @ÎÆüÁ(Ä]<òÈ#1::ª7©V«ñ×ßü¦BÜÅ =Õøcü ô±ááázÎv;j5<<¬[Êå²‰í.kU.—Ãøcü ôÎÑ£G|wadd$=ª[N<õ”Éÿ.T«Õ8ñÔS
aü1ş@Ùw099ÓÓÓ
±KûØÇlÊ‹ˆcÇÅ×¾şuØ¥‡zÈ¦`ãñ:È ØÆèè¨+IûğğÃôz\W²÷ç™gè;'Æãh  ÜzßŸááá~^ù‰',ıÙ‡r¹Ï<û¬ñãh  ;&''ã¾ûîSˆ}ªV«qèĞ¡ûÜÇ‹cÇÀ>ÍÍÍä£/?ÆèF*ÜÈ­÷öÄ	œ¥?íó¿ú+ãÆh¯Ô ¸Éää¤[ïm422÷ßÿÀ|ŞcÇYúÓFÕj5|òIãÆh# ÜÄÕ·ÎÔtPÍíêgj:(ï0ş@ ]æê[gÄšfWÿ;£\.Ç±cÇŒ?@ íçê[ç<ğÀ…ÿŒ®şwÎ“_ú’ñãh  ½&&&\}ë ‘‘‘B?‘cnnÎÕÿªV«…ŞĞiü1ş€ zÀ-âÎ+òNıì¼"ßa1ş@ ]6::êêm<x°›ñªÕjÌÍÍ9À633SÈÍÀÆãh  G'º£ˆW:=k¼{Š¸Øøcü ôÀää¤"tÉÄÄDñ&¥–ÿtÍÜ£0ş€ ögttÔ¸.*Úmø¢oNí7E[dü1ş€ ztB û“æ"MHé®"í·0ş@ =àÑp&=€œÕüSŸ2ş`ü ìİøø¸"˜ôìÙÔƒ: š.ãñ4 ÃÃÃQ©T¢ËFFF
±·\.ÇÔÔ”ÚeÕjµû Œ?ÆĞ @¸ú¦öûaò¯öÆµ 8	°CE¸ò©P{ãñòÚ 4”A522¢=2::šûÏài"joü1ş@î$IZJ’D€ µßË$ÔK…4 Æµ‡²ˆf#Xïá
\‘^H¥ù2ş@ ÁU Ş9pà@ş'¡– i¾Œ?ÆĞ @¾¸ç<è“Pµ7ş@ N˜üh ÔŞøcü       4   € úÎúúº"ôÈÚÚZî?C³Ùt ÕŞøcü6 Y¶¤8	`ò£P{ãñŠ/É²w p 'VWWMBÙ³z½nüa ÇØ‡e í½÷ŞS„)ÂÕÏ"LBsÛ|­¬èñöCÀ@sHí÷Õ \¾ì@j¾Œ?j p`'ŠpõÓ µ7ş@ 9³¼¼¬=Òh4rÿHµ7ş@ NÀJí5 joüQ{Èk f`­­­¹ßF£0ï°¨7“ÿ¢<ÔøcüXÒ 0ğ®\¹¢]ö«_ıª0Ÿeá§?u@{Ğ 0şÀŞYÄÀ»zõª"¨ùŞ€…TÍı· æ €<±„£ûŠtÕs~~ŞívP ».Æãh  ÖÖÖ\ê¢«W¯jİs³Ùt ›“ÿ……BMš?ÆĞ @¸
×=/^,Ügšã¶KNŸ>müÁøûn ²,Uœœº¥ˆ·ß‹8)íWEÜtmü1ş@WeYê „ÛğİR¯×yûİ2 î˜ãB^-7ş Û4 °åüùóŠĞao¿ıva?ÛÉ^p€;ìôßıñãh  }®\¹âêP­®®ÆåË—ûùŠ¶9µßÔëõBïµ0ş@ =ráÂEèA¸Âyêå—è9yò¤ñã´ÃĞP£CC©JÀ¦‹/ÆúúºB´Ùêêê@lt<}út4›M¼Íêõzœ~õUãÆh†; pµµµøùÏ®m6(WßšÍ¦½ 0Wÿ?Æè& ÜäÂ…Öâ¶Ñ ]};uê”½ m4(Wÿ?ÆĞ @y¤cûâÕ·¯>ı´ß&ƒrõßøcün7 ©2À®\¹â*n\¼xq ¯¾-,,Äüü¼ ìÓéÓ§êê¿ñÇø]b lç­·Ş²!oVWWúêÛŸ?ÿ¼ÁûP¯×z?…ñÇø èÑ	ä­·ŞRˆ=:şü@¯e®×ëñçÏ?/{tòäÉ¾
nü1ş@'U*•JdÙ	¥€[-//Çğğp|ìcSŒ]¸páB,..|£\.ÇC?,»pêå—ã¥—^2şŒ?ĞI’¼XJÓ4U
Ø+I»³ººêQ†×ô+Ù»U¯×rã¯ñÇøİ’¦ij	ÜÅÚÚZüà?°w‡'_µºQ³ÙŒ/~áöìpò¯VÆãt vqbáÎ~ô£¹Zy‡‰-wö'_ş²»%Æãt±H•îlyyÙó¹ï`aa!–——b‹‹‹Şp_}úië¶?Æè¼FDÄPDDelìDDTÔî~^[[‹{ï½W1®óÖ[oÅ¿üË¿(Äš€f³Ÿ™UŒëüùóÏÇßüÍß(„ñÇø÷¿WVV^Ô À.½ûî»NÂ7|/\¸ ;töìYMÀM“ÿS§N)„ñÇøİÑ¸¾x""ş5Ÿ„WWW£Z­t\yÛcP¯×cîÑGº_}úiWş?Æè¦$9·²²òÊPDÄx¥òÅˆ¨©
ìÜòòrÔëõ¸÷Ş{cxxx >ûúúzÌÏÏÇ/ùKAØ£ÅÅÅ˜ŸŸÏÌÎF¹\¨ÏŞl6ãó?o¾ù¦ Œ?Ğİ ]YYyÅS€`Ÿ'áüàõä‰ÕÕÕøş÷¿oÃ]›š€/~áõä›z½Ÿ{ì1~?Æè¡kK€>ÓÊ»·¾¾o¿ıvş.\ˆÿøÇñşûï;ğmÒl6ãôéÓñ‘|¤ğo>õòËñ§ú§ñoÿöo¼ñÇø=Dü¬±²ò·×€Ç5 °wñË_ş2VWWc||¼p·ä×××ãŸşéŸbqq1Z­–Şf|ğA¼ùæ›Q¯×cêÁ·$¨ÙlÆÿø³?‹—^z)>øàÜøcüŞ5 ••ï]k f#bFY`®­ËñññB|¦z½?úÑâêÕ«p‡]ÛP.—cêÁñ™æççãO¾üeÏ°7ş do®¬¬üıµ`&"f•öo}}=êõzî¯Æ­®®Æ?şã?Æââb¬¯¯;°]Òl6c~~>÷wêõzüÉ—¿/½ôR4›MÖøcü>PŠx£±²ræú;  h£ååå¸páBîNÄëëëqîÜ¹øÉO~2P›ûÍââbœ:u*w@³ÙŒÿç/ÿ2şôOÿt 67Œ?IÄ›••3IDDmbâ‰,I¾¥,Ğ9“““qôèÑéËŸouu5.\¸ÿú¯ÿêŠ[:vìXœxê©¾}ö{½^S§NÅéW_uÅßøcü~m ²ìÓË—¿­€.›˜˜ˆûî»¯o&rW¯^óçÏÇ•+Wœ˜››‹cÇÇÜÜ\_ü<qò…¬ñ7ş ‡ÀãY’|WY {FFFâĞ¡C199ìúI·^¯»Ú–cÕj5fffâØñã13Óİg8,,,Äüü¼«ıÆãä­(•>›¦éÖ Zm6kµ~¨,ĞÛ“ñÁƒã{î‰J¥ÒÖï¿ººW®\‰«W¯ÆåË—tÚÌÌÌÄÔƒÆÔÔT[¿½^………XøéOc~~Ş¤ßøcü‚4 ÓY«uVY ?8p î¹çßüÍßŒÑÑÑ‘‘‘Üğõëëë±¶¶ëëëñŞ{ïÅ{ï½ÿñÿËËËñ«_ıÊ	wÀ”Ëå˜ššŠ©ŒêÇ?Õ‰‰(—ËQ­V£\.ß²¡¸Ùl~ø«^¯Gıòå¨¿óN,şâ±¸¸hÂoü1ş@q€‡Ò4=w­¨e­ÖÛÊ  …m îKÓ4-mısCI   ĞÉµ:røp¦&  PLK—.%¥'IÊ  …ôá\ÿ×@–i   `` û    ˜’$½¥H, €Â»~	Ğ’r  @ñ$Y–ŞÚ X  …ÔŠXÑ   À€(mó Ti   nÓ    ÅT*¥·6 CC©Ê  @!5nm "4   0@@C]   Òkÿ'¹şw>œ©  ËÒ¥KÎûKÛu  @!Ü0Ç¿¹h¨  H’Ü¡¸é_  ÅrCdÙŠ’  @q$7½ğ×   (¶¥í€›º   çîr ¡B  P CCwh ††Î©  JcûÀ   (šôúHnş·GY,«¨  ä^céÒ¥ñë£tË—Ø  Åp›÷|•vòE  @çÿY¶t×àv_  äOë6ïùºõ@©”*  ä_iGÀÆ†   
Ñ”Îİ½ğ.   (ŠÆİ ï  €BHÓôÜ]€4Mq›µB  @¾æÿ·ûÍÒm¿4IÎ©  äØ6÷¿màQ   oY–ılÇ€G @¾•vµÈ£@  çÀ­ İ¾ğ(P  È»ÛÎé“í¾úÈ‘#Ë‘eu €Üi,]º4~»QÚödYªn  Cwxªç¶@ñ3• €üÙî	@wl ¶Û4   ô·Ò^ì[ºÃŸÓ   @.;€í/æk    xvß ¤iÚˆ;Ü:   úP’œÛšËï®ˆˆH"ŞTA  ÈÑü?Ë–îôïïØ Ø  ¹sfï€}   /w¹ˆ¯  €bÙ{°µy@   yp—Àwm "l €ÜÌÿ³ìÜİ¾æ®@ìà›   } TºëÅû»7 CCgT  rá®s÷d'ßåÈ‘#Ë‘eõ €>•$éÒÒÒ}wû²Ò¾W–}OE  çÿYö³|İ / €>W*½Ö¾ â5 €¾vf'_”ìô»9|øíˆ¨©+  ô™®ÿØù€H"ì  €~œÿgÙ™~í ï  €>U*íøbıÎ€¡¡×T  úÒ™¶7 iš6’$9£¶  ĞG’äLš¦¶7 [ßÜ>   è§ùÿ.ßÙUÚå÷M‰  ”JgvÕ0ìöû{(  ô‰]<şóÃ~a×GÄ+*  ½—írùÏ€İŞb   :£T*½¶Û?“ìå/:räÈrdYEÉ  Gö°ü'b/w ""É²U  z8ÿßÅÛ÷İ X  =V*íé¢|²×¿¯väÈ³,›Uy  è²=.ÿ‰Øë€ˆˆ,{Så  óÿäù½şÙ½7 ¥ÒI¥ €8Óõ MÓF’$gÔ  º(IÎ¤išv½ØúËŸw   ›óÿd_/æMöûx'   tmö¿çÍ¿×”öı3x'   tgş¿Çgÿ·µ°  º¤TÚ÷ü}7 6 @ç%ßŞÏæß¶5 ›?ÍÀ  ĞQ¥Ò+íø6I»~o €I’sKKKµ¥hãå.   tdşŸ´íÁ;I;°#G¼YVsˆ   m³ÿ}?úóz¥öşlî  @?Ï±“vÿ€^  m›ı·õêD›ï Dx1  ´oşßş6m¿P«Õ*Y–µ   ö5ûoûÕÿˆÜØz1˜½   °¯ùgæÔI§~`O €=Ïş;rõ?¢w ®ëXşØ‘ €=Í¥;¶¢&éäîíÀ  °ëÙÇ®şGtğÀÖo/   ìj
İÙ•4m Ò4=“$É‡  v0ùøvš¦?—:ÿ)ì  €ÍÎK_AÓñ MÓ4‰ğr0  ¸ƒ­«ÿiî€­Næ¹H’†Ã
  ·›ı'i7®şGDuã/i4ïYöŸ]  ¸iş_*=Õéµÿş]İü`
  7ÏÈ;ûØÏ›•ºüá<  n˜"'Ÿíæß7ÔÍ¿¬Ñh¤ãccã1ãP 0ğ“ÿˆo§KK¯tóï,uıSÚ  ]İøÛÓ MÓFâİ   üü?y¾ı¼åïíÕ¶! €üG|;½t©'ÅK½ûÔÉ[
 ÀàÍş“F/–ş\3Ô«¿¸Ñh4¼  €›ÿGü÷tiéï{ø÷÷–¥@  Ìä?IÎ¤KKŸíåÏPêƒ*X
 À ÌşÑÃêõ`)  1ÿïñÒŸë~ş`)  ü÷ì©?7+õOU,  ˆ³ÿŞ¼ğ«ï€4MS/  xóÿŞ¼ğk;CıTœF£ñÏãccã1#*  ä]ñâÒÒÒ_öUCÒoEªÕj•,ËÎF–ÕD €ÜJ’tiié¾~û±Jıö¥iÚH’ä³ö  ãÉÿæœ¶õãåÑ   äzşß'üÌM°Õ,Ø  @Şd/.]ºô\7'ıkk?À#Ë¦E	 €¾×§ëş¯Wêçnk?Àçí   “ÿ~]÷Ÿ›`«	H“$ù¼D Ğßóÿä©~zŞÿv†òPÌF£‘%1+Z  ô›,âù¥¥¥ÿ™‡Ÿu(/Em¬¬œ»/‰˜1  úhòÿâ¥K—¾—Ÿ·”§â–J¥‘$çÄ €¾$i©Tz.Wsê<ı°×m
N¥ €^Oş“$ùlš¦\ıØy¬u­V›Şz<hEò  èÁä¿‘$ÉCyØô{³¡<Ö»Ñhüïñññ+‘eK  ]Ÿÿ—Jÿ%MÓ…<şìCy-z£Ñ8çÉ@  t[øS¨ bóÉ@š   º9ù¿téÒsyşCy?
 @—&ÿ¯\ºtéDŞ?GR”R;rä‡Y–ÍŠ&  mŸ4'É™tié³Eø,¥•Ï{G   ˜g‹$ù|a>N‘M­V«dYv6²¬&©  ´aòíYÿiQ>R©HÇgëEaŸõ¢0  Lş ØjRM   &ÿÒ h  0ù°@  €Éÿ€5 š   Lş¬Ğ  `ò?`€&   “ÿk 4  ˜üXpSpNÚ ~ò.I’‡iò?pÀõM@’$g¤ `PçşÉ™­+ÿûìƒ|à>üí$âü'  08²ˆW.]ºôÄ ~ş¡A>ø+++¯%1ë? €˜ü?éÒ¥ƒ\ƒ¡AAceåŒ&  ``&ÿÏzQØT«ÕÏ²ì[‘eÕ  (ÒŒ7i$IòTš¦ßVÀÍM@-Ë²F–ÕT  “ÿ4I’Ï§izN16•”à×¼+   P“ÿs[Oú1ù× Üµ	x(‰xQ5  ò)‹xeĞ^ğµSCJp«F£ñ~ceåïm ÈåäÿùK—.h4ï«†`wÀÊÊ™ñññŸEÄLDTT  %I#)•[ZZú¶bÜ¡LJpw6 ôıäÿÜÖfßT1îÌ€HÓ4]ZZºÏ¾  €ş“E¼h½ÿÎY´••¿_‰Í%AU €J’Fñß—.]zÎzÿ]”M	vÏ’  €OşSWı÷Æ =°$  w¶–ü<dò¿7– íÃÖ’ ¥ˆ˜O	 è¬Í§üü—¥¥¥“–üh z×4çÆÇÇ¿—dÙøV#  @ÛçşÉ™$IKÓtA5öYK%hŸZ­v"Ë²g#Ë*ª Ğ–™#É²çÓK—N*† _›€ZdÙ·²,›U €ıÌı“3‘$l­¿ /€»  {›ù»êßAö tH£ÑXÿ½  »™ûo­õ_Zú{ÕèP• ójµÚ[wjª pÛ™#Ù\îóšbt–; ]àIA  ÛË"^,•JŸOÓôœjt¡×R‚îòa €­‰èæ&ßçÓ4=£€Ah, uæo“oYÔ#– ƒèÃå>KKgT£Gı—ô^­V«E«õ\ñGª rÒé™ş nÛÌfYö-Ë‚ €‚Mü­ó× p—FÀş   ï3ÿtë±&ş 4 @Á'şÏ§iúmÅĞ    Š;ño$Yöb”J'Ó4m(ˆ   PÌ‰¿+ş ºÑD–}%Ë²iÕ  z3ï·¹W@/ÙhµğøP ÀÄÀ`5›ïH’ÏX t`Öo}¿€>nˆ,û£,ËfU Øß¼ßÕ~ yjj1kÓ0 °ëI–½éj¿€|7ÓÑj°D ØfÖm‰ÏWû5 ¯˜Vëñ,IşP3  -M"^1é× 0XÍÀtDÌF–ı¡= 0 ¿Í5ıß‹ˆ×Ò4MUDÀ`7•ˆ¸vwÀR! (†4‰ø^dÙ¹zÍš~4 Ü©!¨Åµ»Ó ÈÃÌ.i$YöZ”J?WùÑ Ğ–† Õš$ù¤·@?Ì÷“s‘eon]á?cÂ€N6•ˆ˜Í»Ÿ‰ˆš¦  :*M"Îl]İ?ç,éA@ÿ4­V-’ä“[Ë‡*ª ;%$",;g²€â4›{
jªÀ K·–ğ,E©”FDº5ÑO• En¦#¢r]sp$"jYDÍ ò=ËÚº’¿y5ÿ†I~D4\ÑG ·6•Ø¼KP‰Z$I-"lıo¸‹ @¥I’4¶&÷ˆXŠ,Kch¨a‚ ºÙ(lşªE«uíÿİĞ0$IÅ nœ%È²ÆÖ„¾Y–FÄÊuÿ?bh(Í«÷&öh  ÇMÃõ¿"66j['‚ÚÖ—]k ~ı5ñá‡ĞL ôTúëùûÖÄ}s¾öû+·üŞæÕù~™Ì£ öÓTÔ®ûÇš†ocãÆßûu³q³#·ÿ/6¹İ÷½­¬=/o«9²ÿ	ò'	×O¬ï<àÜéïZ¹í÷¸İŸÙ¼Ê¾íg°9ÚãÿÍNçtãƒö    IEND®B`‚


# icons.sh

#!/bin/bash

# General Icons
LOADING=ô€–‡
APPLE=ô€£º
PREFERENCES=ô€º½
ACTIVITY=ô€’“
LOCK=ô€’³
BELL=ô€‹š
BELL_DOT=ô€—

# Git Icons
GIT_ISSUE=ô€·
GIT_DISCUSSION=ô€’¤
GIT_PULL_REQUEST=ô€™¡
GIT_COMMIT=ô€¡š
GIT_INDICATOR=ô€‚“

# Spotify Icons
SPOTIFY_BACK=ô€Š
SPOTIFY_PLAY_PAUSE=ô€Šˆ
SPOTIFY_NEXT=ô€Š
SPOTIFY_SHUFFLE=ô€Š
SPOTIFY_REPEAT=ô€Š

# Yabai Icons
YABAI_STACK=ô€­
YABAI_FULLSCREEN_ZOOM=ô€œ
YABAI_PARENT_ZOOM=ô€¥ƒ
YABAI_FLOAT=ô€¢Œ
YABAI_GRID=ô€§

# Battery Icons
BATTERY_100=ô€›¨
BATTERY_75=ô€º¸
BATTERY_50=ô€º¶
BATTERY_25=ô€›©
BATTERY_0=ô€›ª
BATTERY_CHARGING=ô€¢‹

# Volume Icons
VOLUME_100=ô€Š©
VOLUME_66=ô€Š§
VOLUME_33=ô€Š¥
VOLUME_10=ô€Š¡
VOLUME_0=ô€Š£

# WiFi Icons
WIFI_CONNECTED=ô€™‡
WIFI_DISCONNECTED=ô€™ˆ

# Tailscale Icons
TAILSCALE=ô€†ª

# Bluetooth Icons
BLUETOOTH_ON=ó°‚¯
BLUETOOTH_OFF=ó°‚²
BLUETOOTH_CONNECTED=ô€‚



# items/activity.sh

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



# items/apple.sh

#!/bin/bash

POPUP_OFF="sketchybar --set apple.logo popup.drawing=off"
POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

apple_logo=(
  icon=$APPLE
  icon.font="$FONT:Black:16.0"
  icon.color=$WHITE
  padding_right=15
  label.drawing=off
  click_script="$POPUP_CLICK_SCRIPT"
)

apple_prefs=(
  icon=$PREFERENCES
  label="Preferences"
  click_script="open -a 'System Preferences'; $POPUP_OFF"
)

apple_activity=(
  icon=$ACTIVITY
  label="Activity"
  click_script="open -a 'Activity Monitor'; $POPUP_OFF"
)

apple_lock=(
  icon=$LOCK
  label="Lock Screen"
  click_script="pmset displaysleepnow; $POPUP_OFF"
)

sketchybar --add item apple.logo left                  \
           --set apple.logo "${apple_logo[@]}"         \
                                                       \
           --add item apple.prefs popup.apple.logo     \
           --set apple.prefs "${apple_prefs[@]}"       \
                                                       \
           --add item apple.activity popup.apple.logo  \
           --set apple.activity "${apple_activity[@]}" \
                                                       \
           --add item apple.lock popup.apple.logo      \
           --set apple.lock "${apple_lock[@]}"



# items/battery.sh

#!/bin/bash

battery=(
  script="$PLUGIN_DIR/battery.sh"
  icon.font="$FONT:Regular:19.0"
  padding_right=5
  padding_left=0
  label.drawing=off
  drawing=when_shown
  update_freq=120
  updates=when_shown
)

sketchybar --add item battery right      \
           --set battery "${battery[@]}" \
           --subscribe battery power_source_change system_woke




# items/bluetooth.sh

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



# items/brew.sh

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



# items/calendar.sh

#!/bin/bash

calendar=(
  icon=cal
  icon.font="$FONT:Black:12.0"
  icon.padding_right=0
  label.width=45
  label.align=right
  padding_left=5
  update_freq=30
  script="$PLUGIN_DIR/calendar.sh"
  click_script="$PLUGIN_DIR/zen.sh"
)

sketchybar --add item calendar right       \
           --set calendar "${calendar[@]}" \
           --subscribe calendar system_woke



# items/cpu.sh

#!/bin/bash

cpu_top=(
  label.font="$FONT:Semibold:7"
  label=CPU
  icon.drawing=off
  width=0
  padding_right=15
  y_offset=6
)

cpu_percent=(
  label.font="$FONT:Heavy:12"
  label=CPU
  y_offset=-4
  padding_right=15
  width=55
  icon.drawing=off
  update_freq=2
  mach_helper="$HELPER"
)

cpu_sys=(
  width=0
  graph.color=$RED
  graph.fill_color=$RED
  label.drawing=off
  icon.drawing=off
  background.height=30
  background.drawing=on
  background.color=$TRANSPARENT
)

cpu_user=(
  graph.color=$BLUE
  label.drawing=off
  icon.drawing=off
  background.height=30
  background.drawing=on
  background.color=$TRANSPARENT
)

sketchybar --add item cpu.top right              \
           --set cpu.top "${cpu_top[@]}"         \
                                                 \
           --add item cpu.percent right          \
           --set cpu.percent "${cpu_percent[@]}" \
                                                 \
           --add graph cpu.sys right 75          \
           --set cpu.sys "${cpu_sys[@]}"         \
                                                 \
           --add graph cpu.user right 75         \
           --set cpu.user "${cpu_user[@]}"



# items/front_app.sh

#!/bin/bash

front_app=(
  script="$PLUGIN_DIR/front_app.sh"
  icon.background.drawing=on
  padding_left=0
  label.color=$WHITE
  label.font="$FONT:Black:12.0"
  associated_display=active
)

sketchybar --add event window_focus            \
           --add event windows_on_spaces       \
           --add item front_app left           \
           --set front_app "${front_app[@]}"   \
           --subscribe front_app front_app_switched




# items/github.sh

#!/bin/bash

POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

github_bell=(
    update_freq=180
    icon.font="$FONT:Bold:15.0"
    icon=$BELL
    icon.color=$BLUE
    label=$LOADING
    label.highlight_color=$BLUE
    popup.align=right
    script="$PLUGIN_DIR/github.sh"
    click_script="$POPUP_CLICK_SCRIPT"
)

github_template=(
    drawing=off
    background.corner_radius=12
#    padding_left=7
    padding_right=0
    icon.background.height=2
    icon.background.y_offset=-12
)

sketchybar --add item github.bell right \
    --set github.bell "${github_bell[@]}" \
    --subscribe github.bell mouse.entered \
    mouse.exited \
    mouse.exited.global \
    \
    --add item github.template popup.github.bell \
    --set github.template "${github_template[@]}"



# items/spaces.sh

#!/bin/bash

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15")

# Destroy space on right click, focus space on left click.
# New space by left clicking separator (>)

sid=0
spaces=()
for i in "${!SPACE_ICONS[@]}"
do
  sid=$(($i+1))

  space=(
    associated_space=$sid
    icon=${SPACE_ICONS[i]}
    icon.padding_left=10
    icon.padding_right=15
    padding_left=2
    padding_right=2
    icon.highlight_color=$RED
    icon.background.drawing=on
    label.drawing=off
    script="$PLUGIN_DIR/space.sh"
  )

  sketchybar --add space space.$sid left    \
             --set space.$sid "${space[@]}" \
             --subscribe space.$sid mouse.clicked
done

spaces=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
  background.border_width=2
  background.drawing=on
)

separator=(
  icon=ô€†Š
  icon.font="$FONT:Heavy:16.0"
  padding_left=15
  padding_right=15
  label.drawing=off
  associated_display=active
  click_script='yabai -m space --create && sketchybar --trigger space_change'
  icon.color=$WHITE
)

sketchybar --add bracket spaces '/space\..*/' \
           --set spaces "${spaces[@]}"        \
                                              \
           --add item separator left          \
           --set separator "${separator[@]}"



# items/spotify.sh

#!/bin/bash

SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"
POPUP_SCRIPT="sketchybar -m --set spotify.anchor popup.drawing=toggle"

spotify_anchor=(
  script="$PLUGIN_DIR/spotify.sh"
  click_script="$POPUP_SCRIPT"
  popup.horizontal=on
  popup.align=center
  popup.height=150
  icon=ô’
  icon.font="$FONT:Regular:25.0"
  label.drawing=off
  drawing=off
  y_offset=2
)

spotify_cover=(
  script="$PLUGIN_DIR/spotify.sh"
  click_script="open -a 'Spotify'; $POPUP_SCRIPT"
  label.drawing=off
  icon.drawing=off
  padding_left=12
  padding_right=10
  background.image.scale=0.2
  background.image.drawing=on
  background.drawing=on
)

spotify_title=(
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  label.font="$FONT:Heavy:15.0"
  y_offset=55
)

spotify_artist=(
  icon.drawing=off
  y_offset=30
  padding_left=0
  padding_right=0
  width=0
)

spotify_album=(
  icon.drawing=off
  padding_left=0
  padding_right=0
  y_offset=15
  width=0
)

spotify_state=(
  icon.drawing=on
  icon.font="$FONT:Light Italic:10.0"
  icon.width=35
  icon="00:00"
  label.drawing=on
  label.font="$FONT:Light Italic:10.0"
  label.width=35
  label="00:00"
  padding_left=0
  padding_right=0
  y_offset=-15
  width=0
  slider.background.height=6
  slider.background.corner_radius=1
  slider.background.color=$GREY
  slider.highlight_color=$GREEN
  slider.percentage=40
  slider.width=115
  script="$PLUGIN_DIR/spotify.sh"
  update_freq=1
  updates=when_shown
)

spotify_shuffle=(
  icon=ô€Š
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$BLACK
  icon.highlight_color=$GREY
  label.drawing=off
  script="$PLUGIN_DIR/spotify.sh"
  y_offset=-45
)

spotify_back=(
  icon=ô€Š
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$BLACK
  script="$PLUGIN_DIR/spotify.sh"
  label.drawing=off
  y_offset=-45
)

spotify_play=(
  icon=ô€Š”
  background.height=40
  background.corner_radius=20
  width=40
  align=center
  background.color=$POPUP_BACKGROUND_COLOR
  background.border_color=$WHITE
  background.border_width=0
  background.drawing=on
  icon.padding_left=4
  icon.padding_right=5
  icon.color=$WHITE
  updates=on
  label.drawing=off
  script="$PLUGIN_DIR/spotify.sh"
  y_offset=-45
)

spotify_next=(
  icon=ô€Š
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$BLACK
  label.drawing=off
  script="$PLUGIN_DIR/spotify.sh"
  y_offset=-45
)

spotify_repeat=(
  icon=ô€Š
  icon.highlight_color=$GREY
  icon.padding_left=5
  icon.padding_right=10
  icon.color=$BLACK
  label.drawing=off
  script="$PLUGIN_DIR/spotify.sh"
  y_offset=-45
)

spotify_controls=(
  background.color=$GREEN
  background.corner_radius=11
  background.drawing=on
  y_offset=-45
)

sketchybar --add event spotify_change $SPOTIFY_EVENT             \
           --add item spotify.anchor center                      \
           --set spotify.anchor "${spotify_anchor[@]}"           \
           --subscribe spotify.anchor mouse.entered mouse.exited \
                                      mouse.exited.global        \
                                                                 \
           --add item spotify.cover popup.spotify.anchor         \
           --set spotify.cover "${spotify_cover[@]}"             \
                                                                 \
           --add item spotify.title popup.spotify.anchor         \
           --set spotify.title "${spotify_title[@]}"             \
                                                                 \
           --add item spotify.artist popup.spotify.anchor        \
           --set spotify.artist "${spotify_artist[@]}"           \
                                                                 \
           --add item spotify.album popup.spotify.anchor         \
           --set spotify.album "${spotify_album[@]}"             \
                                                                 \
           --add slider spotify.state popup.spotify.anchor       \
           --set spotify.state "${spotify_state[@]}"             \
           --subscribe spotify.state mouse.clicked               \
                                                                 \
           --add item spotify.shuffle popup.spotify.anchor       \
           --set spotify.shuffle "${spotify_shuffle[@]}"         \
           --subscribe spotify.shuffle mouse.clicked             \
                                                                 \
           --add item spotify.back popup.spotify.anchor          \
           --set spotify.back "${spotify_back[@]}"               \
           --subscribe spotify.back mouse.clicked                \
                                                                 \
           --add item spotify.play popup.spotify.anchor          \
           --set spotify.play "${spotify_play[@]}"               \
           --subscribe spotify.play mouse.clicked spotify_change \
                                                                 \
           --add item spotify.next popup.spotify.anchor          \
           --set spotify.next "${spotify_next[@]}"               \
           --subscribe spotify.next mouse.clicked                \
                                                                 \
           --add item spotify.repeat popup.spotify.anchor        \
           --set spotify.repeat "${spotify_repeat[@]}"           \
           --subscribe spotify.repeat  mouse.clicked             \
                                                                 \
           --add item spotify.spacer popup.spotify.anchor        \
           --set spotify.spacer width=5                          \
                                                                 \
           --add bracket spotify.controls spotify.shuffle        \
                                          spotify.back           \
                                          spotify.play           \
                                          spotify.next           \
                                          spotify.repeat         \
           --set spotify.controls "${spotify_controls[@]}"       \



# items/tailscale.sh

#!/bin/bash

tailscale=(
    icon.drawing=off
    label.drawing=off
    background.image="$HOME/.config/sketchybar/icon/tailscale.png"
    background.image.scale=0.03
    background.color=0x00000000
    # padding_right=5
    padding_left=5
    update_freq=10
    popup.align=right
    script="$PLUGIN_DIR/tailscale.sh"
    click_script="$PLUGIN_DIR/tailscale.sh"
)

tailscale_server=(
    icon=â—
    icon.font="SF Pro:Regular:12.0"
    icon.color=$GREY
    label.color=$WHITE
    label.font="SF Pro:Regular:13.0"
    padding_left=10
    padding_right=10
)

sketchybar --add item tailscale right \
           --set tailscale "${tailscale[@]}" \
           --subscribe tailscale mouse.clicked mouse.entered mouse.exited mouse.exited.global system_woke \
           \
           --add item tailscale.server1 popup.tailscale \
           --set tailscale.server1 "${tailscale_server[@]}" label="headscale.kushvinth.com" \
           \
           --add item tailscale.server2 popup.tailscale \
           --set tailscale.server2 "${tailscale_server[@]}" label="headscale.pranavos.com"


# items/volume.sh

#!/bin/bash

volume_slider=(
  script="$PLUGIN_DIR/volume.sh"
  updates=on
  label.drawing=off
  icon.drawing=off
  slider.highlight_color=$BLUE
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color=$BACKGROUND_2
  slider.knob=ô€€
  slider.knob.drawing=off
)

volume_icon=(
  click_script="$PLUGIN_DIR/volume_click.sh"
  padding_left=10
  padding_right=0
  icon=$VOLUME_100
  icon.width=0
  icon.align=left
  icon.color=$GREY
  icon.font="$FONT:Regular:14.0"
  label.width=25
  label.align=left
  label.font="$FONT:Regular:14.0"
)

status_bracket=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
  background.border_width=2
)

sketchybar --add slider volume right            \
           --set volume "${volume_slider[@]}"   \
           --subscribe volume volume_change     \
                              mouse.clicked     \
                              mouse.entered     \
                              mouse.exited      \
                                                \
           --add item volume_icon right         \
           --set volume_icon "${volume_icon[@]}"

sketchybar --add bracket status wifi tailscale battery brew github.bell activity bluetooth volume_icon \
           --set status "${status_bracket[@]}"




# items/wifi.sh

#!/bin/bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/icons.sh"

wifi=(
    #padding_left=5
    label.width=5
    icon="$WIFI_DISCONNECTED"
    script="$PLUGIN_DIR/wifi.sh"
)

sketchybar --add item wifi right \
    --set wifi "${wifi[@]}" \
    --subscribe wifi wifi_change mouse.clicked




# plugins/activity.sh

#!/bin/bash

DEBUG_LOG="$HOME/.config/sketchybar/debug_activity.log"
CACHE_FILE="/tmp/sketchybar-activity.time"
CACHE_TTL_SECONDS=120
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
WAKATIME_CFG="$HOME/.wakatime.cfg"

load_local_env() {
  if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    set +a
  fi
}

cfg_value() {
  local key="$1"
  [ -f "$WAKATIME_CFG" ] || return 0
  grep -E "^[[:space:]]*${key}[[:space:]]*=" "$WAKATIME_CFG" 2>/dev/null | tail -n1 | sed -E "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//"
}

load_local_env

popup() {
  sketchybar --set "$NAME" popup.drawing=$1
}

update() {
  mkdir -p "$(dirname "$CACHE_FILE")"

  now=$(date +%s)
  cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  cache_age=$((now - cache_mtime))

  if [ -f "$CACHE_FILE" ] && [ "$cache_age" -lt "$CACHE_TTL_SECONDS" ]; then
    cached_value=$(cat "$CACHE_FILE" 2>/dev/null)
    [ -z "$cached_value" ] && cached_value="N/A"
    sketchybar --set activity.time label="$cached_value"
    return
  fi

  if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    if [ -f "$CACHE_FILE" ]; then
      cached_value=$(cat "$CACHE_FILE" 2>/dev/null)
      [ -z "$cached_value" ] && cached_value="N/A"
      sketchybar --set activity.time label="$cached_value"
    else
      sketchybar --set activity.time label="N/A"
    fi
    return
  fi

  cfg_api_url="$(cfg_value api_url)"
  cfg_api_key="$(cfg_value api_key)"

  api_url="${WAKAPI_URL:-$cfg_api_url}"
  api_key="${WAKAPI_API_KEY:-$cfg_api_key}"

  if [ -z "$api_url" ]; then
    api_url="https://wakapi.kushvinth.com"
  fi

  api_url="${api_url%/}"
  if [[ "$api_url" == */api ]]; then
    api_url="${api_url%/api}"
  fi

  if [ -z "$api_key" ]; then
    if [ -f "$CACHE_FILE" ]; then
      time_data=$(cat "$CACHE_FILE" 2>/dev/null)
      [ -z "$time_data" ] && time_data="N/A"
    else
      time_data="N/A"
    fi
    sketchybar --set activity.time label="$time_data"
    return
  fi
  time_data=$(curl -fsS "${api_url}/api/v1/users/current/stats/today?api_key=${api_key}" 2>/dev/null | jq -r '.data.human_readable_total // empty' 2>/dev/null)

  if [ -n "$time_data" ]; then
    printf '%s' "$time_data" > "$CACHE_FILE"
  elif [ -f "$CACHE_FILE" ]; then
    time_data=$(cat "$CACHE_FILE" 2>/dev/null)
  else
    time_data="N/A"
  fi

  sketchybar --set activity.time label="$time_data"
}

click() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - click called" >> "$DEBUG_LOG"
  open "https://wakapi.kushvinth.com/"
}

case "$SENDER" in
  "routine" | "forced")
    update
    ;;
  "mouse.entered")
    update
    popup on
    ;;
  "mouse.exited" | "mouse.exited.global")
    popup off
    ;;
  "mouse.clicked")
    click
    ;;
esac



# plugins/battery.sh

#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

DRAWING=on
COLOR=$WHITE
case ${PERCENTAGE} in
  9[0-9]|100) ICON=$BATTERY_100
  ;;
  [6-8][0-9]) ICON=$BATTERY_75
  ;;
  [3-5][0-9]) ICON=$BATTERY_50
  ;;
  [1-2][0-9]) ICON=$BATTERY_25; COLOR=$ORANGE
  ;;
  *) ICON=$BATTERY_0; COLOR=$RED
  ;;
esac

if [[ $CHARGING != "" ]]; then
  ICON=$BATTERY_CHARGING
fi

sketchybar --set $NAME drawing=$DRAWING icon="$ICON" icon.color=$COLOR



# plugins/bluetooth.sh

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



# plugins/brew.sh

#!/bin/bash
unset ZDOTDIR
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
source "$HOME/.config/sketchybar/colors.sh"

# Get outdated count using wc -l (simpler and more reliable)
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
if ! command -v brew >/dev/null 2>&1; then
    sketchybar --set "$NAME" icon.color="$RED" label="N/A"
    exit 0
fi

BREW_COUNT=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
if [ "$BREW_COUNT" -ge 30 ]; then
    COLOR=$RED
elif [ "$BREW_COUNT" -ge 10 ]; then
    COLOR=$ORANGE
elif [ "$BREW_COUNT" -ge 1 ]; then
    COLOR=$YELLOW
else
    COLOR=$GREEN
    BREW_COUNT=ô€†…
fi

sketchybar --set "$NAME" icon.color="$COLOR" label="$BREW_COUNT"



# plugins/brew_click.sh

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



# plugins/calendar.sh

#!/bin/bash

sketchybar --set $NAME icon="$(date '+%a %d. %b')" label="$(date '+%H:%M')"



# plugins/front_app.sh

#!/bin/bash

if [ "$SENDER" = "front_app_switched" ]; then
  # Set the app name and app icon and then animate a bounce for the icon size
  sketchybar --set $NAME label="$INFO" icon.background.image="app.$INFO" \
             --animate sin 10 \
             --set $NAME icon.background.image.scale=0.8 \
             --set $NAME icon.background.image.scale=0.8
fi



# plugins/github.sh

#!/bin/bash

update() {
    source "$HOME/.config/sketchybar/colors.sh"
    source "$HOME/.config/sketchybar/icons.sh"

    NOTIFICATIONS="$(gh api /notifications)"
    COUNT="$(echo "$NOTIFICATIONS" | jq 'length')"
    args=()
    if [ "$NOTIFICATIONS" = "[]" ]; then
        args+=(--set $NAME icon=$BELL label="0")
    else
        args+=(--set $NAME icon=$BELL_DOT label="$COUNT")
    fi

    PREV_COUNT=$(sketchybar --query github.bell | jq -r .label.value)
    # For sound to play around with:
    # afplay /System/Library/Sounds/Morse.aiff

    args+=(--remove '/github.notification\.*/')

    COUNTER=0
    COLOR=$BLUE
    args+=(--set github.bell icon.color=$COLOR)

    while read -r repo url type title; do
        COUNTER=$((COUNTER + 1))
        IMPORTANT="$(echo "$title" | egrep -i "(deprecat|break|broke)")"
        COLOR=$BLUE
        PADDING=0

        if [ "${repo}" = "" ] && [ "${title}" = "" ]; then
            repo="Note"
            title="No new notifications"
        fi
        case "${type}" in
        "'Issue'")
            COLOR=$GREEN
            ICON=$GIT_ISSUE
            URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" | jq .html_url)"
            ;;
        "'Discussion'")
            COLOR=$WHITE
            ICON=$GIT_DISCUSSION
            URL="https://www.github.com/notifications"
            ;;
        "'PullRequest'")
            COLOR=$MAGENTA
            ICON=$GIT_PULL_REQUEST
            URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" | jq .html_url)"
            ;;
        "'Commit'")
            COLOR=$WHITE
            ICON=$GIT_COMMIT
            URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" | jq .html_url)"
            ;;
        esac

        if [ "$IMPORTANT" != "" ]; then
            COLOR=$RED
            ICON=ô€
            args+=(--set github.bell icon.color=$COLOR)
        fi

        notification=(
            label="$(echo "$title" | sed -e "s/^'//" -e "s/'$//")"
            icon="$ICON $(echo "$repo" | sed -e "s/^'//" -e "s/'$//"):"
            icon.padding_left="$PADDING"
            label.padding_right="$PADDING"
            icon.color=$COLOR
            position=popup.github.bell
            icon.background.color=$COLOR
            drawing=on
            click_script="open $URL; sketchybar --set github.bell popup.drawing=off"
        )

        args+=(--clone github.notification.$COUNTER github.template
            --set github.notification.$COUNTER "${notification[@]}")
    done <<<"$(echo "$NOTIFICATIONS" | jq -r '.[] | [.repository.name, .subject.latest_comment_url, .subject.type, .subject.title] | @sh')"

    sketchybar -m "${args[@]}" >/dev/null

    if [ $COUNT -gt $PREV_COUNT ] 2>/dev/null || [ "$SENDER" = "forced" ]; then
        sketchybar --animate tanh 15 --set github.bell label.y_offset=5 label.y_offset=0
    fi
}

popup() {
    sketchybar --set $NAME popup.drawing=$1
}

case "$SENDER" in
"routine" | "forced")
    update
    ;;
"mouse.entered")
    popup on
    ;;
"mouse.exited" | "mouse.exited.global")
    popup off
    ;;
"mouse.clicked")
    popup toggle
    ;;
esac



# plugins/icon_map.sh

case $@ in
"Brave Browser")
  icon_result=":brave_browser:"
  ;;
"Keyboard Maestro")
  icon_result=":keyboard_maestro:"
  ;;
"Min")
  icon_result=":min_browser:"
  ;;
"Final Cut Pro")
  icon_result=":final_cut_pro:"
  ;;
"FaceTime")
  icon_result=":face_time:"
  ;;
"Affinity Publisher")
  icon_result=":affinity_publisher:"
  ;;
"Messages" | "Nachrichten")
  icon_result=":messages:"
  ;;
"Tweetbot" | "Twitter")
  icon_result=":twitter:"
  ;;
"ClickUp")
  icon_result=":click_up:"
  ;;
"KeePassXC")
  icon_result=":kee_pass_x_c:"
  ;;
"Microsoft Edge")
  icon_result=":microsoft_edge:"
  ;;
"VLC")
  icon_result=":vlc:"
  ;;
"Emacs")
  icon_result=":emacs:"
  ;;
"Thunderbird")
  icon_result=":thunderbird:"
  ;;
"Notes")
  icon_result=":notes:"
  ;;
"Caprine")
  icon_result=":caprine:"
  ;;
"Zulip")
  icon_result=":zulip:"
  ;;
"Spark")
  icon_result=":spark:"
  ;;
"Microsoft To Do" | "Things")
  icon_result=":things:"
  ;;
"DEVONthink 3")
  icon_result=":devonthink3:"
  ;;
"GitHub Desktop")
  icon_result=":git_hub:"
  ;;
"App Store")
  icon_result=":app_store:"
  ;;
"Chromium" | "Google Chrome" | "Google Chrome Canary")
  icon_result=":google_chrome:"
  ;;
"zoom.us")
  icon_result=":zoom:"
  ;;
"MoneyMoney")
  icon_result=":bank:"
  ;;
"Color Picker")
  icon_result=":color_picker:"
  ;;
"Microsoft Word")
  icon_result=":microsoft_word:"
  ;;
"Microsoft Teams")
  icon_result=":microsoft_teams:"
  ;;
"Iris")
  icon_result=":iris:"
  ;;
"WebStorm")
  icon_result=":web_storm:"
  ;;
"Neovide" | "MacVim" | "Vim" | "VimR")
  icon_result=":vim:"
  ;;
"Sublime Text")
  icon_result=":sublime_text:"
  ;;
"PomoDone App")
  icon_result=":pomodone:"
  ;;
"Setapp")
  icon_result=":setapp:"
  ;;
"qutebrowser")
  icon_result=":qute_browser:"
  ;;
"Mattermost")
  icon_result=":mattermost:"
  ;;
"Notability")
  icon_result=":notability:"
  ;;
"WhatsApp")
  icon_result=":whats_app:"
  ;;
"OBS")
  icon_result=":obsstudio:"
  ;;
"Parallels Desktop")
  icon_result=":parallels:"
  ;;
"VMware Fusion")
  icon_result=":vmware_fusion:"
  ;;
"Pine")
  icon_result=":pine:"
  ;;
"Microsoft Excel")
  icon_result=":microsoft_excel:"
  ;;
"Microsoft PowerPoint")
  icon_result=":microsoft_power_point:"
  ;;
"Matlab")
  icon_result=":matlab:"
  ;;
"Numbers")
  icon_result=":numbers:"
  ;;
"Default")
  icon_result=":default:"
  ;;
"Element")
  icon_result=":element:"
  ;;
"Bear")
  icon_result=":bear:"
  ;;
"TeamSpeak 3")
  icon_result=":team_speak:"
  ;;
"Airmail")
  icon_result=":airmail:"
  ;;
"Firefox Developer Edition" | "Firefox Nightly")
  icon_result=":firefox_developer_edition:"
  ;;
"Trello")
  icon_result=":trello:"
  ;;
"TickTick")
  icon_result=":tick_tick:"
  ;;
"Notion")
  icon_result=":notion:"
  ;;
"Live")
  icon_result=":ableton:"
  ;;
"Evernote Legacy")
  icon_result=":evernote_legacy:"
  ;;
"Calendar" | "Fantastical")
  icon_result=":calendar:"
  ;;
"Android Studio")
  icon_result=":android_studio:"
  ;;
"Xcode")
  icon_result=":xcode:"
  ;;
"Slack")
  icon_result=":slack:"
  ;;
"Sequel Pro")
  icon_result=":sequel_pro:"
  ;;
"Bitwarden")
  icon_result=":bit_warden:"
  ;;
"System Preferences" | "System Settings")
  icon_result=":gear:"
  ;;
"Discord" | "Discord Canary" | "Discord PTB")
  icon_result=":discord:"
  ;;
"Vivaldi")
  icon_result=":vivaldi:"
  ;;
"Firefox")
  icon_result=":firefox:"
  ;;
"Skype")
  icon_result=":skype:"
  ;;
"Dropbox")
  icon_result=":dropbox:"
  ;;
"å¾®ä¿¡")
  icon_result=":wechat:"
  ;;
"Typora")
  icon_result=":text:"
  ;;
"Blender")
  icon_result=":blender:"
  ;;
"Canary Mail" | "HEY" | "Mail" | "Mailspring" | "MailMate" | "é‚®ä»¶" | "Outlook")
  icon_result=":mail:"
  ;;
"Safari" | "Safari Technology Preview")
  icon_result=":safari:"
  ;;
"Telegram")
  icon_result=":telegram:"
  ;;
"Keynote")
  icon_result=":keynote:"
  ;;
"Reeder")
  icon_result=":reeder5:"
  ;;
"Spotify")
  icon_result=":spotify:"
  ;;
"MAMP" | "MAMP PRO")
  icon_result=":mamp:"
  ;;
"Figma")
  icon_result=":figma:"
  ;;
"Joplin")
  icon_result=":joplin:"
  ;;
"Spotlight")
  icon_result=":spotlight:"
  ;;
"Music")
  icon_result=":music:"
  ;;
"Insomnia")
  icon_result=":insomnia:"
  ;;
"TIDAL")
  icon_result=":tidal:"
  ;;
"Alfred")
  icon_result=":alfred:"
  ;;
"Pages")
  icon_result=":pages:"
  ;;
"Folx")
  icon_result=":folx:"
  ;;
"Android Messages")
  icon_result=":android_messages:"
  ;;
"mpv")
  icon_result=":mpv:"
  ;;
"ç½‘æ˜“äº‘éŸ³ä¹")
  icon_result=":netease_music:"
  ;;
"Transmit")
  icon_result=":transmit:"
  ;;
"Pi-hole Remote")
  icon_result=":pihole:"
  ;;
"Nova")
  icon_result=":nova:"
  ;;
"Affinity Designer")
  icon_result=":affinity_designer:"
  ;;
"IntelliJ IDEA")
  icon_result=":idea:"
  ;;
"Drafts")
  icon_result=":drafts:"
  ;;
"Audacity")
  icon_result=":audacity:"
  ;;
"Affinity Photo")
  icon_result=":affinity_photo:"
  ;;
"Atom")
  icon_result=":atom:"
  ;;
"Obsidian")
  icon_result=":obsidian:"
  ;;
"CleanMyMac X")
  icon_result=":desktop:"
  ;;
"Zotero")
  icon_result=":zotero:"
  ;;
"Todoist")
  icon_result=":todoist:"
  ;;
"LibreWolf")
  icon_result=":libre_wolf:"
  ;;
"Grammarly Editor")
  icon_result=":grammarly:"
  ;;
"OmniFocus")
  icon_result=":omni_focus:"
  ;;
"Reminders")
  icon_result=":reminders:"
  ;;
"Preview" | "Skim" | "zathura")
  icon_result=":pdf:"
  ;;
"1Password 7")
  icon_result=":one_password:"
  ;;
"Code" | "Code - Insiders")
  icon_result=":code:"
  ;;
"VSCodium")
  icon_result=":vscodium:"
  ;;
"Tower")
  icon_result=":tower:"
  ;;
"Calibre")
  icon_result=":book:"
  ;;
"Finder" | "è®¿è¾¾")
  icon_result=":finder:"
  ;;
"Linear")
  icon_result=":linear:"
  ;;
"League of Legends")
  icon_result=":league_of_legends:"
  ;;
"Zeplin")
  icon_result=":zeplin:"
  ;;
"Signal")
  icon_result=":signal:"
  ;;
"Podcasts")
  icon_result=":podcasts:"
  ;;
"Alacritty" | "Hyper" | "iTerm2" | "kitty" | "Terminal" | "WezTerm")
  icon_result=":terminal:"
  ;;
"Tor Browser")
  icon_result=":tor_browser:"
  ;;
"Kakoune")
  icon_result=":kakoune:"
  ;;
"GrandTotal" | "Receipts")
  icon_result=":dollar:"
  ;;
"Sketch")
  icon_result=":sketch:"
  ;;
"Sequel Ace")
  icon_result=":sequel_ace:"
  ;;
*)
  icon_result=":default:"
  ;;
esac
echo $icon_result



# plugins/space.sh

#!/bin/bash

update() {
  WIDTH="dynamic"
  if [ "$SELECTED" = "true" ]; then
    WIDTH="0"
  fi

  # Get the app running in this space
  SPACE_APP=$(yabai -m query --windows --space $SID | jq -r '.[0].app' 2>/dev/null)
  
  if [ -n "$SPACE_APP" ] && [ "$SPACE_APP" != "null" ]; then
    sketchybar --animate tanh 20 \
               --set $NAME icon.highlight=$SELECTED \
                           label.width=$WIDTH \
                           icon.background.image="app.$SPACE_APP" \
                           icon.background.image.scale=0.8
  else
    sketchybar --animate tanh 20 \
               --set $NAME icon.highlight=$SELECTED \
                           label.width=$WIDTH \
                           icon.background.image="" \
                           icon.background.image.scale=0.8
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



# plugins/spotify.sh

#!/bin/bash

next ()
{
  osascript -e 'tell application "Spotify" to play next track'
}

back () 
{
  osascript -e 'tell application "Spotify" to play previous track'
}

play () 
{
  osascript -e 'tell application "Spotify" to playpause'
}

repeat () 
{
  REPEAT=$(osascript -e 'tell application "Spotify" to get repeating')
  if [ "$REPEAT" = "false" ]; then
    sketchybar -m --set spotify.repeat icon.highlight=on
    osascript -e 'tell application "Spotify" to set repeating to true'
  else 
    sketchybar -m --set spotify.repeat icon.highlight=off
    osascript -e 'tell application "Spotify" to set repeating to false'
  fi
}

shuffle () 
{
  SHUFFLE=$(osascript -e 'tell application "Spotify" to get shuffling')
  if [ "$SHUFFLE" = "false" ]; then
    sketchybar -m --set spotify.shuffle icon.highlight=on
    osascript -e 'tell application "Spotify" to set shuffling to true'
  else 
    sketchybar -m --set spotify.shuffle icon.highlight=off
    osascript -e 'tell application "Spotify" to set shuffling to false'
  fi
}

update ()
{
  PLAYING=1
  if [ "$(echo "$INFO" | jq -r '.["Player State"]')" = "Playing" ]; then
    PLAYING=0
    TRACK="$(echo "$INFO" | jq -r .Name | sed 's/\(.\{20\}\).*/\1.../')"
    ARTIST="$(echo "$INFO" | jq -r .Artist | sed 's/\(.\{20\}\).*/\1.../')"
    ALBUM="$(echo "$INFO" | jq -r .Album | sed 's/\(.\{25\}\).*/\1.../')"
    SHUFFLE=$(osascript -e 'tell application "Spotify" to get shuffling')
    REPEAT=$(osascript -e 'tell application "Spotify" to get repeating')
    COVER=$(osascript -e 'tell application "Spotify" to get artwork url of current track')
  fi

  args=()
  if [ $PLAYING -eq 0 ]; then
    curl -s --max-time 20 "$COVER" -o /tmp/cover.jpg
    if [ "$ARTIST" == "" ]; then
      args+=(--set spotify.title label="$TRACK"
             --set spotify.album label="Podcast"
             --set spotify.artist label="$ALBUM"  )
    else
      args+=(--set spotify.title label="$TRACK"
             --set spotify.album label="$ALBUM"
             --set spotify.artist label="$ARTIST")
    fi
    args+=(--set spotify.play icon=ô€Š†
           --set spotify.shuffle icon.highlight=$SHUFFLE
           --set spotify.repeat icon.highlight=$REPEAT
           --set spotify.cover background.image="/tmp/cover.jpg"
                               background.color=0x00000000
           --set spotify.anchor drawing=on                      )
  else
    args+=(--set spotify.anchor drawing=off popup.drawing=off
           --set spotify.play icon=ô€Š„                         )
  fi
  sketchybar -m "${args[@]}"
}

scrubbing() {
  DURATION_MS=$(osascript -e 'tell application "Spotify" to get duration of current track')
  DURATION=$((DURATION_MS/1000))

  TARGET=$((DURATION*PERCENTAGE/100))
  osascript -e "tell application \"Spotify\" to set player position to $TARGET"
  sketchybar --set spotify.state slider.percentage=$PERCENTAGE
}

scroll() {
  DURATION_MS=$(osascript -e 'tell application "Spotify" to get duration of current track')
  DURATION=$((DURATION_MS/1000))

  FLOAT="$(osascript -e 'tell application "Spotify" to get player position')"
  TIME=${FLOAT%.*}
  
  sketchybar --animate linear 10 \
             --set spotify.state slider.percentage="$((TIME*100/DURATION))" \
                                 icon="$(date -r $TIME +'%M:%S')" \
                                 label="$(date -r $DURATION +'%M:%S')"
}

mouse_clicked () {
  case "$NAME" in
    "spotify.next") next
    ;;
    "spotify.back") back
    ;;
    "spotify.play") play
    ;;
    "spotify.shuffle") shuffle
    ;;
    "spotify.repeat") repeat
    ;;
    "spotify.state") scrubbing
    ;;
    *) exit
    ;;
  esac
}

popup () {
  sketchybar --set spotify.anchor popup.drawing=$1
}

routine() {
  case "$NAME" in
    "spotify.state") scroll
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



# plugins/tailscale.sh

#!/bin/bash
# inspo: https://github.com/kejadlen/dotfiles/blob/7eac34262edfab1b6774c158de2f83c0b26a363c/.config/sketchybar/plugins/tailscale.sh
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

LOCK_ICON=ô€¡
UNLOCK_ICON=ô€¥

# Toggle tailscale on click
if [ "$SENDER" = "mouse.clicked" ]; then
	if ! command -v tailscale >/dev/null 2>&1; then
		sketchybar --set "$NAME" icon.drawing=on icon="$UNLOCK_ICON" icon.color=$RED
		exit 0
	fi

	if tailscale status --self &>/dev/null; then
		# Currently connected â†’ disconnect
		sketchybar --set "$NAME" background.image.scale=0 icon.drawing=on icon="$UNLOCK_ICON" icon.color=$RED
		sketchybar --animate sin 15 --set "$NAME" icon.color=$GREY
		tailscale down
		sleep 1
		sketchybar --set "$NAME" icon.drawing=off background.image.scale=0.03
	else
		# Currently disconnected â†’ connect
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


# plugins/volume.sh

#!/bin/bash

WIDTH=100

volume_change() {
  source "$HOME/.config/sketchybar/icons.sh"
  case $INFO in
    [6-9][0-9]|100) ICON=$VOLUME_100
    ;;
    [3-5][0-9]) ICON=$VOLUME_66
    ;;
    [1-2][0-9]) ICON=$VOLUME_33
    ;;
    [1-9]) ICON=$VOLUME_10
    ;;
    0) ICON=$VOLUME_0
    ;;
    *) ICON=$VOLUME_100
  esac

  sketchybar --set volume_icon label=$ICON

  sketchybar --set $NAME slider.percentage=$INFO \
             --animate tanh 30 --set $NAME slider.width=$WIDTH 

  sleep 2

  # Check wether the volume was changed another time while sleeping
  FINAL_PERCENTAGE=$(sketchybar --query $NAME | jq -r ".slider.percentage")
  if [ "$FINAL_PERCENTAGE" -eq "$INFO" ]; then
    sketchybar --animate tanh 30 --set $NAME slider.width=0
  fi
}

mouse_clicked() {
  osascript -e "set volume output volume $PERCENTAGE"
}

mouse_entered() {
  sketchybar --set $NAME slider.knob.drawing=on
}

mouse_exited() {
  sketchybar --set $NAME slider.knob.drawing=off
}

case "$SENDER" in
  "volume_change") volume_change
  ;;
  "mouse.clicked") mouse_clicked
  ;;
  "mouse.entered") mouse_entered
  ;;
  "mouse.exited") mouse_exited
  ;;
esac



# plugins/volume_click.sh

#!/bin/bash

WIDTH=100

detail_on() {
  sketchybar --animate tanh 30 --set volume slider.width=$WIDTH
}

detail_off() {
  sketchybar --animate tanh 30 --set volume slider.width=0
}

toggle_detail() {
  INITIAL_WIDTH=$(sketchybar --query volume | jq -r ".slider.width")
  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    detail_on
  else
    detail_off
  fi
}

toggle_devices() {
  which SwitchAudioSource >/dev/null || exit 0
  source "$HOME/.config/sketchybar/colors.sh"

  args=(--remove '/volume.device\.*/' --set "$NAME" popup.drawing=toggle)
  COUNTER=0
  CURRENT="$(SwitchAudioSource -t output -c)"
  while IFS= read -r device; do
    COLOR=$GREY
    if [ "${device}" = "$CURRENT" ]; then
      COLOR=$WHITE
    fi
    args+=(--add item volume.device.$COUNTER popup."$NAME" \
           --set volume.device.$COUNTER label="${device}" \
                                        label.color="$COLOR" \
                 click_script="SwitchAudioSource -s \"${device}\" && sketchybar --set /volume.device\.*/ label.color=$GREY --set \$NAME label.color=$WHITE --set $NAME popup.drawing=off")
    COUNTER=$((COUNTER+1))
  done <<< "$(SwitchAudioSource -a -t output)"

  sketchybar -m "${args[@]}" > /dev/null
}

if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
  toggle_devices
else
  toggle_detail
fi



# plugins/wifi.sh

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




# plugins/wifit.sh

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




# plugins/yabai.sh

#!/bin/bash

window_state() {
  source "$HOME/.config/sketchybar/colors.sh"
  source "$HOME/.config/sketchybar/icons.sh"

  WINDOW=$(yabai -m query --windows --window)
  CURRENT=$(echo "$WINDOW" | jq '.["stack-index"]')

  args=()
  if [[ $CURRENT -gt 0 ]]; then
    LAST=$(yabai -m query --windows --window stack.last | jq '.["stack-index"]')
    args+=(--set $NAME icon=$YABAI_STACK icon.color=$RED label.drawing=on label=$(printf "[%s/%s]" "$CURRENT" "$LAST"))
    yabai -m config active_window_border_color $RED > /dev/null 2>&1 &

  else 
    args+=(--set $NAME label.drawing=off)
    case "$(echo "$WINDOW" | jq '.["is-floating"]')" in
      "false")
        if [ "$(echo "$WINDOW" | jq '.["has-fullscreen-zoom"]')" = "true" ]; then
          args+=(--set $NAME icon=$YABAI_FULLSCREEN_ZOOM icon.color=$GREEN)
          yabai -m config active_window_border_color $GREEN > /dev/null 2>&1 &
        elif [ "$(echo "$WINDOW" | jq '.["has-parent-zoom"]')" = "true" ]; then
          args+=(--set $NAME icon=$YABAI_PARENT_ZOOM icon.color=$BLUE)
          yabai -m config active_window_border_color $BLUE > /dev/null 2>&1 &
        else
          args+=(--set $NAME icon=$YABAI_GRID icon.color=$ORANGE)
          yabai -m config active_window_border_color $WHITE > /dev/null 2>&1 &
        fi
        ;;
      "true")
        args+=(--set $NAME icon=$YABAI_FLOAT icon.color=$MAGENTA)
        yabai -m config active_window_border_color $MAGENTA > /dev/null 2>&1 &
        ;;
    esac
  fi

  sketchybar -m "${args[@]}"
}

windows_on_spaces () {
  CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh')"

  args=()
  while read -r line
  do
    for space in $line
    do
      icon_strip=" "
      apps=$(yabai -m query --windows --space $space | jq -r ".[].app")
      if [ "$apps" != "" ]; then
        while IFS= read -r app; do
          icon_strip+=" $($HOME/.config/sketchybar/plugins/icon_map.sh "$app")"
        done <<< "$apps"
      fi
      args+=(--set space.$space label="$icon_strip" label.drawing=on)
    done
  done <<< "$CURRENT_SPACES"

  sketchybar -m "${args[@]}"
}

mouse_clicked() {
  yabai -m window --toggle float
  window_state
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "forced") exit 0
  ;;
  "window_focus") window_state 
  ;;
  "windows_on_spaces") windows_on_spaces
  ;;
esac



# plugins/zen.sh

#!/bin/bash

zen_on() {
  sketchybar --set github.bell drawing=off \
             --set apple.logo drawing=off \
             --set '/cpu.*/' drawing=off \
             --set calendar icon.drawing=off \
             --set yabai drawing=off \
             --set separator drawing=off \
             --set front_app drawing=off \
             --set volume_icon drawing=off \
             --set spotify.anchor drawing=off \
             --set spotify.play updates=off \
             --set brew drawing=off
}

zen_off() {
  sketchybar --set github.bell drawing=on \
             --set apple.logo drawing=on \
             --set '/cpu.*/' drawing=on \
             --set calendar icon.drawing=on \
             --set separator drawing=on \
             --set front_app drawing=on \
             --set yabai drawing=on \
             --set volume_icon drawing=on \
             --set spotify.play updates=on \
             --set brew drawing=on
}

if [ "$1" = "on" ]; then
  zen_on
elif [ "$1" = "off" ]; then
  zen_off
else
  if [ "$(sketchybar --query apple.logo | jq -r ".geometry.drawing")" = "on" ]; then
    zen_on
  else
    zen_off
  fi
fi




# sketchybarrc

#!/bin/bash

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
source "$HOME/.config/sketchybar/colors.sh" # Loads all defined colors
source "$HOME/.config/sketchybar/icons.sh" # Loads all defined icons

export CONFIG_DIR="$HOME/.config/sketchybar"
export ITEM_DIR="$CONFIG_DIR/items" # Directory where the items are configured
export PLUGIN_DIR="$CONFIG_DIR/plugins" # Directory where all the plugin scripts are stored

export FONT="SF Pro" # Needs to have Regular, Bold, Semibold, Heavy and Black variants
export PADDINGS=3 # All paddings use this value (icon, label, background)

# Setting up and starting the helper process
HELPER=git.felix.helper
killall helper
cd "$HOME/.config/sketchybar/helper" && make
"$HOME/.config/sketchybar/helper/helper" "$HELPER" > /dev/null 2>&1 &

# Unload the macOS on screen indicator overlay for volume change
launchctl unload -F /System/Library/LaunchAgents/com.apple.OSDUIHelper.plist > /dev/null 2>&1 &

# Setting up the general bar appearance of the bar
bar=(
  height=35
  color=$TRANSPARENT
  shadow=on
  position=top
  sticky=on
  # padding_right=10
  # padding_left=10
  corner_radius=0
  y_offset=0
  # margin=10
  blur_radius=20
  notch_width=0
)

sketchybar --bar "${bar[@]}"

# Setting up default values
defaults=(
  updates=when_shown
  icon.font="$FONT:Bold:14.0"
  icon.color=$ICON_COLOR
  icon.padding_left=$PADDINGS
  icon.padding_right=$PADDINGS
  label.font="$FONT:Semibold:13.0"
  label.color=$LABEL_COLOR
  label.padding_left=$PADDINGS
  label.padding_right=$PADDINGS
  padding_right=$PADDINGS
  padding_left=$PADDINGS
  background.height=30
  background.corner_radius=9
  popup.background.border_width=2
  popup.background.corner_radius=9
  popup.background.border_color=$POPUP_BORDER_COLOR
  popup.background.color=$POPUP_BACKGROUND_COLOR
  popup.blur_radius=20
  popup.background.shadow.drawing=on
)

sketchybar --default "${defaults[@]}"

# Left
source "$ITEM_DIR/apple.sh"
source "$ITEM_DIR/spaces.sh"
source "$ITEM_DIR/front_app.sh"

# Center
source "$ITEM_DIR/apple_music.sh"

# Right
source "$ITEM_DIR/calendar.sh"

sketchybar --add alias "TextInputMenuAgent,Item-0" right \
    --set "TextInputMenuAgent,Item-0" padding_left=0 padding_right=0 label.width=0 update_freq=1

source "$ITEM_DIR/wifi.sh"
source "$ITEM_DIR/battery.sh"
source "$ITEM_DIR/github.sh"
source "$ITEM_DIR/bluetooth.sh"
source "$ITEM_DIR/activity.sh"
source "$ITEM_DIR/tailscale.sh"
source "$ITEM_DIR/brew.sh"
source "$ITEM_DIR/volume.sh"
source "$ITEM_DIR/cpu.sh"

# Forcing all item scripts to run (never do this outside of sketchybarrc)
sketchybar --update

# Disable hotloading to avoid automatic full reloads while plugins update state
sketchybar --hotload false #fix

echo "sketchybar configuration loaded.."


