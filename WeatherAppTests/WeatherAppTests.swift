//
//  WeatherAppTests.swift
//  WeatherAppTests
//
//  Created by Ankit Umretiya on 30/10/26.
//

import Foundation
import Testing
@testable import WeatherApp

struct WeatherAppTests {
    @Test func compassDirections() {
        #expect(WeatherFormat.compass(degrees: 0) == "N")
        #expect(WeatherFormat.compass(degrees: 90) == "E")
        #expect(WeatherFormat.compass(degrees: 180) == "S")
        #expect(WeatherFormat.compass(degrees: 270) == "W")
        #expect(WeatherFormat.compass(degrees: 278) == "W")
        #expect(WeatherFormat.compass(degrees: 360) == "N")
        #expect(WeatherFormat.compass(degrees: -10) == "N")
    }

    @Test func uvCategoriesAndFeelsLike() {
        #expect(WeatherFormat.uvCategory(2) == "Low")
        #expect(WeatherFormat.uvCategory(3) == "Moderate")
        #expect(WeatherFormat.uvCategory(6) == "High")
        #expect(WeatherFormat.uvCategory(8) == "Very high")
        #expect(WeatherFormat.uvCategory(11) == "Extreme")
        #expect(WeatherFormat.feelsLikeNote(actual: 20, apparent: 20.2) == "Similar to the actual temperature")
        #expect(WeatherFormat.feelsLikeNote(actual: 20, apparent: 22) == "2° warmer than the air")
        #expect(WeatherFormat.feelsLikeNote(actual: 20, apparent: 18) == "2° cooler than the air")
    }

    @Test func weatherCodeMapping() {
        #expect(WeatherKind.title(code: 2) == "Partly cloudy")
        #expect(WeatherKind.symbol(code: 0, isDay: true) == "sun.max.fill")
        #expect(WeatherKind.symbol(code: 0, isDay: false) == "moon.stars.fill")
        #expect(WeatherKind.symbol(code: 95, isDay: true) == "cloud.bolt.rain.fill")
        #expect(WeatherKind.symbol(code: 71, isDay: true) == "cloud.snow.fill")
    }

    @Test func decodesLiveForecastShape() throws {
        let forecast = try JSONDecoder().decode(Forecast.self, from: Data(SampleForecast.json.utf8))
        #expect(forecast.current.temperature == 21.4)
        #expect(forecast.units.windSpeed == "km/h")
        #expect(forecast.hours.count == 2)
        #expect(forecast.upcomingHours().first?.time == "2026-10-30T15:00")
        #expect(forecast.upcomingHours().first?.temperature == 21)
        #expect(forecast.upcomingHours().first?.uvIndex == nil)
        #expect(forecast.today?.maximum == 24.2)
        #expect(forecast.today?.uvIndexMax == 3.2)
    }

    @Test func dayLabelUsesTheCityTimeZone() throws {
        let now = try #require(WeatherTime.parse("2026-10-30T12:00", timeZone: "Europe/Berlin"))
        #expect(WeatherTime.dayLabel("2026-10-30", timeZone: "Europe/Berlin", now: now) == "Today")
        #expect(WeatherTime.dayLabel("2026-10-31", timeZone: "Europe/Berlin", now: now) == "Tomorrow")
        let fraction = WeatherTime.daylightFraction(
            now: now,
            sunrise: "2026-10-30T06:58",
            sunset: "2026-10-30T16:40",
            timeZone: "Europe/Berlin"
        )
        #expect(fraction > 0.4)
        #expect(fraction < 0.6)
    }
}

private enum SampleForecast {
    static let json = """
    {
      "timezone": "Europe/Berlin",
      "current_units": { "temperature_2m": "°C", "wind_speed_10m": "km/h" },
      "current": {
        "time": "2026-10-30T15:15",
        "temperature_2m": 21.4,
        "apparent_temperature": 20.0,
        "relative_humidity_2m": 60,
        "wind_speed_10m": 12.2,
        "wind_direction_10m": 278,
        "weather_code": 2,
        "is_day": 1
      },
      "hourly": {
        "time": ["2026-10-30T14:00", "2026-10-30T15:00"],
        "temperature_2m": [19.0, 21.0],
        "weather_code": [3, 2],
        "apparent_temperature": [18.0, 20.0],
        "relative_humidity_2m": [70, 60],
        "wind_speed_10m": [10, 12],
        "wind_direction_10m": [270, 280],
        "precipitation_probability": [10, null],
        "uv_index": [1.5, null],
        "is_day": [1, 1]
      },
      "daily": {
        "time": ["2026-10-30"],
        "weather_code": [2],
        "temperature_2m_max": [24.2],
        "temperature_2m_min": [15.4],
        "sunrise": ["2026-10-30T06:58"],
        "sunset": ["2026-10-30T16:40"],
        "uv_index_max": [3.2],
        "precipitation_probability_max": [20]
      }
    }
    """
}
