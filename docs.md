
Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationBar Properties

Bar Properties
Configuration of the bar

For an example configuration see the supplied default sketchybarrc. The configuration file resides in ~/.config/sketchybar/sketchybarrc and is a regular script that gets executed when SketchyBar launches, everything persistent should be set up in this script.

It is possible to play with properties in the commandline and change them on the fly while the bar is running, once you find a fitting value you can include it in the sketchybarrc file, such that the configuration is restored on restart. When configuring SketchyBar it can be helpful to stop the brew service and run sketchybar from the commandline directly to see all relevant error messages and warnings directly.

The global bar properties can be configured by invoking:

sketchybar --bar <setting>=<value> ... <setting>=<value>

where possible settings are:
<setting>	<value>	default	description
color	<argb_hex>	0x44000000	Color of the bar
border_color	<argb_hex>	0xffff0000	Color of the bars border
position	top, bottom	top	Position of the bar on the screen
height	<integer>	25	Height of the bar
notch_display_height	<integer>	0	Override of the height of the bar on notched displays
margin	<integer>	0	Margin around the bar
y_offset	<integer>	0	Vertical offset of the bar from its default position
corner_radius	<positive_integer>	0	Corner radius of the bar
border_width	<positive_integer>	0	Border width of the bars border
blur_radius	<positive_integer>	0	Blur radius applied to the background of the bar
padding_left	<positive_integer>	0	Padding between the left bar border and the leftmost item
padding_right	<positive_integer>	0	Padding between the right bar border and the rightmost item
notch_width	<positive_integer>	200	The width of the notch to be accounted for on the internal display
notch_offset	<positive_integer>	0	Additional y_offset exclusively applied to notched screens
display	main, all, <positive_integer list>	all	Display to show the bar on
hidden	<boolean>, current	off	If all / the current bar is hidden
topmost	<boolean>, window	off	If the bar should be drawn on top of everything, or on top of all windows
sticky	<boolean>	on	Makes the bar sticky during space changes
font_smoothing	<boolean>	off	If fonts should be smoothened
shadow	<boolean>	off	If the bar should draw a shadow

You can find the nomenclature for all the types here. If you are looking for colors, check out the color picker.
Previous
Setup
Next
Item Properties

    Configuration of the bar


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationSpecial Components

Special Components
Components -- Special Items with special properties

Components are essentially items, but with special properties. Currently there are the components (more details in the corresponding sections below):

    graph: showing a graph,
    space: representing a mission control space
    bracket: brackets together other items
    alias: an alias of a menu bar item from the macOS bar
    slider: a slider that shows a progression and can be clicked/dragged to set a new value

Data Graph -- Draws an arbitrary graph into the bar

sketchybar --add graph <name> <position> <width in points>

Additional graph properties:
<property>	<value>	default	description
graph.color	<argb_hex>	0xffcccccc	Color of the graph line
graph.fill_color	<argb_hex>	0xffcccccc	Fill color of the graph
graph.line_width	<float>	0.5	Width of the line in points

Push data points into the graph via:

sketchybar --push <name> <data point> ... <data point>

where the <data point> is a floating point number between 0 and 1.

Graphs usually take the entire height of the bar as a drawing canvas, however, if you set a background for the graph item and set a height for it, the graph will draw inside of the background. With a background enabled, the graph can also be moved via a y_offset, e.g.:

sketchybar --set <graph name> background.color=0xff00ff00 background.height=20 y_offset=2

Space -- Associate mission control spaces with an item

sketchybar --add space <name> <position>

The space component overrides the definition of the following properties:

    space: Which space this item represents
    (optional) display: On which display the space is shown. The space property must be set to properly associate this item with the corresponding mission control space. Optionally, you can provide an display to force a space item to stay on a specific display, otherwise the item will draw on the screen on which the space is currently located. 

The space component has additional variables available in scripts:

$SELECTED
$SID
$DID

where $SELECTED has the value true if the associated space is selected and false if the associated space is not selected, while $SID holds the space id and $DID the display id.

By default the space component invokes the following script:

sketchybar --set $NAME icon.highlight=$SELECTED

which you can freely configure to your liking by supplying a different script to the space component:

sketchybar --set <name> script=<script/path>

For performance reasons the space script is only run on a change in the $SELECTED variable, i.e. if the associated space has become active or has resigned being active.
Item Bracket -- Group Items in e.g. colored sections

It is possible to create a common background for any number of items, i.e. to bracket together items, via the command:

sketchybar --add bracket <name> <member name> ... <member name>

The <member name> is a name of any item in the bar that should be added to the bracket. The <member name> can also be a /<regex>/ expression. It is now possible to set properties for the bracket, just as for any item or component. Brackets currently only support all background features. E.g., if I wanted a colored background around my space components (which are named space.1, space.2, space.3) I would set it up like this:

sketchybar --add bracket spaces space.1 space.2 space.3     \
           --set         spaces background.color=0xffffffff \
                                background.corner_radius=4  \
                                background.height=20

Alternatively, if I had a number of spaces, called space.1, space.2, etc. the regex syntax comes in handy:

sketchybar --add bracket spaces '/space\..*/'               \
           --set         spaces background.color=0xffffffff \
                                background.corner_radius=4  \
                                background.height=20

this draws a white background below all my space components.

Brackets are very flexible with their members, i.e. it is no problem to bracket together a left and a center item, the background will span all the way between those items.
Item Alias -- Mirror items of the original macOS status bar into sketchybar

It is possible to create an alias for default menu bar items (such as MeetingBar, etc.) in sketchybar. The default menu bar can be set to autohide and this should still work.

To create an alias of a default menu bar item use the following syntax:

sketchybar --add alias <application_name> <position>

this operation requires screen capture permissions, which should be granted in the system preferences.

This will put the default macOS menu bar item into sketchybar. If an application has multiple menu bar widgets the command can be overloaded by providing a window_owner and a window_name

sketchybar --add alias "<window_owner>,<window_name>" <position>

this way the default system items can also be aliased in sketchybar as well, e.g.:

    "Control Center,Bluetooth"
    "Control Center,WiFi"
    ...

Or the individual widgets of Stats:

    "Stats,CPU_Mini"
    etc...

All further macOS menu bar items currently available on your system can be found via the command

sketchybar --query default_menu_items

where all items with their respective owner and name are listed.

You can override the color of an alias via the property:

sketchybar --set <name> alias.color=<argb_hex>

and change its scale via:

sketchybar --set <name> alias.scale=<float>

By default, an alias will update once a second, the update interval can be adapted via:

sketchybar --set <name> alias.update_freq=<positive_integer>

Slider -- A draggable progression indicator

A slider can be added to the bar via the command:

sketchybar --add slider <name> <position> <width>

Like all components, the slider only adds some additional properties and functionality to a regular item. Thus all properties of regular items are available for the slider. Additionally the slider exposes the additional properties:
<property>	<value>	default	description
slider.width	<positive_integer>	100	Total width of the slider in points
slider.percentage	<positive_integer>	0	Progression of the slider in percent (0-100)
slider.highlight_color	<argb_hex>	0xff0000ff	Color that highlights the progression of the slider
slider.knob	<string>		Knob of the slider
slider.knob.<text_property>			The slider knob supports all text properties
slider.background.<background_property>			The slider supports all background properties

The slider can be enabled to receive mouse.clicked events by subscribing to this event. A slider will receive the additional environment variable $PERCENTAGE on a click in its script, which represents the percentage corresponding to the click location. If a slider is dragged by the mouse it will only send a single event on drag release and track the mouse during the drag.
Previous
Item Properties
Next
Popup Menus

    Components -- Special Items with special properties
        Data Graph -- Draws an arbitrary graph into the bar
        Space -- Associate mission control spaces with an item
        Item Bracket -- Group Items in e.g. colored sections
        Item Alias -- Mirror items of the original macOS status bar into sketchybar
        Slider -- A draggable progression indicator


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationPopup Menus

Popup Menus
Popup Menus

Simple Popup

Popup menus are a powerful way to make further items accessible in a small popup window below any bar item. Every item has a popup available with the properties:

sketchybar --set <name> popup.<popup_property>=<value>

<popup_property>	<value>	default	description
drawing	<boolean>	off	If the popup should be rendered
horizontal	<boolean>	off	If the popup should render horizontally
topmost	<boolean>	on	If the popup should always be on top of all other windows
height	<positive_integer>	bar height	The vertical spacing between items in a popup
blur_radius	<positive_integer>	0	The blur applied to the popup background
y_offset	<integer>	0	Vertical offset applied to the popup
align	left, right, center	left	Alignment of the popup with its parent item in the bar
background.<background_property>			Popups have a background and support all properties

Items can be added to a popup menu by setting the position of those items to popup.<name> where <name> is the name of the item containing the popup. You can find a demo implementation of this here.
Previous
Special Components
Next
Events & Scripting

    Popup Menus


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationEvents & Scripting

Events & Scripting
Events and Scripting

All items can subscribe to arbitrary events; when the event happens, all items subscribed to the event will execute their script. This can be used to create more reactive and performant items which react to events rather than polling for a change.

sketchybar --subscribe <name> <event> ... <event>

where the events are:
<event>	description	$INFO
front_app_switched	When the front application changes (not triggered if a different window of the same app is focused)	front application name
space_change	When the active mission control space changes	JSON for active spaces on all displays
space_windows_change	When a window is created or destroyed on a space	JSON containing the space and all app windows on this space
display_change	When the active display is changed	new active display id
volume_change	When the system audio volume is changed	new volume in percent
brightness_change	When a displays brightness is changed	new brightness in percent
power_source_change	When the devices power source is changed	new power source (AC or BATTERY)
wifi_change	When the device connects of disconnects from wifi	new WiFi SSID or empty on disconnect (not working since macOS Sonoma)
media_change	When a change in now playing media is performed (deprecated on macOS 26.0)	media info in a JSON structure
system_will_sleep	When the system prepares to sleep	
system_woke	When the system has awaken from sleep	
mouse.entered	When the mouse enters over an item	
mouse.exited	When the mouse leaves an item	
mouse.entered.global	When the mouse enters over any part of the bar	
mouse.exited.global	When the mouse leaves all parts of the bar	
mouse.clicked	When an item is clicked	mouse button and modifier info
mouse.scrolled	When the mouse is scrolled over an item	scroll wheel delta
mouse.scrolled.global	When the mouse is scrolled over an empty region of the bar	scroll wheel delta

Some events send additional information in the $INFO variable When an item is subscribed to these events the script is run and it gets passed the $SENDER variable, which holds exactly the above names to distinguish between the different events. It is thus possible to have a script that reacts to each event differently e.g. via a switch for the $SENDER variable in the script.

Alternatively a fixed update_freq can be --set, such that the event is routinely run to poll for change, the $SENDER variable will in this case hold the value routine.

When an item invokes a script, the script has access to some environment variables, such as:

$NAME
$SENDER
$CONFIG_DIR

Where $NAME is the name of the item that has invoked the script and $SENDER is the reason why the script is executed. The variable $CONFIG_DIR contains the absolute path of the directory where the current sketchybarrc file is located.

If an item is clicked the script has access to the additional variables:

$BUTTON
$MODIFIER

where the $BUTTON can be left, right or other and specifies the mouse button that was used to click the item, while the $MODIFIER is either shift, ctrl, alt or cmd and specifies the modifier key held down while clicking the item.

If an item receive a scroll event from the mouse the script gets send the additional $SCROLL_DELTA variable.

All scripts are forced to terminate after 60 seconds and do not run while the system is sleeping.
Creating custom events

This allows to define events which are triggered by arbitrary applications or manually (see Trigger custom events). Items can also subscribe to these events for their script execution.

sketchybar --add event <name> [optional: <NSDistributedNotificationName>]

Optional: You can subscribe to the notifications sent to the NSDistributedNotificationCenter e.g. the notification Spotify sends on track change: com.spotify.client.PlaybackStateChanged (example), or the notification sent by the system when the screen is unlocked: com.apple.screenIsUnlocked (example) to create more responsive items. Custom events that subscribe to NSDistributedNotificationCenter notifications will receive additional notification information in the $INFO variable if available. For more NSDistributedNotifications see this discussion.
Triggering custom events

This triggers a custom event that has been added before

sketchybar --trigger <event> [Optional: <envvar>=<value> ... <envvar>=<value>]

Optionally you can add environment variables to the trigger command witch are passed to the script, e.g.:

sketchybar --trigger demo VAR=Test

will trigger the demo event and $VAR will be available as an environment variable in the scripts that this event invokes.
Forcing all shell scripts to run and the bar to refresh

This command forces all scripts to run and all events to be emitted, it should never be used in an item script, as this would lead to infinite loops. It is prominently needed after the initial configuration to properly initialize all items by forcing all their scripts to run

sketchybar --update

Previous
Popup Menus
Next
Querying Information

    Events and Scripting
        Creating custom events
        Triggering custom events
        Forcing all shell scripts to run and the bar to refresh


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationQuerying Information

Querying Information
Querying

SketchyBar can be queried for information about a number of things.
Bar Properties

Information about the bar can be queried via:

sketchybar --query bar

The output is a JSON structure containing relevant information about the configuration settings of the bar.
Item Properties

Information about an item can be queried via:

sketchybar --query <name>

The output is a JSON structure containing relevant information about the configuration of the item.
Default Properties

Information about the current defaults.

sketchybar --query defaults

Event Properties

Information about the events.

sketchybar --query events

macOS Menu Bar Item Names (for use with aliases)

The names of the menu bar items in the default macOS bar:

sketchybar --query default_menu_items

Display Configuration Information

Information about the current display configuration:

sketchybar --query displays

Previous
Events & Scripting
Next
Animations

    Querying
        Bar Properties
        Item Properties
        Default Properties
        Event Properties
        macOS Menu Bar Item Names (for use with aliases)
        Display Configuration Information


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationAnimations

Animations
Animating the bar

All transitions between <argb_hex>, <integer> and <positive_integer> values can be animated, by prepending the animation command in front of any regular --set or --bar command:

sketchybar --animate <curve> <duration> \
           --bar <property>=<value> ... <property>=<value> \
           --set <name> <property>=<value> ... <property>=<value>

where the <curve> is any of the animation curves:

    linear, quadratic, tanh, sin, exp, circ

The <duration> is a positive integer quantifying the number of animation steps (the duration is the frame count on a 60Hz display, such that the temporal duration of the animation in seconds is given by <duration> / 60).

The animation system always animates between all current values and the values specified in a configuration command (i.e. --bar or --set commands).
Perform multiple animations chained together

If you want to chain two or more animations together, you can do so by simply changing the property multiple times in a single call, e.g.

sketchybar --animate sin 30 --bar y_offset=10 y_offset=0

will animate the bar to the first offset and after that to the second offset. You can chain together as main animations as you like and you can change the animation function in between. This is a nice way to create custom animations with key-frames. You can also make other properties wait with their animation till another animation is finished, by simply setting the property that should wait to its current value in the first animation.

A new non-animated --set command targeting a currently animated property will cancel the animation queue and immediately set the value.

A new animated --set command targeting a currently animated property will cancel the animation queue and immediately begin with the new animation, beginning at the current state.
Previous
Querying Information
Next
Type Nomenclature

    Animating the bar
        Perform multiple animations chained together


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationType Nomenclature

Type Nomenclature
Type nomenclature
type	values
<boolean>	on, off, yes, no, true, false, 1, 0, toggle
<argb_hex>	Color as an 8 digit hex with alpha, red, green and blue channels
<path>	An absolute file path
<string>	Any UTF-8 string or symbol
<float>	A floating point number
<integer>	An integer
<positive_integer>	A positive integer
<positive_integer list>	A comma separated list of positive integers
Further <boolean> operations

All <boolean> properties can be negated with an exclamation mark, e.g. !on.
Further <argb_hex> operations

All colors (i.e. all fields where the value type is <argb_hex>) can additionally be accessed to change specific channels like this:
<color_property>	<value>	default	description
alpha	<float>	1.0	The alpha channel of the color (0 to 1)
red	<float>	1.0	The red channel of the color (0 to 1)
green	<float>	1.0	The green channel of the color (0 to 1)
blue	<float>	1.0	The blue channel of the color (0 to 1)

So for example, if I want to only change the alpha channel of the bars color I would use

sketchybar --bar color.alpha=0.5

Previous
Animations
Next
Reloading the configuration

    Type nomenclature
        Further <boolean> operations
        Further <argb_hex> operations


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationReloading the configuration

Reloading the configuration file of the bar

If you wish to reload the configuration file of the bar without resorting to manually restarting the process you can use the following command:

sketchybar --reload [Optional: <path>]

which, has the same effect as restarting the process, but is a bit more convenient. Additionally, an optional <path> argument to a new sketchybarrc file can be given to load a different configuration. If the optional argument is left out, the current configuration is reloaded.
Hotloading the configuration of the bar

If you wish that the bar automatically reloads the configuration file once you edit it, you can use the hotload functionality included in SketchyBar. It will monitor the directory of the current configuration for changes and reload the configuration should it detect file changes. To control the hotload feature you can use:

sketchybar --hotload <boolean>

Previous
Type Nomenclature
Next
Tips & Tricks


Skip to main content
SketchyBar Logo
SketchyBar
Features
Setup & Installation
Configuration
⌘
K

    Features
    Setup
    Configuration
        Bar Properties
        Item Properties
        Special Components
        Popup Menus
        Events & Scripting
        Querying Information
        Animations
        Type Nomenclature
        Reloading the configuration
        Tips & Tricks
    Credits

    ConfigurationTips & Tricks

Tips & Tricks
Batching of configuration commands

It is possible to batch commands together into a single call to SketchyBar, this can be helpful to keep the configuration file a bit cleaner and also to reduce startup times. Assume 5 individual configuration calls to SketchyBar:

sketchybar --bar position=top
sketchybar --bar margin=5
sketchybar --add item demo left
sketchybar --set demo label=Hello
sketchybar --subscribe demo system_woke

after each configuration command the bar is redrawn (if needed), thus it is faster to append these calls into a single command like so:

sketchybar --bar position=top           \
                 margin=5               \
           --add item demo left         \
           --set demo label=Hello       \
           --subscribe demo system_woke

The backslash at the end of the first 4 lines is the default bash way to join lines together and should not be followed by a whitespace.
Using bash arrays for cleaner configuration

Lets assume this bar configuration command (from the default config):

sketchybar --bar height=32        \
                 blur_radius=30   \
                 position=top     \
                 sticky=off       \
                 padding_left=10  \
                 padding_right=10 \
                 color=0x15ffffff

We can rewrite this as a bash array to get rid of the backslashes and pass the contents of the array to the --bar command:

bar=(
  height=32
  blur_radius=30
  position=top
  sticky=off
  padding_left=10
  padding_right=10
  color=0x15ffffff
)

sketchybar --bar "${bar[@]}"

Debugging Problems

If you are experiencing problems with the configuration of SketchyBar it might be helpful to work through the following steps:

    1.) Start sketchybar directly from the commandline to see the verbose error/warning messages
    2.) Make sure you have no trailing whitespaces after the bash newline escape char \
    3.) Make sure your scripts are made executable via: chmod +x script.sh
    4.) Reduce the configuration to a minimal example and narrow down the problematic region
    5.) Try running erroneous scripts directly in the commandline
    6.) Query SketchyBar for relevant properties and use them to deduce the problems root cause
    7.) Create an Issue on GitHub, a second pair of eyes might now be the only thing that helps

Color Picker

SketchyBar uses the argb hex color format, which means: 0xAARRGGBB encodes a color.
Try the Picker!
Finding Icons

The default font SketchyBar uses is the Hack Nerd Font which means all Nerdfont icons can be used. Refer to the Nerdfont cheat-sheet to find new icons.

Additionally, it is possible to use other icons and glyphs from different fonts, such as the sf-symbols from apple. Those symbols can be installed via brew:

brew install --cask sf-symbols

After installing this package, an app called SF Symbols will be available where you can find all the available icons. Once you find a fitting icon, right click it, select Copy Symbol and paste it in the relevant configuration file.

If you are looking for stylised app icons you might want to checkout the excellent community maintained app-icon-font for SketchyBar.
Multiple Bars

It is possible to have multiple independent instances of SketchyBar running. This is possible by changing the argv[0] of the sketchybar program. This is very easy, e.g. by symlinking the sketchybar binary with a different name, e.g. bottom_bar:

ln -s $(which sketchybar) $(dirname $(which sketchybar))/bottom_bar

This symlink can now be used to spawn and target an additional bar, i.e. for this bar we do not call sketchybar --bar color=0xffff0000, but rather bottom_bar --bar color=0xffff0000 and start it by running bottom_bar in the commandline.

The config path for this additional bar is in $HOME/.config/bottom_bar/. Of course bottom_bar is only an example and can be freely replaced with any other identifier. The name of the bar is available in the environment variable $BAR_NAME in all scripts, making it possible to create bar-agnostic scripts by replacing sketchybar with $BAR_NAME.
Performance optimizations

SketchyBar can be configured to have a very small performance footprint. In the following I will highlight some optimizations that can be used to reduce the footprint further.

    Batch together configuration commands where ever possible.
    Set updates=when_shown for items that do not need to run their script if they are not rendered.
    Reduce the update_freq of scripts and aliases and use event-driven scripting when ever possible.
    Do not add aliases to apps that are not always running, otherwise SketchyBar searches for them continuously.
    (Advanced; Only >=v2.9.0) Use compiled mach_helper programs that directly interface with SketchyBar example for performance sensitive tasks

Previous
Reloading the configuration
Next
Credits

    Batching of configuration commands
        Using bash arrays for cleaner configuration
    Debugging Problems
    Color Picker
    Finding Icons
    Multiple Bars
    Performance optimizations

