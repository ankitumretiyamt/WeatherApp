//
//  Glass.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var cornerRadius: CGFloat
    var selected: Bool

    func body(content: Content) -> some View {
        let palette = Palette.resolve(colorScheme)
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.34))
                    }
                    .overlay {
                        if reduceTransparency {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.78) : Color.white.opacity(0.92))
                        }
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(selected ? palette.accent : palette.stroke, lineWidth: selected ? 1.6 : 1)
            }
            .shadow(color: selected ? palette.accent.opacity(0.28) : palette.shadow, radius: selected ? 16 : 14, y: 8)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 26, selected: Bool = false) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, selected: selected))
    }
}

struct ScreenScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            content()
                .frame(maxWidth: 480)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

struct RoundIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: 42, height: 42)
                .glassCard(cornerRadius: 21)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct AppearanceButton: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundIconButton(
            symbol: colorScheme == .dark ? "sun.max" : "moon",
            label: colorScheme == .dark ? "Switch to light mode" : "Switch to dark mode"
        ) {
            store.toggleColorScheme(current: colorScheme)
        }
    }
}

struct AttributionLabel: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("Weather data by Open-Meteo")
            .font(.caption)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Palette.resolve(colorScheme).textSecondary)
            .padding(.top, 2)
    }
}

struct FloatingTabBar: View {
    @Environment(WeatherStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = Palette.resolve(colorScheme)
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let selected = store.selectedTab == tab
                Button {
                    store.selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol(selected: selected))
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(selected ? palette.accent : palette.textSecondary)
                    .background {
                        if selected {
                            Capsule(style: .continuous)
                                .fill(palette.accent.opacity(colorScheme == .dark ? 0.20 : 0.16))
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .glassCard(cornerRadius: 32)
        .animation(.snappy(duration: 0.25), value: store.selectedTab)
        .sensoryFeedback(.selection, trigger: store.selectedTab)
    }
}
