//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

@main
struct WeatherAppApp: App {
    @State private var store = WeatherStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
