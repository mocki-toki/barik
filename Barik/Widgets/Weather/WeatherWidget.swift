import SwiftUI
import CoreLocation

/// Weather widget that displays current weather using Open-Meteo API
struct WeatherWidget: View {
    @StateObject private var weatherManager = WeatherManager.shared

    var body: some View {
        HStack(spacing: 4) {
            if let weather = weatherManager.currentWeather {
                Image(systemName: weather.symbolName)
                    .symbolRenderingMode(.multicolor)
                Text(weather.temperature)
                    .fontWeight(.semibold)
            } else {
                Image(systemName: "cloud.sun")
                    .symbolRenderingMode(.multicolor)
                if weatherManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
        }
        .font(.headline)
        .foregroundStyle(.foregroundOutside)
        .shadow(color: .foregroundShadowOutside, radius: 3)
        .experimentalConfiguration(cornerRadius: 15)
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .onTapGesture {
            SystemUIHelper.openWeatherDropdown()
        }
        .onAppear {
            weatherManager.startUpdating()
        }
    }
}

// MARK: - Weather Data Model

struct CurrentWeather {
    let temperature: String
    let symbolName: String
    let condition: String
}

// MARK: - Open-Meteo API Response

struct OpenMeteoResponse: Codable {
    let currentWeather: OpenMeteoCurrentWeather

    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
    }
}

struct OpenMeteoCurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int
}

// MARK: - Weather Manager

@MainActor
final class WeatherManager: NSObject, ObservableObject {
    static let shared = WeatherManager()

    @Published private(set) var currentWeather: CurrentWeather?
    @Published private(set) var isLoading = false

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var updateTimer: Timer?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func startUpdating() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()

        // Update every 15 minutes
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchWeather()
            }
        }
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func fetchWeather() {
        guard let location = lastLocation else { return }

        isLoading = true

        Task {
            do {
                let lat = location.coordinate.latitude
                let lon = location.coordinate.longitude
                let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true&temperature_unit=fahrenheit"

                guard let url = URL(string: urlString) else {
                    isLoading = false
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

                let temp = Int(response.currentWeather.temperature.rounded())
                let symbol = symbolName(for: response.currentWeather.weathercode)
                let condition = conditionName(for: response.currentWeather.weathercode)

                self.currentWeather = CurrentWeather(
                    temperature: "\(temp)°F",
                    symbolName: symbol,
                    condition: condition
                )
            } catch {
                print("Weather fetch error: \(error)")
            }
            isLoading = false
        }
    }

    /// Maps Open-Meteo weather codes to SF Symbols
    private func symbolName(for code: Int) -> String {
        switch code {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67:
            return "cloud.rain.fill"
        case 71, 73, 75, 77:
            return "cloud.snow.fill"
        case 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }

    /// Maps Open-Meteo weather codes to condition names
    private func conditionName(for code: Int) -> String {
        switch code {
        case 0:
            return "Clear"
        case 1:
            return "Mainly Clear"
        case 2:
            return "Partly Cloudy"
        case 3:
            return "Overcast"
        case 45, 48:
            return "Foggy"
        case 51, 53, 55:
            return "Drizzle"
        case 56, 57:
            return "Freezing Drizzle"
        case 61, 63, 65:
            return "Rain"
        case 66, 67:
            return "Freezing Rain"
        case 71, 73, 75:
            return "Snow"
        case 77:
            return "Snow Grains"
        case 80, 81, 82:
            return "Rain Showers"
        case 85, 86:
            return "Snow Showers"
        case 95:
            return "Thunderstorm"
        case 96, 99:
            return "Thunderstorm with Hail"
        default:
            return "Unknown"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            // Only update if location changed significantly (1km)
            if lastLocation == nil || lastLocation!.distance(from: location) > 1000 {
                lastLocation = location
                fetchWeather()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorized ||
            manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            WeatherWidget()
        }.frame(width: 100, height: 50)
    }
}
