//
//  SavedCityStore.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import Foundation

struct SavedCityStore {
    private let defaults: UserDefaults
    private let key = "weathernow.savedCities"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [Place] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Place].self, from: data)) ?? []
    }

    func save(_ places: [Place]) {
        guard let data = try? JSONEncoder().encode(places) else { return }
        defaults.set(data, forKey: key)
    }
}
