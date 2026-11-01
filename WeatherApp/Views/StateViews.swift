//
//  StateViews.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI
import UIKit

struct ForecastGate<Content: View>: View {
    @Environment(WeatherStore.self) private var store
    @ViewBuilder var content: (Place, Forecast) -> Content

    var body: some View {
        if case .failed(let failure) = store.loadState, store.forecast == nil {
            FailureState(failure: failure)
        } else if let place = store.place, let forecast = store.forecast {
            content(place, forecast)
        } else {
            LoadingState()
        }
    }
}

struct LoadingState: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = Palette.resolve(colorScheme)
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(palette.accent)
            Text("Fetching the latest weather")
                .font(.headline)
            Text("Live data from Open-Meteo")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .glassCard()
        .foregroundStyle(palette.textPrimary)
        .padding(.top, 12)
    }
}

struct FailureState: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    let failure: LoadFailure

    var body: some View {
        let palette = Palette.resolve(colorScheme)
        VStack(spacing: 14) {
            Image(systemName: failure.symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(palette.accent)
            Text(failure.title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            Text(failure.message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textSecondary)
            Button {
                Task { await store.retry() }
            } label: {
                Text("Try again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(palette.accent, in: Capsule())
                    .foregroundStyle(palette.onAccent)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            if failure.suggestsSearch {
                Button {
                    store.selectedTab = .explore
                } label: {
                    Text("Search cities")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.accent.opacity(0.16), in: Capsule())
                        .foregroundStyle(palette.accent)
                }
                .buttonStyle(.plain)
            }

            if failure == .locationDenied {
                Button("Open Settings", action: openSettings)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .glassCard()
        .foregroundStyle(palette.textPrimary)
        .padding(.top, 12)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct StatusBanner: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let banner = store.banner {
            let palette = Palette.resolve(colorScheme)
            Button {
                store.banner = nil
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Text(banner)
                        .font(.footnote.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .padding(.top, 2)
                }
                .foregroundStyle(palette.textPrimary)
                .padding(14)
                .glassCard(cornerRadius: 18)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss. \(banner)")
        }
    }
}
