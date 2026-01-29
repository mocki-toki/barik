import SwiftUI

struct SettingsPopup: View {
    @ObservedObject var configManager = ConfigManager.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                TabButton(title: "General", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "Bar", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Widgets", isSelected: selectedTab == 2) { selectedTab = 2 }
                TabButton(title: "Advanced", isSelected: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider()
                .padding(.top, 8)

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0: GeneralTab(configManager: configManager)
                    case 1: BarTab(configManager: configManager)
                    case 2: WidgetsTab(configManager: configManager)
                    case 3: AdvancedTab(configManager: configManager)
                    default: EmptyView()
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 360, height: 420)
        .background(.regularMaterial)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab

struct GeneralTab: View {
    @ObservedObject var configManager: ConfigManager

    private var theme: String {
        configManager.config.rootToml.theme ?? "system"
    }

    private var position: BarPosition {
        configManager.config.experimental.foreground.position
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Appearance") {
                HStack {
                    Text("Theme")
                    Spacer()
                    Picker("", selection: themeBinding) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }

            SettingsSection(title: "Layout") {
                HStack {
                    Text("Position")
                    Spacer()
                    Picker("", selection: positionBinding) {
                        Text("Top").tag("top")
                        Text("Bottom").tag("bottom")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
    }

    private var themeBinding: Binding<String> {
        Binding(
            get: { theme },
            set: { ConfigManager.shared.updateConfigValue(key: "theme", newValue: $0) }
        )
    }

    private var positionBinding: Binding<String> {
        Binding(
            get: { position.rawValue },
            set: { ConfigManager.shared.updateConfigValue(key: "experimental.foreground.position", newValue: $0) }
        )
    }
}

// MARK: - Bar Tab

struct BarTab: View {
    @ObservedObject var configManager: ConfigManager

    private var backgroundDisplayed: Bool {
        configManager.config.experimental.background.displayed
    }

    private var widgetsBackgroundDisplayed: Bool {
        configManager.config.experimental.foreground.widgetsBackground.displayed
    }

    private var spacing: CGFloat {
        configManager.config.experimental.foreground.spacing
    }

    private var horizontalPadding: CGFloat {
        configManager.config.experimental.foreground.horizontalPadding
    }

    private var backgroundBlurRaw: Int {
        configManager.config.experimental.background.blurRaw
    }

    private var widgetBlurRaw: Int {
        configManager.config.experimental.foreground.widgetsBackground.blurRaw
    }

    @State private var backgroundBlur: Double = 3
    @State private var widgetBlur: Double = 3
    @State private var spacingValue: Double = 15
    @State private var paddingValue: Double = 25

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Background Panel") {
                Toggle(isOn: backgroundBinding) {
                    Text("Show background panel")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blur: \(Int(backgroundBlur))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $backgroundBlur, in: 1...7, step: 1) { editing in
                        if !editing {
                            ConfigManager.shared.updateConfigValue(
                                key: "experimental.background.blur",
                                newValue: Int(backgroundBlur)
                            )
                        }
                    }
                }
            }

            SettingsSection(title: "Widget Backgrounds") {
                Toggle(isOn: widgetsBackgroundBinding) {
                    Text("Show widget backgrounds")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blur: \(Int(widgetBlur))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $widgetBlur, in: 1...6, step: 1) { editing in
                        if !editing {
                            ConfigManager.shared.updateConfigValue(
                                key: "experimental.foreground.widgets-background.blur",
                                newValue: Int(widgetBlur)
                            )
                        }
                    }
                }
            }

            SettingsSection(title: "Spacing") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Widget spacing: \(Int(spacingValue))px")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $spacingValue, in: 0...50, step: 5) { editing in
                        if !editing {
                            ConfigManager.shared.updateConfigValue(
                                key: "experimental.foreground.spacing",
                                newValue: Int(spacingValue)
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Horizontal padding: \(Int(paddingValue))px")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $paddingValue, in: 0...100, step: 5) { editing in
                        if !editing {
                            ConfigManager.shared.updateConfigValue(
                                key: "experimental.foreground.horizontal-padding",
                                newValue: Int(paddingValue)
                            )
                        }
                    }
                }
            }

        }
        .onAppear {
            backgroundBlur = Double(backgroundBlurRaw)
            widgetBlur = Double(widgetBlurRaw)
            spacingValue = Double(spacing)
            paddingValue = Double(horizontalPadding)
        }
    }

    private var backgroundBinding: Binding<Bool> {
        Binding(
            get: { backgroundDisplayed },
            set: { ConfigManager.shared.updateConfigValue(key: "experimental.background.displayed", newValue: $0) }
        )
    }

    private var widgetsBackgroundBinding: Binding<Bool> {
        Binding(
            get: { widgetsBackgroundDisplayed },
            set: { ConfigManager.shared.updateConfigValue(key: "experimental.foreground.widgets-background.displayed", newValue: $0) }
        )
    }
}

// MARK: - Widgets Tab

struct WidgetsTab: View {
    @ObservedObject var configManager: ConfigManager

    // Battery state
    @State private var showPercentage = true
    @State private var warningLevel: Double = 30
    @State private var criticalLevel: Double = 10

    // Time state
    @State private var timeFormat = "E d, J:mm"
    @State private var showCalendarEvents = true
    @State private var calendarFormat = "J:mm"
    @State private var popupVariant = "box"

    // Spaces state
    @State private var showSpaceKey = true
    @State private var showWindowTitle = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Battery") {
                Toggle("Show percentage", isOn: $showPercentage)
                    .onChange(of: showPercentage) { _, newValue in
                        ConfigManager.shared.updateConfigValue(
                            tablePath: "widgets.default.battery",
                            key: "show-percentage",
                            newValue: newValue
                        )
                    }

                SliderRow(
                    label: "Warning level",
                    value: $warningLevel,
                    range: 5...50,
                    unit: "%"
                ) { newValue in
                    ConfigManager.shared.updateConfigValue(
                        tablePath: "widgets.default.battery",
                        key: "warning-level",
                        newValue: Int(newValue)
                    )
                }

                SliderRow(
                    label: "Critical level",
                    value: $criticalLevel,
                    range: 5...30,
                    unit: "%"
                ) { newValue in
                    ConfigManager.shared.updateConfigValue(
                        tablePath: "widgets.default.battery",
                        key: "critical-level",
                        newValue: Int(newValue)
                    )
                }
            }

            SettingsSection(title: "Time") {
                TextFieldRow(label: "Format", text: $timeFormat) { newValue in
                    ConfigManager.shared.updateConfigValue(
                        tablePath: "widgets.default.time",
                        key: "format",
                        newValue: newValue
                    )
                }

                Toggle("Show calendar events", isOn: $showCalendarEvents)
                    .onChange(of: showCalendarEvents) { _, newValue in
                        ConfigManager.shared.updateConfigValue(
                            tablePath: "widgets.default.time",
                            key: "calendar.show-events",
                            newValue: newValue
                        )
                    }

                TextFieldRow(label: "Calendar format", text: $calendarFormat) { newValue in
                    ConfigManager.shared.updateConfigValue(
                        tablePath: "widgets.default.time",
                        key: "calendar.format",
                        newValue: newValue
                    )
                }

                HStack {
                    Text("Popup style")
                    Spacer()
                    Picker("", selection: $popupVariant) {
                        Text("Box").tag("box")
                        Text("Vertical").tag("vertical")
                        Text("Horizontal").tag("horizontal")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .onChange(of: popupVariant) { _, newValue in
                        ConfigManager.shared.updateConfigValue(
                            tablePath: "popup.default.time",
                            key: "view-variant",
                            newValue: newValue
                        )
                    }
                }
            }

            SettingsSection(title: "Spaces") {
                Toggle("Show space key", isOn: $showSpaceKey)
                    .onChange(of: showSpaceKey) { _, newValue in
                        ConfigManager.shared.updateConfigValue(
                            tablePath: "widgets.default.spaces",
                            key: "space.show-key",
                            newValue: newValue
                        )
                    }

                Toggle("Show window title", isOn: $showWindowTitle)
                    .onChange(of: showWindowTitle) { _, newValue in
                        ConfigManager.shared.updateConfigValue(
                            tablePath: "widgets.default.spaces",
                            key: "window.show-title",
                            newValue: newValue
                        )
                    }
            }
        }
        .onAppear { loadFromConfig() }
    }

    private func loadFromConfig() {
        // Load battery config
        if let batteryConfig = configManager.config.rootToml.widgets.config(for: "default.battery") {
            if let showPct = batteryConfig["show-percentage"]?.boolValue {
                showPercentage = showPct
            }
            if let warning = batteryConfig["warning-level"]?.intValue {
                warningLevel = Double(warning)
            }
            if let critical = batteryConfig["critical-level"]?.intValue {
                criticalLevel = Double(critical)
            }
        }

        // Load time config
        if let timeConfig = configManager.config.rootToml.widgets.config(for: "default.time") {
            if let format = timeConfig["format"]?.stringValue {
                timeFormat = format
            }
            if let calendarDict = timeConfig["calendar"]?.dictionaryValue {
                if let showEvents = calendarDict["show-events"]?.boolValue {
                    showCalendarEvents = showEvents
                }
                if let calFormat = calendarDict["format"]?.stringValue {
                    calendarFormat = calFormat
                }
            }
        }

        // Note: popup config is in a separate [popup.default.time] table
        // which isn't currently decoded in the config model.
        // The default value "box" will be used, and changes will be saved correctly.

        // Load spaces config
        if let spacesConfig = configManager.config.rootToml.widgets.config(for: "default.spaces") {
            if let spaceDict = spacesConfig["space"]?.dictionaryValue,
               let showKey = spaceDict["show-key"]?.boolValue {
                showSpaceKey = showKey
            }
            if let windowDict = spacesConfig["window"]?.dictionaryValue,
               let showTitle = windowDict["show-title"]?.boolValue {
                showWindowTitle = showTitle
            }
        }
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var unit: String = ""
    var onCommit: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label): \(Int(value))\(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $value, in: range, step: 1) { editing in
                if !editing {
                    onCommit(value)
                }
            }
        }
    }
}

// MARK: - TextField Row

struct TextFieldRow: View {
    let label: String
    @Binding var text: String
    var onCommit: (String) -> Void

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
                .onSubmit {
                    onCommit(text)
                }
        }
    }
}

// MARK: - Advanced Tab

struct AdvancedTab: View {
    @ObservedObject var configManager: ConfigManager

    @State private var aerospacePath: String = ""
    @State private var yabaiPath: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Tiling Window Managers") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AeroSpace path")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Auto-detect", text: $aerospacePath)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !aerospacePath.isEmpty {
                                ConfigManager.shared.updateConfigValue(key: "aerospace.path", newValue: aerospacePath)
                            }
                        }
                    Text("Leave empty for auto-detection")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Yabai path")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Auto-detect", text: $yabaiPath)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !yabaiPath.isEmpty {
                                ConfigManager.shared.updateConfigValue(key: "yabai.path", newValue: yabaiPath)
                            }
                        }
                    Text("Leave empty for auto-detection")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            SettingsSection(title: "Configuration") {
                Button("Open Config File") {
                    openConfigFile()
                }
                .buttonStyle(.borderedProminent)
            }

            SettingsSection(title: "Config File Location") {
                Text("~/.barik-config.toml")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .onAppear {
            loadPaths()
        }
    }

    private func loadPaths() {
        if let aerospace = configManager.config.rootToml.aerospace {
            // Only show if it was explicitly set (not auto-detected)
            // We can't easily detect this, so we leave it empty to indicate auto-detect
        }
        if let yabai = configManager.config.rootToml.yabai {
            // Same as above
        }
    }

    private func openConfigFile() {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let path1 = "\(homePath)/.barik-config.toml"
        let path2 = "\(homePath)/.config/barik/config.toml"

        let configPath: String
        if FileManager.default.fileExists(atPath: path1) {
            configPath = path1
        } else if FileManager.default.fileExists(atPath: path2) {
            configPath = path2
        } else {
            configPath = path1
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
        }
    }
}
