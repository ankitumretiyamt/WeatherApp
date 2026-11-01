//
//  WeatherFormat.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import Foundation

enum WeatherFormat {
    static func temperature(_ value: Double) -> String {
        "\(Int(value.rounded()))°"
    }

    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    static func wind(_ speed: Double, unit: String, direction: Double) -> String {
        "\(Int(speed.rounded())) \(unit) · \(compass(degrees: direction))"
    }

    static func uvText(_ value: Double) -> String {
        let number = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), value)
        return "\(number) · \(uvCategory(value))"
    }

    static func uvCategory(_ value: Double) -> String {
        switch value {
        case ..<3: "Low"
        case ..<6: "Moderate"
        case ..<8: "High"
        case ..<11: "Very high"
        default: "Extreme"
        }
    }

    static func fraction(value: Double, upper: Double) -> Double {
        guard upper > 0 else { return 0 }
        return min(max(value / upper, 0), 1)
    }

    static func feelsLikeNote(actual: Double, apparent: Double) -> String {
        let delta = apparent - actual
        if abs(delta) < 0.5 {
            return "Similar to the actual temperature"
        }
        let amount = temperature(abs(delta))
        if delta > 0 {
            return "\(amount) warmer than the air"
        }
        return "\(amount) cooler than the air"
    }

    /// 16-point compass from meteorological degrees (0 is north, clockwise).
    static func compass(degrees: Double) -> String {
        let names = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        var normalized = degrees.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        let index = Int((normalized + 11.25) / 22.5) % 16
        return names[index]
    }
}

enum WeatherKind {
    static func title(code: Int) -> String {
        switch code {
        case 0: "Clear sky"
        case 1: "Mainly clear"
        case 2: "Partly cloudy"
        case 3: "Overcast"
        case 45: "Fog"
        case 48: "Rime fog"
        case 51: "Light drizzle"
        case 53: "Drizzle"
        case 55: "Dense drizzle"
        case 56, 57: "Freezing drizzle"
        case 61: "Light rain"
        case 63: "Rain"
        case 65: "Heavy rain"
        case 66, 67: "Freezing rain"
        case 71: "Light snow"
        case 73: "Snow"
        case 75: "Heavy snow"
        case 77: "Snow grains"
        case 80: "Light showers"
        case 81: "Showers"
        case 82: "Violent showers"
        case 85: "Snow showers"
        case 86: "Heavy snow showers"
        case 95: "Thunderstorm"
        case 96: "Thunderstorm and hail"
        case 99: "Thunderstorm and heavy hail"
        default: "Unknown conditions"
        }
    }

    static func symbol(code: Int, isDay: Bool) -> String {
        switch code {
        case 0:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1:
            return isDay ? "sun.min.fill" : "moon.stars.fill"
        case 2:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
}

enum WeatherTime {
    static func parse(_ value: String, timeZone: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timeZone) ?? .current
        formatter.dateFormat = value.count > 10 ? "yyyy-MM-dd'T'HH:mm" : "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    static func longDate(timeZone: String, now: Date = .now) -> String {
        format(now, timeZone: timeZone, template: "EEEE d MMM")
    }

    static func clock(_ value: String, timeZone: String) -> String {
        guard let date = parse(value, timeZone: timeZone) else { return value }
        return format(date, timeZone: timeZone, template: "j:mm")
    }

    static func hourChip(_ value: String, timeZone: String) -> String {
        guard let date = parse(value, timeZone: timeZone) else { return value }
        return format(date, timeZone: timeZone, template: "j")
    }

    static func dayLabel(_ value: String, timeZone: String, now: Date = .now) -> String {
        guard let date = parse(value, timeZone: timeZone) else { return value }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone) ?? .current
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return format(date, timeZone: timeZone, template: "EEE")
    }

    static func daylightFraction(now: Date = .now, sunrise: String, sunset: String, timeZone: String) -> Double {
        guard
            let rise = parse(sunrise, timeZone: timeZone),
            let set = parse(sunset, timeZone: timeZone)
        else { return 0 }
        let span = set.timeIntervalSince(rise)
        guard span > 0 else { return 0 }
        return min(max(now.timeIntervalSince(rise) / span, 0), 1)
    }

    private static func format(_ date: Date, timeZone: String, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = TimeZone(identifier: timeZone) ?? .current
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}
