//
//  SkyBackground.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct SkyBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        let palette = Palette.resolve(colorScheme)
        ZStack {
            LinearGradient(
                colors: [palette.backgroundTop, palette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            glow(palette.glowPink, size: 320, x: drift ? -130 : -50, y: drift ? -180 : -70)
            glow(palette.glowCyan, size: 280, x: drift ? 160 : 80, y: drift ? 160 : 250)
            glow(palette.glowWarm, size: 260, x: drift ? -90 : 30, y: drift ? 480 : 390)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion, !drift else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func glow(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(colorScheme == .dark ? 0.90 : 0.80))
            .frame(width: size, height: size)
            .blur(radius: 72)
            .offset(x: x, y: y)
    }
}
