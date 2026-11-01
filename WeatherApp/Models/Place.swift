//
//  Place.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import Foundation

struct Place: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let countryCode: String?
    let admin1: String?
    let timezone: String?

    var shortLocation: String {
        guard let country, !country.isEmpty else { return name }
        return "\(name), \(country)"
    }

    var detailLine: String {
        var parts: [String] = []
        if let admin1, !admin1.isEmpty, admin1.caseInsensitiveCompare(name) != .orderedSame {
            parts.append(admin1)
        }
        if let country, !country.isEmpty {
            parts.append(country)
        }
        return parts.joined(separator: ", ")
    }

    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case country
        case countryCode = "country_code"
        case admin1
        case timezone
    }
}

struct GeocodingResponse: Decodable {
    let results: [Place]?
}
