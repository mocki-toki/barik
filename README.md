**NOTICE**: Unfortunately, I don’t have much free time to actively maintain this project. If you like the project but are not satisfied with its current state, you can explore the many forks or create your own. Even if you’re unfamiliar with **Swift**, tools like **Claude Code** and **Codex** can effectively help implement projects like this. This is a great opportunity to tailor **barik** to your needs and make it exactly the way you’d like.

----

<p align="center" dir="auto">
  <img src="resources/header-image.png" alt="Barik"">
  <p align="center" dir="auto">
    <a href="LICENSE">
      <img alt="License Badge" src="https://img.shields.io/github/license/mocki-toki/barik.svg?color=green" style="max-width: 100%;">
    </a>
    <a href="https://github.com/mocki-toki/barik/issues">
      <img alt="Issues Badge" src="https://img.shields.io/github/issues/mocki-toki/barik.svg?color=green" style="max-width: 100%;">
    </a>
    <a href="CHANGELOG.md">
      <img alt="Changelog Badge" src="https://img.shields.io/badge/view-changelog-green.svg" style="max-width: 100%;">
    </a>
    <a href="https://github.com/mocki-toki/barik/releases">
      <img alt="GitHub Downloads (all assets, all releases)" src="https://img.shields.io/github/downloads/mocki-toki/barik/total">
    </a>
  </p>
</p>

**barik** is a lightweight macOS menu bar replacement. If you use [**yabai**](https://github.com/koekeishiya/yabai) or [**AeroSpace**](https://github.com/nikitabobko/AeroSpace) for tiling WM, you can display the current space in a sleek macOS-style panel with smooth animations. This makes it easy to see which number to press to switch spaces.

<br>

## Features

### 🎯 **Core Functionality**

- **Workspace Management**: Real-time display of spaces with window titles and application names
- **Interactive Popups**: Click widgets to access detailed views and controls
- **Multi-App Support**: Works with yabai, AeroSpace, or standalone
- **Performance Modes**: Intelligent update intervals to optimize battery life
- **Theme Support**: System, light, and dark themes with automatic switching

### 🧩 **Available Widgets**

#### **Workspace & Navigation**

- **`default.spaces`** - Display current spaces/workspaces with window information
- **`spacer`** - Flexible spacing element
- **`divider`** - Visual separator between widget groups

#### **System Monitoring**

- **`default.battery`** - Battery status with charging indicators and percentage
- **`default.cpuram`** - CPU and RAM usage with configurable thresholds
- **`default.networkactivity`** - Real-time network upload/download speeds
- **`default.performance`** - Performance mode toggle (battery/balanced/max performance)

#### **Network & Connectivity**

- **`default.network`** - Wi-Fi and Ethernet status with detailed information
- **`default.keyboardlayout`** - Current keyboard layout with quick switching

#### **Time & Calendar**

- **`default.time`** - Customizable time display with calendar integration
- Calendar events support with allow/deny lists
- Multiple timezone support
- Configurable date/time formats

#### **Media & Audio**

- **`default.nowplaying`** - Music control for Spotify and Apple Music
- Album art display with rotation animation
- Playback controls (previous, play/pause, next)
- Progress tracking and time remaining

#### **System Utilities**

- **`system-banner`** - System notifications and alerts

### 🎨 **Customization Features**

#### **Positioning**

- Top or bottom screen placement
- Custom horizontal padding and spacing
- Flexible widget ordering

#### **Appearance**

- Blur effects with 6 intensity levels
- Widget background customization
- Configurable menu bar height
- Smooth animations and transitions

#### **Performance Optimization**

- Three performance modes with different update intervals
- Battery-conscious operation
- Intelligent widget activation/deactivation

## Requirements

- macOS 14.6+

## Quick Start

1. Install **barik** via [Homebrew](https://brew.sh/)

```sh
brew install --cask qusaismael/barik
```

Or you can download from [Releases](https://github.com/mocki-toki/barik/releases), unzip it, and move it to your Applications folder.

2. _(Optional)_ To display open applications and spaces, install [**yabai**](https://github.com/koekeishiya/yabai) or [**AeroSpace**](https://github.com/nikitabobko/AeroSpace) and set up hotkeys. For **yabai**, you'll need **skhd** or **Raycast scripts**. Don't forget to configure **top padding** — [here's an example for **yabai**](https://github.com/qusaismael/barik/blob/main/example/.yabairc).

3. Hide the system menu bar in **System Settings** and uncheck **Desktop & Dock → Show items → On Desktop**.

4. Launch **barik** from the Applications folder.

5. Add **barik** to your login items for automatic startup.

**That's it!** Try switching spaces and see the panel in action.

## Configuration

Barik creates a `~/.barik-config.toml` file on first launch. Here's a comprehensive configuration guide:

### Basic Settings

```toml
# Theme options: "system", "light", "dark"
theme = "system"

# Custom paths for window managers (if not installed via Homebrew)
# yabai.path = "/run/current-system/sw/bin/yabai"
# aerospace.path = "/opt/homebrew/bin/aerospace"
```

### Widget Configuration

```toml
[widgets]
displayed = [
    "default.spaces",
    "spacer",
    "default.nowplaying",
    "default.network",
    "default.battery",
    "default.cpuram",
    "default.networkactivity",
    "default.performance",
    "default.keyboardlayout",
    "divider",
    # Inline configuration example:
    # { "default.time" = { time-zone = "America/Los_Angeles", format = "E d, hh:mm" } },
    "default.time",
]
```

### Spaces Widget

```toml
[widgets.default.spaces]
space.show-key = true                    # Show space number/character
window.show-title = true                 # Show window titles
window.title.max-length = 50             # Maximum title length
window.notch.width = 200                 # Options: <float> (recommended [200 | 0] for displays with and without a notch respectivly)

# Applications that always show app name instead of window title
window.title.always-display-app-name-for = ["Mail", "Chrome", "Arc", "Finder"]
```

### Battery Widget

```toml
[widgets.default.battery]
show-percentage = true                   # Display battery percentage
warning-level = 30                       # Yellow warning threshold
critical-level = 10                      # Red critical threshold
```

### System Monitor Widget

```toml
[widgets.default.cpuram]
show-icon = false                        # Show CPU icon
cpu-warning-level = 70                   # CPU warning threshold (%)
cpu-critical-level = 90                  # CPU critical threshold (%)
ram-warning-level = 70                   # RAM warning threshold (%)
ram-critical-level = 90                  # RAM critical threshold (%)
```

### Time & Calendar Widget

```toml
[widgets.default.time]
format = "E d, J:mm"                     # Time format pattern
time-zone = "America/Los_Angeles"        # Optional timezone override

[widgets.default.time.calendar]
format = "J:mm"                          # Calendar popup time format
show-events = true                       # Display calendar events

# Filter calendars (choose one approach):
# allow-list = ["Personal", "Work"]      # Show only these calendars
# deny-list = ["Birthdays", "Holidays"]  # Hide these calendars

[widgets.default.time.popup]
view-variant = "box"                     # Options: "box", "horizontal", "vertical"
```

### Now Playing Widget

```toml
[widgets.default.nowplaying.popup]
view-variant = "horizontal"              # Options: "horizontal", "vertical"
```

### Network Activity Widget

```toml
[widgets.default.networkactivity]
# Real-time upload/download speed monitoring
# No specific configuration options yet
```

### Performance Mode Widget

```toml
[widgets.default.performance]
# Controls system update intervals for energy optimization
# Modes: battery-saver, balanced, max-performance
```

### Keyboard Layout Widget

```toml
[widgets.default.keyboardlayout]
# Displays current input source with switching capability
# No specific configuration options yet
```

### Position & Layout

```toml
[experimental]
position = "top"                         # Options: "top", "bottom"

[experimental.background]
displayed = true                         # Show blurred background
height = "default"                       # Options: "default", "menu-bar", <float>
blur = 3                                 # Blur intensity: 1-6, or 7 for solid black

[experimental.foreground]
height = "default"                       # Options: "default" (55.0), "menu-bar", <float>
horizontal-padding = 25                  # Left/right padding
spacing = 15                             # Space between widgets

[experimental.foreground.widgets-background]
displayed = false                        # Individual widget backgrounds
blur = 3                                 # Background blur intensity: 1-6
```

## Advanced Features

### Performance Modes

Barik includes intelligent performance management:

- **Battery Saver**: Longest update intervals for maximum battery life
- **Balanced**: Moderate intervals balancing performance and efficiency
- **Max Performance**: Shortest intervals for most responsive updates

### Interactive Popups

Click widgets to access detailed controls:

- **Battery**: Detailed power information and health status
- **Network**: Wi-Fi details, connection info, and network switching
- **Calendar**: Full calendar view with event details
- **Now Playing**: Music controls with album art and progress
- **System Monitor**: CPU/RAM graphs and detailed system statistics
- **Keyboard Layout**: Input source switching and layout management

### Multi-Language Support

- Keyboard layout widget supports multiple languages with abbreviations
- Automatic input source detection and switching
- Localized date/time formatting

## Widget Popup Views

Many widgets support different popup layouts:

- **Box**: Compact square layout
- **Horizontal**: Wide landscape layout
- **Vertical**: Tall portrait layout

Configure via the `view-variant` setting in each widget's popup section.

## Music Service Support

The Now Playing widget currently supports:

1. **Spotify** (desktop application required)
2. **Apple Music** (desktop application required)

Want support for another service? [Create an issue](https://github.com/mocki-toki/barik/issues/new)!

## Menu Items & Compatibility

Menu items (File, Edit, View, etc.) are planned for future releases. Current alternatives:

If you’re accustomed to using menu items from the system menu bar, simply move your mouse to the top of the screen to reveal the system menu bar, where they will be available.

<img src="resources/raycast-menu-items.jpeg" alt="Raycast Menu Items">

## Troubleshooting

### Performance Issues

- Switch to **Battery Saver** or **Balanced** performance mode
- Reduce the number of active widgets
- Increase widget update intervals manually

### Window Manager Integration

- Ensure yabai/AeroSpace is running and properly configured
- Check that the binary path is correct in configuration
- Verify top padding is set appropriately

### Widget Not Updating

- Check widget activation status
- Verify required permissions (calendar, location for network widget)
- Review configuration syntax in `~/.barik-config.toml`

## Future Roadmap

- **Full Style API**: Complete visual customization system
- **Custom Widgets**: Plugin system for community widgets
- **Widget Store**: Share and download community-created widgets and themes
- **Multi-Position Support**: Widgets on all screen edges (replace Dock functionality)
- **Menu Items**: Native menu bar item support
- **More Music Services**: Extended platform support

## Contributing

Contributions are welcome! Please feel free to submit a PR.

## License

[MIT](LICENSE)

## Trademarks

Apple and macOS are trademarks of Apple Inc. This project is not connected to Apple Inc. and does not have their approval or support.

## Stars

[![Stargazers over time](https://starchart.cc/mocki-toki/barik.svg?variant=adaptive)](https://starchart.cc/mocki-toki/barik)
