//
//  WeatherLogo.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct WeatherLogo: View {
    var size: CGFloat = 120
    @Environment(\.colorScheme) private var colorScheme

    private var palette: Palette { Palette.resolve(colorScheme) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.backgroundTop, palette.glowCyan.opacity(0.55), palette.backgroundBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(palette.accent.opacity(colorScheme == .dark ? 0.55 : 0.40))
                .frame(width: size * 0.62, height: size * 0.62)
                .blur(radius: size * 0.07)
                .offset(y: -size * 0.06)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, palette.accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(y: -size * 0.12)
                .shadow(color: palette.accent.opacity(0.55), radius: size * 0.06, y: size * 0.02)

            cloud
                .offset(y: size * 0.16)
        }
        .frame(width: size, height: size)
        .shadow(color: palette.shadow, radius: size * 0.12, y: size * 0.06)
        .accessibilityLabel("WeatherNow")
    }

    private var cloud: some View {
        ZStack {
            Circle()
                .frame(width: size * 0.26, height: size * 0.26)
                .offset(x: -size * 0.15, y: size * 0.04)
            Circle()
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(y: -size * 0.05)
            Circle()
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: size * 0.16, y: size * 0.05)
            Capsule()
                .frame(width: size * 0.58, height: size * 0.20)
                .offset(y: size * 0.08)
        }
        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.94) : Color.white)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 6, y: 3)
    }
}
