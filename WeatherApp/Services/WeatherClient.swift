//
//  WeatherClient.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import Foundation

enum WeatherClientError: Error, Equatable {
    case offline
    case badResponse
    case decoding
}

/// Open-Meteo needs no API key for non-commercial use.
/// Forecast: https://api.open-meteo.com/v1/forecast
/// Geocoding: https://geocoding-api.open-meteo.com/v1/search
/// The default model (best match) is used so UV index is available worldwide.
/// DWD ICON does not publish `uv_index`, so `models=dwd_icon_seamless` is intentionally omitted.
struct WeatherClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func forecast(latitude: Double, longitude: Double) async throws -> Forecast {
        let url = try makeURL(
            base: "https://api.open-meteo.com/v1/forecast",
            items: [
                URLQueryItem(name: "latitude", value: Self.coordinates([latitude])),
                URLQueryItem(name: "longitude", value: Self.coordinates([longitude])),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "forecast_days", value: "7"),
                URLQueryItem(name: "forecast_hours", value: "24"),
                URLQueryItem(
                    name: "current",
                    value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day"
                ),
                URLQueryItem(
                    name: "hourly",
                    value: "temperature_2m,weather_code,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,precipitation_probability,uv_index,is_day"
                ),
                URLQueryItem(
                    name: "daily",
                    value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max"
                )
            ]
        )
        let data = try await fetch(url)
        do {
            return try JSONDecoder().decode(Forecast.self, from: data)
        } catch {
            #if DEBUG
            print("Open-Meteo decode error:", error)
            #endif
            throw WeatherClientError.decoding
        }
    }

    func search(name: String) async throws -> [Place] {
        let url = try makeURL(
            base: "https://geocoding-api.open-meteo.com/v1/search",
            items: [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "count", value: "8"),
                URLQueryItem(name: "language", value: "en")
            ]
        )
        let data = try await fetch(url)
        do {
            return try JSONDecoder().decode(GeocodingResponse.self, from: data).results ?? []
        } catch {
            throw WeatherClientError.decoding
        }
    }

    /// One request covers every city. Open-Meteo accepts comma-separated coordinates
    /// and returns an array, or a single object when only one place is asked for.
    func conditions(for places: [Place]) async throws -> [CurrentConditions] {
        guard !places.isEmpty else { return [] }
        let url = try makeURL(
            base: "https://api.open-meteo.com/v1/forecast",
            items: [
                URLQueryItem(name: "latitude", value: Self.coordinates(places.map(\.latitude))),
                URLQueryItem(name: "longitude", value: Self.coordinates(places.map(\.longitude))),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day")
            ]
        )
        let data = try await fetch(url)
        let decoder = JSONDecoder()
        if places.count == 1, let one = try? decoder.decode(ConditionsPayload.self, from: data) {
            return [one.current]
        }
        do {
            return try decoder.decode([ConditionsPayload].self, from: data).map(\.current)
        } catch {
            if let one = try? decoder.decode(ConditionsPayload.self, from: data) {
                return [one.current]
            }
            throw WeatherClientError.decoding
        }
    }

    private func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("WeatherNow/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data), envelope.error == true {
                throw WeatherClientError.badResponse
            }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw WeatherClientError.badResponse
            }
            return data
        } catch let error as WeatherClientError {
            throw error
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where Self.offlineCodes.contains(error.code) {
            throw WeatherClientError.offline
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw WeatherClientError.badResponse
        }
    }

    private func makeURL(base: String, items: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(string: base) else {
            throw WeatherClientError.badResponse
        }
        components.queryItems = items
        guard let url = components.url else {
            throw WeatherClientError.badResponse
        }
        return url
    }

    private static func coordinates(_ values: [Double]) -> String {
        values.map { value in
            String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), value)
        }
        .joined(separator: ",")
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed,
        .timedOut,
        .internationalRoamingOff,
        .callIsActive
    ]
}

private struct ErrorEnvelope: Decodable {
    let error: Bool?
    let reason: String?
}
