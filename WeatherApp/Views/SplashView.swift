//
//  SplashView.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    private var palette: Palette { Palette.resolve(colorScheme) }

    var body: some View {
        ZStack {
            SkyBackground()
            VStack(spacing: 22) {
                WeatherLogo(size: 132)
                    .scaleEffect(appeared ? 1 : 0.86)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 6) {
                    Text("WeatherNow")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Live weather for where you are")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.textSecondary)
                }
                .foregroundStyle(palette.textPrimary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                ProgressView()
                    .controlSize(.regular)
                    .tint(palette.accent)
                    .padding(.top, 6)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.28)) {
                appeared = true
            }
        }
    }
}
