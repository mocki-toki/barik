import SwiftUI

struct CountdownWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @ObservedObject private var manager = CountdownManager.shared
    @State private var rect: CGRect = .zero

    private let timer = Timer.publish(every: 3600, on: .main, in: .common).autoconnect()

    var body: some View {
        CalendarIcon(days: manager.daysRemaining)
            .shadow(color: .foregroundShadowOutside, radius: 3)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            rect = geometry.frame(in: .global)
                        }
                        .onChange(of: geometry.frame(in: .global)) { _, newState in
                            rect = newState
                        }
                }
            )
            .experimentalConfiguration(cornerRadius: 15)
            .frame(maxHeight: .infinity)
            .background(.black.opacity(0.001))
            .onTapGesture {
                MenuBarPopup.show(rect: rect, id: "countdown") {
                    CountdownPopup()
                }
            }
            .onReceive(timer) { _ in
                manager.objectWillChange.send()
            }
    }
}

private struct CalendarIcon: View {
    let days: Int

    private var isWide: Bool { days >= 100 }
    private var iconWidth: CGFloat { isWide ? 24 : 18 }
    private var frameWidth: CGFloat { isWide ? 28 : 22 }

    var body: some View {
        ZStack {
            // Calendar outline
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.foregroundOutside, lineWidth: 1.5)
                .frame(width: iconWidth, height: 20)

            // Top bar
            Rectangle()
                .fill(Color.foregroundOutside)
                .frame(width: iconWidth, height: 5)
                .clipShape(
                    .rect(topLeadingRadius: 3, topTrailingRadius: 3)
                )
                .offset(y: -7.5)

            // Binding rings
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.foregroundOutside)
                    .frame(width: 2, height: 5)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.foregroundOutside)
                    .frame(width: 2, height: 5)
            }
            .offset(y: -10)

            // Day number
            Text("\(days)")
                .font(.system(size: isWide ? 9 : 10, weight: .bold))
                .foregroundStyle(.foregroundOutside)
                .offset(y: 2)
        }
        .frame(width: frameWidth, height: 24)
    }
}
