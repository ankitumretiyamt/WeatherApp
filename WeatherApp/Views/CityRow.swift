//
//  CityRow.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct CityRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let place: Place
    let conditions: CurrentConditions?
    let isResolving: Bool
    let isSelected: Bool
    let isSaved: Bool
    let onSelect: () -> Void
    let onToggleSave: () -> Void

    private var palette: Palette { Palette.resolve(colorScheme) }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: WeatherKind.symbol(code: conditions?.weatherCode ?? 2, isDay: conditions?.daytime ?? true))
                        .font(.title3)
                        .foregroundStyle(palette.accent)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.name)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(1)
                        if !place.detailLine.isEmpty {
                            Text(place.detailLine)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    temperatureView
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onToggleSave) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSaved ? palette.accent : palette.textSecondary)
                    .frame(width: 32, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSaved ? "Remove \(place.name)" : "Save \(place.name)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 22, selected: isSelected)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var temperatureView: some View {
        if let conditions {
            VStack(alignment: .trailing, spacing: 2) {
                Text(WeatherFormat.temperature(conditions.temperature))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.textPrimary)
                Text(WeatherKind.title(code: conditions.weatherCode))
                    .font(.caption2)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }
        } else if isResolving {
            ProgressView()
                .controlSize(.small)
                .tint(palette.accent)
        } else {
            Text("—")
                .font(.title3.weight(.bold))
                .foregroundStyle(palette.textSecondary)
        }
    }
}
