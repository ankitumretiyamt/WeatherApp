//
//  ContentView.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true

    var body: some View {
        ZStack {
            SkyBackground()
            VStack(spacing: 0) {
                Group {
                    switch store.selectedTab {
                    case .home:
                        HomeView()
                    case .details:
                        DetailsView()
                    case .explore:
                        ExploreView()
                    case .saved:
                        SavedView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                FloatingTabBar()
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(store.colorSchemeOverride)
        .task {
            await presentSplash()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            store.appBecameActive()
        }
    }

    private func presentSplash() async {
        let clock = ContinuousClock()
        let start = clock.now
        store.appBecameActive()
        while clock.now - start < .milliseconds(2600) {
            let elapsed = clock.now - start
            if elapsed >= .milliseconds(1300), store.loadState != .loading {
                break
            }
            try? await Task.sleep(for: .milliseconds(60))
        }
        withAnimation(.easeOut(duration: 0.45)) {
            showSplash = false
        }
    }
}

#Preview {
    ContentView()
        .environment(WeatherStore())
}
