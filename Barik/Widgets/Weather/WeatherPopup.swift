import SwiftUI

struct WeatherPopup: View {
    @ObservedObject private var weatherManager = WeatherManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let weather = weatherManager.currentWeather {
                // Header: Location + Current Weather
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(weatherManager.locationName ?? "Current Location")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "location.fill")
                                .font(.system(size: 8))
                                .opacity(0.6)
                        }
                        Text(weather.temperature)
                            .font(.system(size: 48, weight: .regular))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: weather.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 28))
                        Text(weather.condition)
                            .font(.system(size: 13))
                            .opacity(0.8)
                        if let high = weatherManager.highTemp, let low = weatherManager.lowTemp {
                            Text("H:\(high) L:\(low)")
                                .font(.system(size: 12))
                                .opacity(0.6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Precipitation indicator (if raining)
                if let precipitation = weatherManager.precipitation, precipitation > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "umbrella.fill")
                            .font(.system(size: 14))
                        Text("\(Int(precipitation * 100))% chance of rain")
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()
                        .background(Color.white.opacity(0.2))
                }

                // Hourly Forecast
                if !weatherManager.hourlyForecast.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(weatherManager.hourlyForecast.prefix(6), id: \.time) { hour in
                                VStack(spacing: 8) {
                                    Text(hour.timeLabel)
                                        .font(.system(size: 12, weight: .medium))
                                        .opacity(0.8)
                                    Image(systemName: hour.symbolName)
                                        .symbolRenderingMode(.multicolor)
                                        .font(.system(size: 20))
                                    if let precip = hour.precipitationProbability, precip > 0 {
                                        Text("\(precip)%")
                                            .font(.system(size: 10))
                                            .foregroundColor(.cyan)
                                    }
                                    Text(hour.temperature)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(width: 50)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                }

                // Open Weather button
                Button(action: {
                    SystemUIHelper.openWeatherApp()
                }) {
                    HStack {
                        Text("Open Weather")
                            .font(.system(size: 13))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .opacity(0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.001))
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }

            } else {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading weather...")
                        .font(.system(size: 13))
                        .opacity(0.6)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            }
        }
        .frame(width: 280)
        .background(Color.black)
    }
}

struct WeatherPopup_Previews: PreviewProvider {
    static var previews: some View {
        WeatherPopup()
            .background(Color.black)
    }
}
