import SwiftUI

struct BatteryWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    var showPercentage: Bool { config["show-percentage"]?.boolValue ?? true }
    var warningLevel: Int { config["warning-level"]?.intValue ?? 20 }
    var criticalLevel: Int { config["critical-level"]?.intValue ?? 10 }

    @StateObject private var batteryManager = BatteryManager()
    private var level: Int { batteryManager.batteryLevel }
    private var isCharging: Bool { batteryManager.isCharging }
    private var isPluggedIn: Bool { batteryManager.isPluggedIn }

    @State private var rect: CGRect = CGRect()

    var body: some View {
        ZStack {
            ZStack(alignment: .leading) {
                BatteryBodyView(mask: false)
                    .opacity(showPercentage ? 0.3 : 0.4)
                BatteryBodyView(mask: true)
                    .clipShape(
                        Rectangle().path(
                            in: CGRect(
                                x: showPercentage ? 0 : 2,
                                y: 0,
                                width: 30 * Int(level)
                                    / (showPercentage ? 110 : 130),
                                height: .bitWidth
                            )
                        )
                    )
                    .foregroundStyle(batteryColor)
                BatteryText(
                    level: level, isCharging: isCharging,
                    isPluggedIn: isPluggedIn
                )
                .foregroundStyle(batteryTextColor)
            }
            .frame(width: 30, height: 10)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            rect = geometry.frame(in: .global)
                        }
                        .onChange(of: geometry.frame(in: .global)) {
                            oldState, newState in
                            rect = newState
                        }
                }
            )
        }
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "battery") { BatteryPopup() }
        }

    }

    private var batteryTextColor: Color {
        if isCharging {
            return .foregroundOutsideInvert
        } else {
            return level > warningLevel ? .foregroundOutsideInvert : .black
        }
    }

    private var batteryColor: Color {
        if isCharging {
            return .green
        } else {
            if level <= criticalLevel {
                return .red
            } else if level <= warningLevel {
                return .yellow
            } else {
                return .icon
            }
        }
    }
}

private struct BatteryText: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    var showPercentage: Bool { config["show-percentage"]?.boolValue ?? true }

    let level: Int
    let isCharging: Bool
    let isPluggedIn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: -1) {
            if showPercentage {
                Text("\(level)")
                    .font(.system(size: 12))
                    .transition(.blurReplace)
            }

            if isCharging && level != 100 {
                Image(systemName: "bolt.fill")
                    .font(.system(size: showPercentage ? 8 : 10))
            }

            if !isCharging && isPluggedIn && level != 100 {
                Image(systemName: "powerplug.portrait.fill")
                    .font(.system(size: 8))
                    .padding(.leading, 1)
            }
        }
        .foregroundStyle(
            showPercentage ? .foregroundOutsideInvert : .foregroundOutside
        )
        .fontWeight(.semibold)
        .transition(.blurReplace)
        .animation(.smooth, value: isCharging)
        .frame(width: 26, height: 15)
    }
}

private struct BatteryBodyView: View {
    let mask: Bool

    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    var showPercentage: Bool { config["show-percentage"]?.boolValue ?? true }

    var body: some View {
        ZStack {
            if showPercentage || !mask {
                Image(systemName: "battery.0")
                    .resizable()
                    .scaledToFit()
            }
            if showPercentage || mask {
                Rectangle()
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.horizontal, showPercentage ? 3 : 4.4)
                    .padding(.vertical, showPercentage ? 2 : 3.5)
                    .offset(
                        x: showPercentage ? -2 : -1.77,
                        y: showPercentage ? 0 : 0.2)
            }
        }
        .compositingGroup()
    }
}

struct BatteryWidget_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BatteryWidget()
        }.frame(width: 200, height: 100)
            .background(.yellow)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
