//
//  DetailsView.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct DetailsView: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTime: String?

    private var palette: Palette { Palette.resolve(colorScheme) }

    var body: some View {
        ScreenScroll {
            VStack(alignment: .leading, spacing: 18) {
                header
                StatusBanner()
                ForecastGate { place, forecast in
                    let hours = forecast.upcomingHours()
                    let selected = hours.first { $0.time == selectedTime } ?? hours.first
                    VStack(alignment: .leading, spacing: 18) {
                        if hours.isEmpty {
                            Text("The hourly forecast isn't available for \(place.name) right now.")
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                        } else if let selected {
                            hourScroller(hours, selected: selected, timeZone: forecast.timezone)
                            chartCard(hours, timeZone: forecast.timezone)
                            detailCard(selected, forecast: forecast)
                        }
                        AttributionLabel()
                    }
                    .onChange(of: forecast.current.time) { _, _ in
                        selectedTime = nil
                    }
                }
            }
        }
        .refreshable {
            await store.refresh()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Details")
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

    private func hourScroller(_ hours: [HourPoint], selected: HourPoint, timeZone: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                    Button {
                        selectedTime = hour.time
                    } label: {
                        chip(hour, isNow: index == 0, isSelected: hour.time == selected.time, timeZone: timeZone)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ hour: HourPoint, isNow: Bool, isSelected: Bool, timeZone: String) -> some View {
        let title = isNow ? "Now" : WeatherTime.hourChip(hour.time, timeZone: timeZone)
        let rain = hour.precipitationProbability ?? 0
        return VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
            Image(systemName: WeatherKind.symbol(code: hour.weatherCode, isDay: hour.isDay))
                .font(.title3)
                .foregroundStyle(isSelected ? palette.onAccent : palette.accent)
            Text(WeatherFormat.temperature(hour.temperature))
                .font(.subheadline.weight(.bold))
            Text(rain >= 15 ? WeatherFormat.percent(rain) : " ")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isSelected ? palette.onAccent.opacity(0.85) : palette.accent)
        }
        .foregroundStyle(isSelected ? palette.onAccent : palette.textPrimary)
        .frame(width: 74)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? palette.accent : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.40))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.65), lineWidth: 1)
        }
        .accessibilityLabel("\(title), \(WeatherFormat.temperature(hour.temperature)), \(WeatherKind.title(code: hour.weatherCode))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func chartCard(_ hours: [HourPoint], timeZone: String) -> some View {
        let temps = hours.map(\.temperature)
        let low = temps.min() ?? 0
        let high = temps.max() ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Temperature curve")
                    .font(.headline)
                Spacer()
                Text("\(WeatherFormat.temperature(low)) – \(WeatherFormat.temperature(high))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            if hours.count > 1 {
                TemperatureChart(values: temps, accent: palette.accent, secondary: palette.glowCyan)
                    .frame(height: 150)
                HStack {
                    Text("Now")
                    Spacer()
                    Text(WeatherTime.hourChip(hours[hours.count / 2].time, timeZone: timeZone))
                    Spacer()
                    Text(WeatherTime.hourChip(hours[hours.count - 1].time, timeZone: timeZone))
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(16)
        .glassCard()
        .foregroundStyle(palette.textPrimary)
    }

    private func detailCard(_ hour: HourPoint, forecast: Forecast) -> some View {
        let uv = hour.uvIndex ?? forecast.today?.uvIndexMax
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Feels like", systemImage: "thermometer.medium")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    Text(WeatherFormat.temperature(hour.apparentTemperature))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
                Text(WeatherFormat.feelsLikeNote(actual: hour.temperature, apparent: hour.apparentTemperature))
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }

            divider

            meterRow(
                "wind",
                "Wind",
                WeatherFormat.wind(hour.windSpeed, unit: forecast.units.windSpeed, direction: hour.windDirection),
                WeatherFormat.fraction(value: hour.windSpeed, upper: 50)
            )
            divider
            meterRow(
                "humidity.fill",
                "Humidity",
                WeatherFormat.percent(hour.humidity),
                WeatherFormat.fraction(value: hour.humidity, upper: 100)
            )
            divider
            meterRow(
                "sun.max",
                "UV index",
                uv.map(WeatherFormat.uvText) ?? "—",
                WeatherFormat.fraction(value: uv ?? 0, upper: 11)
            )
        }
        .padding(18)
        .glassCard()
        .foregroundStyle(palette.textPrimary)
        .labelStyle(.titleAndIcon)
    }

    private func meterRow(_ symbol: String, _ title: String, _ value: String, _ fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(palette.accent)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
                Spacer(minLength: 8)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            MeterBar(fraction: fraction, tint: palette.accent, track: palette.textPrimary.opacity(0.12))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.stroke)
            .frame(height: 1)
    }
}

private struct MeterBar: View {
    let fraction: Double
    let tint: Color
    let track: Color

    var body: some View {
        GeometryReader { geo in
            let width = max(8, geo.size.width * min(max(fraction, 0), 1))
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.65), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: min(width, geo.size.width))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Level \(Int((fraction * 100).rounded())) percent")
    }
}

private struct TemperatureChart: View {
    let values: [Double]
    let accent: Color
    let secondary: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 0
            let span = max(maxValue - minValue, 1)
            let plot = CGRect(x: 8, y: 12, width: size.width - 16, height: size.height - 24)

            func point(at index: Int) -> CGPoint {
                let x = plot.minX + plot.width * CGFloat(index) / CGFloat(values.count - 1)
                let normalized = (values[index] - minValue) / span
                let y = plot.maxY - plot.height * CGFloat(normalized)
                return CGPoint(x: x, y: y)
            }

            let points = values.indices.map(point(at:))
            var line = Path()
            line.move(to: points[0])
            if points.count == 2 {
                line.addLine(to: points[1])
            } else {
                for index in 0..<(points.count - 1) {
                    let previous = points[max(index - 1, 0)]
                    let current = points[index]
                    let next = points[index + 1]
                    let after = points[min(index + 2, points.count - 1)]
                    let control1 = CGPoint(
                        x: current.x + (next.x - previous.x) / 6,
                        y: current.y + (next.y - previous.y) / 6
                    )
                    let control2 = CGPoint(
                        x: next.x - (after.x - current.x) / 6,
                        y: next.y - (after.y - current.y) / 6
                    )
                    line.addCurve(to: next, control1: control1, control2: control2)
                }
            }

            var fill = line
            fill.addLine(to: CGPoint(x: points[points.count - 1].x, y: plot.maxY))
            fill.addLine(to: CGPoint(x: points[0].x, y: plot.maxY))
            fill.closeSubpath()

            context.fill(
                fill,
                with: .linearGradient(
                    Gradient(colors: [accent.opacity(0.42), accent.opacity(0.02)]),
                    startPoint: CGPoint(x: plot.midX, y: plot.minY),
                    endPoint: CGPoint(x: plot.midX, y: plot.maxY)
                )
            )
            context.stroke(
                line,
                with: .linearGradient(
                    Gradient(colors: [secondary, accent]),
                    startPoint: CGPoint(x: plot.minX, y: plot.midY),
                    endPoint: CGPoint(x: plot.maxX, y: plot.midY)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )

            let now = points[0]
            let dot = CGRect(x: now.x - 5, y: now.y - 5, width: 10, height: 10)
            context.fill(Path(ellipseIn: dot), with: .color(accent))
            context.stroke(Path(ellipseIn: dot), with: .color(.white), lineWidth: 2)
        }
        .accessibilityLabel("Temperature curve from now across the next hours")
    }
}
