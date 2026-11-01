//
//  HomeView.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    private var palette: Palette { Palette.resolve(colorScheme) }

    var body: some View {
        ScreenScroll {
            VStack(alignment: .leading, spacing: 14) {
                header
                StatusBanner()
                ForecastGate { _, forecast in
                    VStack(alignment: .leading, spacing: 14) {
                        hero(forecast)
                        highlights(forecast)
                        sunStrip(forecast)
                        AttributionLabel()
                    }
                }
            }
        }
        .refreshable {
            await store.refresh()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(palette.accent)
                    Text(locationTitle)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                Text(dateText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                RoundIconButton(symbol: "location", label: "Use my location") {
                    Task { await store.useDeviceLocation() }
                }
                if let place = store.place {
                    RoundIconButton(
                        symbol: store.isSaved(place) ? "bookmark.fill" : "bookmark",
                        label: store.isSaved(place) ? "Remove saved city" : "Save city"
                    ) {
                        store.toggleSaved(place)
                    }
                }
                AppearanceButton()
            }
        }
        .foregroundStyle(palette.textPrimary)
    }

    private var locationTitle: String {
        if let place = store.place {
            return place.shortLocation
        }
        if case .failed = store.loadState {
            return "WeatherNow"
        }
        return "Finding your city"
    }

    private var dateText: String {
        WeatherTime.longDate(timeZone: store.forecast?.timezone ?? TimeZone.current.identifier)
    }

    private func hero(_ forecast: Forecast) -> some View {
        let code = forecast.current.weatherCode
        let daytime = forecast.current.daytime
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(palette.accent.opacity(0.38))
                    .frame(width: 108, height: 108)
                    .blur(radius: 14)
                Image(systemName: WeatherKind.symbol(code: code, isDay: daytime))
                    .font(.system(size: 62))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(palette.accent, Color.white.opacity(0.92))
                    .shadow(color: palette.accent.opacity(0.45), radius: 12, y: 4)
                    .accessibilityHidden(true)
            }
            .padding(.top, 2)

            Text(WeatherFormat.temperature(forecast.current.temperature))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [palette.textPrimary, palette.accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())

            Text(WeatherKind.title(code: code))
                .font(.title3.weight(.semibold))

            if let today = forecast.today {
                HStack(spacing: 18) {
                    highLow("arrow.up", "High", today.maximum)
                    highLow("arrow.down", "Low", today.minimum)
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .glassCard()
        .foregroundStyle(palette.textPrimary)
    }

    private func highLow(_ symbol: String, _ title: String, _ value: Double) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.accent)
            Text(title)
                .foregroundStyle(palette.textSecondary)
            Text(WeatherFormat.temperature(value))
                .fontWeight(.bold)
        }
        .font(.subheadline)
    }

    private func highlights(_ forecast: Forecast) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            metric("thermometer.medium", "Feels like", WeatherFormat.temperature(forecast.current.apparentTemperature))
            metric("humidity.fill", "Humidity", WeatherFormat.percent(forecast.current.humidity))
            metric(
                "wind",
                "Wind",
                WeatherFormat.wind(
                    forecast.current.windSpeed,
                    unit: forecast.units.windSpeed,
                    direction: forecast.current.windDirection
                )
            )
            metric("sun.max", "UV index", uvValue(forecast))
        }
    }

    private func uvValue(_ forecast: Forecast) -> String {
        if let uv = forecast.today?.uvIndexMax ?? forecast.upcomingHours(limit: 1).first?.uvIndex {
            return WeatherFormat.uvText(uv)
        }
        return "—"
    }

    private func metric(_ symbol: String, _ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 34, height: 34)
                .background(palette.accent.opacity(0.16), in: Circle())
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textSecondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 22)
    }

    @ViewBuilder
    private func sunStrip(_ forecast: Forecast) -> some View {
        if let today = forecast.today {
            let fraction = WeatherTime.daylightFraction(
                sunrise: today.sunrise,
                sunset: today.sunset,
                timeZone: forecast.timezone
            )
            VStack(alignment: .leading, spacing: 14) {
                Text("Daylight")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
                HStack(spacing: 10) {
                    sunColumn("sunrise.fill", "Sunrise", WeatherTime.clock(today.sunrise, timeZone: forecast.timezone))
                    daylightTrack(fraction)
                    sunColumn("sunset.fill", "Sunset", WeatherTime.clock(today.sunset, timeZone: forecast.timezone))
                }
            }
            .padding(16)
            .glassCard()
            .foregroundStyle(palette.textPrimary)
        }
    }

    private func sunColumn(_ symbol: String, _ title: String, _ time: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .foregroundStyle(palette.accent)
            Text(time)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(width: 78)
    }

    private func daylightTrack(_ fraction: Double) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let icon = fraction > 0.02 && fraction < 0.98 ? "sun.max.fill" : "moon.fill"
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.textPrimary.opacity(0.12))
                    .frame(height: 4)
                Circle()
                    .fill(palette.accent)
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(palette.onAccent)
                    }
                    .shadow(color: palette.accent.opacity(0.55), radius: 6)
                    .offset(x: max(0, min(width - 22, (width - 22) * fraction)))
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 28)
        .accessibilityLabel("Daylight progress")
    }
}
