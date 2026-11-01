//
//  ExploreView.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct ExploreView: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var palette: Palette { Palette.resolve(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            searchField
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    results
                }
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: 480)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: query) {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 3 else {
                store.clearSearch()
                return
            }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await store.search(trimmed)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Explore")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Search for a city, then open it on Home.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            AppearanceButton()
        }
        .foregroundStyle(palette.textPrimary)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.accent)
            TextField(
                "Search cities",
                text: $query,
                prompt: Text("Search cities").foregroundStyle(palette.textSecondary)
            )
            .focused($searchFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .foregroundStyle(palette.textPrimary)
            if store.isSearching {
                ProgressView()
                    .controlSize(.small)
                    .tint(palette.accent)
            } else if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 22)
    }

    @ViewBuilder
    private var results: some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 3 {
            sectionTitle("Results")
            if let message = store.searchFailed {
                note(message)
            } else if store.searchResults.isEmpty && store.isSearching {
                searchingRow("Searching cities")
            } else if store.searchResults.isEmpty {
                note("No cities found for that search.")
            } else {
                cityList(store.searchResults)
            }
        } else if trimmed.isEmpty {
            sectionTitle("Suggested")
            if let message = store.suggestionsNote, store.suggestions.isEmpty {
                note(message)
            } else if store.suggestions.isEmpty && store.isLoadingSuggestions {
                searchingRow("Looking up cities")
            } else if store.suggestions.isEmpty {
                note("Search for a city to see live weather.")
            } else {
                cityList(store.suggestions)
            }
        } else {
            note("Type at least 3 letters to search.")
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(palette.textPrimary)
            .padding(.top, 4)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private func searchingRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(palette.accent)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(palette.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private func cityList(_ cities: [CityWeather]) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(cities) { city in
                CityRow(
                    place: city.place,
                    conditions: city.conditions,
                    isResolving: city.isResolvingWeather,
                    isSelected: store.place?.id == city.place.id,
                    isSaved: store.isSaved(city.place),
                    onSelect: {
                        searchFocused = false
                        Task { await store.select(city.place) }
                    },
                    onToggleSave: {
                        store.toggleSaved(city.place)
                    }
                )
            }
        }
    }
}
