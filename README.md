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

**barik** is a lightweight macOS menu bar replacement. If you use [**yabai**](https://github.com/koekeishiya/yabai), [**AeroSpace**](https://github.com/nikitabobko/AeroSpace), or [**OmniWM**](https://github.com/BarutSRB/OmniWM) for tiling WM, you can display the current space in a sleek macOS-style panel with smooth animations. This makes it easy to see which number to press to switch spaces.

<br>

<div align="center">
  <h3>Screenshots</h3>
  <img src="resources/preview-image-light.png" alt="Barik Light Theme">
  <img src="resources/preview-image-dark.png" alt="Barik Dark Theme">
</div>
<br>
<div align="center">
  <h3>Video</h3>
  <video src="https://github.com/user-attachments/assets/33cfd2c2-e961-4d04-8012-664db0113d4f">
</div>
    
https://github.com/user-attachments/assets/d3799e24-c077-4c6a-a7da-a1f2eee1a07f

<br>

## Requirements

- macOS 14.6+

## Quick Start

1. Install **barik** via [Homebrew](https://brew.sh/)

```sh
brew install --cask mocki-toki/formulae/barik
```

Or you can download from [Releases](https://github.com/mocki-toki/barik/releases), unzip it, and move it to your Applications folder.

2. _(Optional)_ To display open applications and spaces, install [**yabai**](https://github.com/koekeishiya/yabai), [**AeroSpace**](https://github.com/nikitabobko/AeroSpace), or [**OmniWM**](https://github.com/BarutSRB/OmniWM) and set up hotkeys. For **yabai**, you'll need **skhd** or **Raycast scripts**. For **OmniWM**, enable IPC from the status bar menu. Don't forget to configure **top padding** — [here's an example for **yabai**](https://github.com/mocki-toki/barik/blob/main/example/.yabairc).

3. Hide the system menu bar in **System Settings** and uncheck **Desktop & Dock → Show items → On Desktop**.

4. Launch **barik** from the Applications folder.

5. Add **barik** to your login items for automatic startup.

**That's it!** Try switching spaces and see the panel in action.

## Configuration

When you launch **barik** for the first time, it will create a `~/.barik-config.toml` file with an example customization for your new menu bar.

```toml
# If you installed yabai, aerospace, or omniwm without using Homebrew,
# manually set the path to the binary. For example:
#
# yabai.path = "/run/current-system/sw/bin/yabai"
# aerospace.path = ...
# omniwm.path = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"

theme = "system" # system, light, dark

[widgets]
displayed = [ # widgets on menu bar
    "default.spaces",
    "spacer",
    "default.nowplaying",
    "default.network",
    "default.battery",
    # "invisible-divider", # zero-width section break with no line or padding
    "divider",
    # { "default.time" = { time-zone = "America/Los_Angeles", format = "E d, hh:mm" } },
    "default.time",
]

[widgets.default.spaces]
space.show-key = true        # show space number (or character, if you use AeroSpace)
window.show-title = true
window.title.max-length = 50
window.ignore-list = ["Barik"] # hide matching apps by app name or, with OmniWM, by bundle ID

# A list of applications that will always be displayed by application name.
# Other applications will show the window title if there is more than one window.
window.title.always-display-app-name-for = ["Mail", "Chrome", "Arc"]

[widgets.default.nowplaying.popup]
view-variant = "horizontal"

[widgets.default.battery]
show-percentage = true
warning-level = 30
critical-level = 10

[widgets.default.time]
format = "E d, J:mm"
calendar.format = "J:mm"

calendar.show-events = true
# calendar.allow-list = ["Home", "Personal"] # show only these calendars
# calendar.deny-list = ["Work", "Boss"] # show all calendars except these

[widgets.default.time.popup]
view-variant = "box"



### EXPERIMENTAL, WILL BE REPLACED BY STYLE API IN THE FUTURE
[experimental.background] # settings for blurred background
displayed = true          # display blurred background
height = "default"        # available values: default (stretch to full screen), menu-bar (height like system menu bar), <float> (e.g., 40, 33.5)
blur = 3                  # background type: from 1 to 6 for blur intensity, 7 for black color

[experimental.foreground] # settings for menu bar
height = "default"        # available values: default (55.0), menu-bar (height like system menu bar), <float> (e.g., 40, 33.5)
horizontal-padding = 25   # padding on the left and right corners
spacing = 15              # spacing between widgets

# When positioned at the top, barik now stays below the system menu bar area.
# `top-padding` adds extra spacing below that reserved area.
# top-padding = 0

[experimental.foreground.widgets-background] # settings for widgets background
displayed = false                            # wrap widgets in their own background
blur = 3                                     # background type: from 1 to 6 for blur intensity
```

Currently, you can customize the order of widgets (time, indicators, etc.) and adjust some of their settings. Soon, you’ll also be able to add custom widgets and completely change **barik**'s appearance—making it almost unrecognizable (hello, r/unixporn!).

## Building from Source

Build the project and copy it to `~/Applications`:

```sh
xcodebuild -project Barik.xcodeproj -scheme Barik -configuration Release build -derivedDataPath build

# Copy to your Applications folder (~/Applications or /Applications):
cp -R build/Build/Products/Release/Barik.app ~/Applications/

rm -rf build
```

This compiles the app in Release mode and copies it to your Applications folder. Launch **barik** from `~/Applications` or add it to your login items.

## Future Plans

I'm not planning to stick to minimal functionality—exciting new features are coming soon! The roadmap includes full style customization, the ability to create custom widgets or extend existing ones, and a public **Store** where you can share your styles and widgets.

Soon, you'll also be able to place widgets not just at the top, but at the bottom, left, and right as well. This means you can replace not only the menu bar but also the Dock! 🚀

## What to do if the currently playing song is not displayed in the Now Playing widget?

Unfortunately, macOS does not support access to its API that allows music control. Fortunately, there is a workaround using Apple Script or a service API, but this requires additional work to integrate each service. Currently, the Now Playing widget supports the following services:

1. Spotify (requires the desktop application)
2. Apple Music (requires the desktop application)

Create an issue so we can add your favorite music service: https://github.com/mocki-toki/barik/issues/new

## Where Are the Menu Items?

[#5](https://github.com/mocki-toki/barik/issues/5), [#1](https://github.com/mocki-toki/barik/issues/1)

Menu items (such as File, Edit, View, etc.) are not currently supported, but they are planned for future releases. However, you can use [Raycast](https://www.raycast.com/), which supports menu items through an interface similar to Spotlight. I personally use it with the `option + tab` shortcut, and it works very well.

If you’re accustomed to using menu items from the system menu bar, simply move your mouse to the top of the screen to reveal the system menu bar, where they will be available.

<img src="resources/raycast-menu-items.jpeg" alt="Raycast Menu Items">

## Contributing

Contributions are welcome! Please feel free to submit a PR.

## License

[MIT](LICENSE)

## Trademarks

Apple and macOS are trademarks of Apple Inc. This project is not connected to Apple Inc. and does not have their approval or support.

## Stars

[![Stargazers over time](https://starchart.cc/mocki-toki/barik.svg?variant=adaptive)](https://starchart.cc/mocki-toki/barik)
