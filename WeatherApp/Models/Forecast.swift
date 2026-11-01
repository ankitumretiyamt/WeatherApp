//
//  Forecast.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import Foundation

struct Forecast: Decodable {
    let timezone: String
    let units: ForecastUnits
    let current: CurrentWeather
    let hourly: HourlySeries
    let daily: DailySeries

    var hours: [HourPoint] { hourly.points() }
    var days: [DayPoint] { daily.points() }
    var today: DayPoint? { days.first }

    /// Hours from the current local hour forward. `forecast_hours` can still
    /// include the previous slot, so this trims to "now".
    func upcomingHours(limit: Int = 24) -> [HourPoint] {
        let stamp = String(current.time.prefix(13))
        let start = hours.firstIndex { $0.time.hasPrefix(stamp) } ?? 0
        return Array(hours.dropFirst(start).prefix(limit))
    }

    enum CodingKeys: String, CodingKey {
        case timezone
        case units = "current_units"
        case current
        case hourly
        case daily
    }
}

struct ForecastUnits: Decodable, Equatable {
    let temperature: String
    let windSpeed: String

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case windSpeed = "wind_speed_10m"
    }
}

struct CurrentWeather: Decodable {
    let time: String
    let temperature: Double
    let apparentTemperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: Double
    let weatherCode: Int
    let isDay: Int

    var daytime: Bool { isDay == 1 }

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case humidity = "relative_humidity_2m"
        case windSpeed = "wind_speed_10m"
        case windDirection = "wind_direction_10m"
        case weatherCode = "weather_code"
        case isDay = "is_day"
    }
}

struct CurrentConditions: Decodable {
    let temperature: Double
    let weatherCode: Int
    let isDay: Int

    var daytime: Bool { isDay == 1 }

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case isDay = "is_day"
    }
}

struct ConditionsPayload: Decodable {
    let current: CurrentConditions
}

struct HourPoint: Identifiable, Equatable {
    var id: String { time }
    let time: String
    let temperature: Double
    let weatherCode: Int
    let apparentTemperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: Double
    let precipitationProbability: Double?
    let uvIndex: Double?
    let isDay: Bool
}

struct DayPoint: Identifiable, Equatable {
    var id: String { date }
    let date: String
    let weatherCode: Int
    let minimum: Double
    let maximum: Double
    let sunrise: String
    let sunset: String
    let uvIndexMax: Double?
    let precipitationProbability: Double?
}

struct HourlySeries: Decodable {
    let time: [String]
    let temperature: [Double?]
    let weatherCode: [Int?]
    let apparentTemperature: [Double?]
    let humidity: [Double?]
    let windSpeed: [Double?]
    let windDirection: [Double?]
    let precipitationProbability: [Double?]
    let uvIndex: [Double?]
    let isDay: [Int?]

    func points() -> [HourPoint] {
        time.indices.compactMap { index in
            guard
                let temperature = value(self.temperature, at: index),
                let weatherCode = value(self.weatherCode, at: index),
                let apparentTemperature = value(self.apparentTemperature, at: index),
                let humidity = value(self.humidity, at: index),
                let windSpeed = value(self.windSpeed, at: index),
                let windDirection = value(self.windDirection, at: index)
            else { return nil }

            return HourPoint(
                time: time[index],
                temperature: temperature,
                weatherCode: weatherCode,
                apparentTemperature: apparentTemperature,
                humidity: humidity,
                windSpeed: windSpeed,
                windDirection: windDirection,
                precipitationProbability: value(precipitationProbability, at: index),
                uvIndex: value(uvIndex, at: index),
                isDay: value(isDay, at: index) == 1
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case apparentTemperature = "apparent_temperature"
        case humidity = "relative_humidity_2m"
        case windSpeed = "wind_speed_10m"
        case windDirection = "wind_direction_10m"
        case precipitationProbability = "precipitation_probability"
        case uvIndex = "uv_index"
        case isDay = "is_day"
    }
}

struct DailySeries: Decodable {
    let time: [String]
    let weatherCode: [Int?]
    let temperatureMax: [Double?]
    let temperatureMin: [Double?]
    let sunrise: [String]
    let sunset: [String]
    let uvIndexMax: [Double?]
    let precipitationProbabilityMax: [Double?]

    func points() -> [DayPoint] {
        time.indices.compactMap { index in
            guard
                sunrise.indices.contains(index),
                sunset.indices.contains(index),
                let weatherCode = value(self.weatherCode, at: index),
                let maximum = value(temperatureMax, at: index),
                let minimum = value(temperatureMin, at: index)
            else { return nil }

            return DayPoint(
                date: time[index],
                weatherCode: weatherCode,
                minimum: minimum,
                maximum: maximum,
                sunrise: sunrise[index],
                sunset: sunset[index],
                uvIndexMax: value(uvIndexMax, at: index),
                precipitationProbability: value(precipitationProbabilityMax, at: index)
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case sunrise
        case sunset
        case uvIndexMax = "uv_index_max"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

struct CityWeather: Identifiable {
    var id: Int { place.id }
    let place: Place
    var conditions: CurrentConditions?
    var isResolvingWeather: Bool
}

private func value<T>(_ values: [T?], at index: Int) -> T? {
    guard values.indices.contains(index) else { return nil }
    return values[index]
}
