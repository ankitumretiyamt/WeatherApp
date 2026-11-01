//
//  Palette.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import SwiftUI

struct Palette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let glowPink: Color
    let glowCyan: Color
    let glowWarm: Color
    let accent: Color
    let onAccent: Color
    let textPrimary: Color
    let textSecondary: Color
    let stroke: Color
    let shadow: Color

    static func resolve(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? dark : light
    }

    static let dark = Palette(
        backgroundTop: Color(red: 0.15, green: 0.06, blue: 0.26),
        backgroundBottom: Color(red: 0.04, green: 0.05, blue: 0.13),
        glowPink: Color(red: 0.96, green: 0.32, blue: 0.62),
        glowCyan: Color(red: 0.25, green: 0.86, blue: 0.95),
        glowWarm: Color(red: 1.0, green: 0.50, blue: 0.22),
        accent: Color(red: 1.0, green: 0.74, blue: 0.32),
        onAccent: Color(red: 0.16, green: 0.08, blue: 0.18),
        textPrimary: .white,
        textSecondary: Color.white.opacity(0.70),
        stroke: Color.white.opacity(0.28),
        shadow: Color.black.opacity(0.35)
    )

    static let light = Palette(
        backgroundTop: Color(red: 0.75, green: 0.89, blue: 1.0),
        backgroundBottom: Color(red: 0.91, green: 0.83, blue: 0.98),
        glowPink: Color(red: 1.0, green: 0.70, blue: 0.58),
        glowCyan: Color(red: 0.42, green: 0.70, blue: 1.0),
        glowWarm: Color(red: 0.74, green: 0.62, blue: 0.98),
        accent: Color(red: 0.98, green: 0.40, blue: 0.16),
        onAccent: .white,
        textPrimary: Color(red: 0.09, green: 0.11, blue: 0.25),
        textSecondary: Color(red: 0.16, green: 0.18, blue: 0.34).opacity(0.72),
        stroke: Color.white.opacity(0.80),
        shadow: Color(red: 0.20, green: 0.18, blue: 0.40).opacity(0.12)
    )
}
