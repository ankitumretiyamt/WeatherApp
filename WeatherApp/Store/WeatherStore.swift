//
//  WeatherStore.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import CoreLocation
import Foundation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case details
    case explore
    case saved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .details: "Details"
        case .explore: "Explore"
        case .saved: "Saved"
        }
    }

    func symbol(selected: Bool) -> String {
        switch self {
        case .home: selected ? "house.fill" : "house"
        case .details: "chart.xyaxis.line"
        case .explore: "magnifyingglass"
        case .saved: selected ? "bookmark.fill" : "bookmark"
        }
    }
}

enum LoadFailure: Equatable {
    case offline
    case unavailable
    case locationDenied
    case locationUnavailable

    init(_ error: Error) {
        switch error {
        case WeatherClientError.offline:
            self = .offline
        case LocationAccessError.denied:
            self = .locationDenied
        case LocationAccessError.unavailable:
            self = .locationUnavailable
        default:
            self = .unavailable
        }
    }

    var title: String {
        switch self {
        case .offline: "You're offline"
        case .unavailable: "Weather is unavailable"
        case .locationDenied: "Location is off"
        case .locationUnavailable: "Location not found"
        }
    }

    var message: String {
        switch self {
        case .offline:
            "No internet connection. Check your network and try again."
        case .unavailable:
            "The weather service didn't respond. Please try again."
        case .locationDenied:
            "Allow location access to see weather for where you are, or search for a city."
        case .locationUnavailable:
            "We couldn't read your position. Search for a city instead."
        }
    }

    var symbol: String {
        switch self {
        case .offline: "wifi.slash"
        case .unavailable: "cloud.slash"
        case .locationDenied, .locationUnavailable: "location.slash"
        }
    }

    var suggestsSearch: Bool {
        switch self {
        case .locationDenied, .locationUnavailable: true
        case .offline, .unavailable: false
        }
    }
}

enum LoadState: Equatable {
    case loading
    case loaded
    case failed(LoadFailure)
}

@MainActor
@Observable
final class WeatherStore {
    private let client: WeatherClient
    private let locationProvider: LocationProvider
    private let savedCityStore: SavedCityStore
    private var didStart = false
    private var loadGeneration = 0

    var selectedTab: AppTab = .home
    var colorSchemeOverride: ColorScheme? {
        didSet { Self.storeAppearance(colorSchemeOverride) }
    }

    var place: Place?
    var forecast: Forecast?
    var usingDeviceLocation = false
    var loadState: LoadState = .loading
    var banner: String?

    var savedCities: [Place] = []
    var savedConditions: [Int: CurrentConditions] = [:]

    var suggestions: [CityWeather] = []
    var isLoadingSuggestions = false
    var suggestionsNote: String?

    var searchResults: [CityWeather] = []
    var isSearching = false
    var searchFailed: String?
    private var searchGeneration = 0

    /// Queries sent to the geocoding API when Explore is empty.
    /// Names are only search terms. Temperatures always come back from the forecast API.
    private static let suggestedQueries = ["London", "Tokyo", "New York", "Sydney", "Paris", "Mumbai", "Lisbon", "Dubai"]
    private static let appearanceKey = "weathernow.appearance"

    init(
        client: WeatherClient = WeatherClient(),
        locationProvider: LocationProvider? = nil,
        savedCityStore: SavedCityStore = SavedCityStore()
    ) {
        self.client = client
        self.locationProvider = locationProvider ?? LocationProvider()
        self.savedCityStore = savedCityStore
        switch UserDefaults.standard.string(forKey: Self.appearanceKey) {
        case "dark": colorSchemeOverride = .dark
        case "light": colorSchemeOverride = .light
        default: colorSchemeOverride = nil
        }
        savedCities = savedCityStore.load()
    }

    /// Cold launch always opens Home and loads the forecast for this device.
    /// Coming back to the app refreshes that same location. A city chosen in
    /// Explore stays put until the next launch.
    func appBecameActive() {
        if !didStart {
            didStart = true
            selectedTab = .home
            Task { await loadSuggestions() }
            Task { await loadDeviceForecast(keepPreviousOnFailure: false) }
            return
        }
        guard usingDeviceLocation else { return }
        Task { await loadDeviceForecast(keepPreviousOnFailure: true) }
    }

    func refresh() async {
        banner = nil
        if usingDeviceLocation || place == nil {
            await loadDeviceForecast(keepPreviousOnFailure: forecast != nil)
        } else if let place {
            await loadForecast(for: place, keepVisible: true)
        }
    }

    func retry() async {
        banner = nil
        if usingDeviceLocation || place == nil {
            await loadDeviceForecast(keepPreviousOnFailure: false)
        } else if let place {
            await loadForecast(for: place, keepVisible: false)
        }
    }

    func useDeviceLocation() async {
        await loadDeviceForecast(keepPreviousOnFailure: forecast != nil)
    }

    func toggleColorScheme(current: ColorScheme) {
        colorSchemeOverride = current == .dark ? .light : .dark
    }

    @discardableResult
    func select(_ place: Place) async -> Bool {
        usingDeviceLocation = false
        self.place = place
        return await loadForecast(for: place, keepVisible: false)
    }

    func isSaved(_ place: Place) -> Bool {
        savedCities.contains(place)
    }

    func toggleSaved(_ place: Place) {
        if let index = savedCities.firstIndex(of: place) {
            savedCities.remove(at: index)
            savedConditions[place.id] = nil
        } else {
            savedCities.insert(place, at: 0)
            if let forecast, self.place?.id == place.id {
                savedConditions[place.id] = CurrentConditions(
                    temperature: forecast.current.temperature,
                    weatherCode: forecast.current.weatherCode,
                    isDay: forecast.current.isDay
                )
            }
        }
        savedCityStore.save(savedCities)
    }

    func conditions(for place: Place) -> CurrentConditions? {
        if let cached = savedConditions[place.id] {
            return cached
        }
        guard place.id == self.place?.id, let forecast else { return nil }
        return CurrentConditions(
            temperature: forecast.current.temperature,
            weatherCode: forecast.current.weatherCode,
            isDay: forecast.current.isDay
        )
    }

    func refreshSavedConditions() async {
        let places = savedCities
        guard !places.isEmpty else { return }
        do {
            let conditions = try await client.conditions(for: places)
            guard !Task.isCancelled else { return }
            var map = savedConditions
            for (place, condition) in zip(places, conditions) {
                map[place.id] = condition
            }
            savedConditions = map
        } catch {
            return
        }
    }

    func clearSearch() {
        searchGeneration += 1
        searchResults = []
        searchFailed = nil
        isSearching = false
    }

    func search(_ query: String) async {
        searchGeneration += 1
        let generation = searchGeneration
        isSearching = true
        searchFailed = nil
        do {
            let places = try await client.search(name: query)
            guard generation == searchGeneration else { return }
            var rows = places.map { CityWeather(place: $0, conditions: nil, isResolvingWeather: true) }
            searchResults = rows
            guard !places.isEmpty else {
                isSearching = false
                return
            }
            let conditions = try await client.conditions(for: places)
            guard generation == searchGeneration else { return }
            for index in rows.indices {
                rows[index].isResolvingWeather = false
                if index < conditions.count {
                    rows[index].conditions = conditions[index]
                }
            }
            searchResults = rows
            isSearching = false
        } catch is CancellationError {
            return
        } catch {
            guard generation == searchGeneration else { return }
            searchResults = []
            searchFailed = LoadFailure(error).message
            isSearching = false
        }
    }

    private func loadDeviceForecast(keepPreviousOnFailure: Bool) async {
        let generation = nextGeneration()
        let previousPlace = place
        let previousForecast = forecast
        let wasUsingDevice = usingDeviceLocation
        if !keepPreviousOnFailure {
            loadState = .loading
        }

        do {
            let location = try await locationProvider.requestCurrentLocation()
            guard isCurrent(generation) else { return }
            let resolved = await resolve(location)
            guard isCurrent(generation) else { return }
            place = resolved
            let result = try await client.forecast(latitude: resolved.latitude, longitude: resolved.longitude)
            guard isCurrent(generation) else { return }
            place = resolved
            forecast = result
            usingDeviceLocation = true
            loadState = .loaded
            banner = nil
        } catch is CancellationError {
            return
        } catch {
            guard isCurrent(generation) else { return }
            if keepPreviousOnFailure, previousForecast != nil {
                place = previousPlace
                forecast = previousForecast
                usingDeviceLocation = wasUsingDevice
                loadState = .loaded
                banner = LoadFailure(error).message
            } else {
                forecast = nil
                loadState = .failed(LoadFailure(error))
            }
        }
    }

    @discardableResult
    private func loadForecast(for place: Place, keepVisible: Bool) async -> Bool {
        let generation = nextGeneration()
        if !keepVisible {
            forecast = nil
            loadState = .loading
        }
        do {
            let result = try await client.forecast(latitude: place.latitude, longitude: place.longitude)
            guard isCurrent(generation) else { return false }
            self.place = place
            forecast = result
            loadState = .loaded
            banner = nil
            if savedCities.contains(place) {
                savedConditions[place.id] = CurrentConditions(
                    temperature: result.current.temperature,
                    weatherCode: result.current.weatherCode,
                    isDay: result.current.isDay
                )
            }
            return true
        } catch is CancellationError {
            return false
        } catch {
            guard isCurrent(generation) else { return false }
            if forecast == nil {
                loadState = .failed(LoadFailure(error))
            } else {
                banner = LoadFailure(error).message
            }
            return false
        }
    }

    private func loadSuggestions() async {
        isLoadingSuggestions = true
        suggestionsNote = nil
        defer { isLoadingSuggestions = false }

        let api = client
        let queries = Self.suggestedQueries
        let matches: [(Int, Place)] = await withTaskGroup(of: (Int, Place)?.self) { group in
            for (index, name) in queries.enumerated() {
                group.addTask {
                    guard let place = (try? await api.search(name: name))?.first else { return nil }
                    return (index, place)
                }
            }
            var found: [(Int, Place)] = []
            for await match in group {
                if let match {
                    found.append(match)
                }
            }
            return found
        }

        let ordered = uniquePlaces(matches.sorted { $0.0 < $1.0 }.map(\.1))
        guard !ordered.isEmpty else {
            suggestions = []
            suggestionsNote = "Suggested cities couldn't be loaded. You can still search."
            return
        }

        var rows = ordered.map { CityWeather(place: $0, conditions: nil, isResolvingWeather: true) }
        suggestions = rows
        do {
            let conditions = try await api.conditions(for: ordered)
            for index in rows.indices {
                rows[index].isResolvingWeather = false
                if index < conditions.count {
                    rows[index].conditions = conditions[index]
                }
            }
            suggestions = rows
        } catch {
            for index in rows.indices {
                rows[index].isResolvingWeather = false
            }
            suggestions = rows
        }
    }

    /// Name comes from the nearest city when one is close. The forecast itself
    /// always uses the device coordinates.
    private func resolve(_ location: CLLocation) async -> Place {
        let described = await locationProvider.describe(location)
        var name = described.name
        var country = described.country.isEmpty ? nil : described.country
        var admin = described.admin
        var id = Self.syntheticID(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        var timezone = TimeZone.current.identifier

        if described.name != "Current location",
           let results = try? await client.search(name: described.name) {
            let nearest = results.min { lhs, rhs in
                distance(lhs, location) < distance(rhs, location)
            }
            if let nearest, distance(nearest, location) < 40_000 {
                name = nearest.name
                country = nearest.country ?? country
                admin = nearest.admin1 ?? admin
                id = nearest.id
                timezone = nearest.timezone ?? timezone
            }
        }

        return Place(
            id: id,
            name: name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            country: country,
            countryCode: nil,
            admin1: admin,
            timezone: timezone
        )
    }

    private func distance(_ place: Place, _ location: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: place.latitude, longitude: place.longitude).distance(from: location)
    }

    private func uniquePlaces(_ places: [Place]) -> [Place] {
        var seen = Set<Int>()
        return places.filter { seen.insert($0.id).inserted }
    }

    private static func syntheticID(latitude: Double, longitude: Double) -> Int {
        let lat = Int((latitude * 100).rounded())
        let lon = Int((longitude * 100).rounded())
        return -(abs(lat &* 100_000 &+ lon) + 1)
    }

    private func nextGeneration() -> Int {
        loadGeneration += 1
        return loadGeneration
    }

    private func isCurrent(_ generation: Int) -> Bool {
        generation == loadGeneration && !Task.isCancelled
    }

    private static func storeAppearance(_ scheme: ColorScheme?) {
        let defaults = UserDefaults.standard
        switch scheme {
        case .dark:
            defaults.set("dark", forKey: appearanceKey)
        case .light:
            defaults.set("light", forKey: appearanceKey)
        case nil:
            defaults.removeObject(forKey: appearanceKey)
        @unknown default:
            defaults.removeObject(forKey: appearanceKey)
        }
    }
}
