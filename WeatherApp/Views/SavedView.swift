//
//  SavedView.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct SavedView: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    private var palette: Palette { Palette.resolve(colorScheme) }

    var body: some View {
        ScreenScroll {
            VStack(alignment: .leading, spacing: 18) {
                header
                StatusBanner()
                ForecastGate { _, forecast in
                    weekCard(forecast)
                }
                savedSection
                AttributionLabel()
            }
        }
        .refreshable {
            await store.refresh()
            await store.refreshSavedConditions()
        }
        .task(id: store.savedCities.map(\.id)) {
            await store.refreshSavedConditions()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Forecast")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                if let place = store.place {
                    Text(place.shortLocation)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            AppearanceButton()
        }
        .foregroundStyle(palette.textPrimary)
    }

    private func weekCard(_ forecast: Forecast) -> some View {
        let days = forecast.days
        let weekLow = days.map(\.minimum).min() ?? 0
        let weekHigh = days.map(\.maximum).max() ?? 1
        return VStack(alignment: .leading, spacing: 4) {
            Text("7-day forecast")
                .font(.headline)
                .padding(.bottom, 8)
            if days.isEmpty {
                Text("The daily forecast isn't available for this city.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            } else {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    dayRow(day, timeZone: forecast.timezone, weekLow: weekLow, weekHigh: weekHigh)
                    if index < days.count - 1 {
                        Rectangle()
                            .fill(palette.stroke)
                            .frame(height: 1)
                            .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
        .foregroundStyle(palette.textPrimary)
    }

    private func dayRow(_ day: DayPoint, timeZone: String, weekLow: Double, weekHigh: Double) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(WeatherTime.dayLabel(day.date, timeZone: timeZone))
                    .font(.subheadline.weight(.semibold))
                if let rain = day.precipitationProbability, rain >= 10 {
                    Text(WeatherFormat.percent(rain))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
            }
            .frame(width: 88, alignment: .leading)

            Image(systemName: WeatherKind.symbol(code: day.weatherCode, isDay: true))
                .foregroundStyle(palette.accent)
                .frame(width: 24)
                .accessibilityLabel(WeatherKind.title(code: day.weatherCode))

            Text(WeatherFormat.temperature(day.minimum))
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 36, alignment: .trailing)

            TemperatureRangeBar(
                low: day.minimum,
                high: day.maximum,
                weekLow: weekLow,
                weekHigh: weekHigh,
                tint: palette.accent,
                track: palette.textPrimary.opacity(0.12)
            )

            Text(WeatherFormat.temperature(day.maximum))
                .font(.caption.weight(.bold))
                .frame(width: 36, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved cities")
                .font(.title3.weight(.bold))
                .foregroundStyle(palette.textPrimary)
            if store.savedCities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.title2)
                        .foregroundStyle(palette.accent)
                    Text("No saved cities yet")
                        .font(.headline)
                    Text("Bookmark a city from Home or Explore and it stays on this phone.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .glassCard()
                .foregroundStyle(palette.textPrimary)
            } else {
                ForEach(store.savedCities) { place in
                    CityRow(
                        place: place,
                        conditions: store.conditions(for: place),
                        isResolving: store.conditions(for: place) == nil,
                        isSelected: store.place?.id == place.id,
                        isSaved: true,
                        onSelect: {
                            Task {
                                let loaded = await store.select(place)
                                if loaded {
                                    store.selectedTab = .home
                                }
                            }
                        },
                        onToggleSave: {
                            store.toggleSaved(place)
                        }
                    )
                }
            }
        }
    }
}

private struct TemperatureRangeBar: View {
    let low: Double
    let high: Double
    let weekLow: Double
    let weekHigh: Double
    let tint: Color
    let track: Color

    var body: some View {
        GeometryReader { geo in
            let span = max(weekHigh - weekLow, 0.5)
            let start = min(max((low - weekLow) / span, 0), 1)
            let end = min(max((high - weekLow) / span, 0), 1)
            let width = geo.size.width
            let barWidth = min(max(8, (end - start) * width), width)
            let origin = min(start * width, max(width - barWidth, 0))
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.55), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: barWidth)
                    .offset(x: origin)
            }
        }
        .frame(height: 8)
    }
}
