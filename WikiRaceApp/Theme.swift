import SwiftUI

extension Color {
    static let themeBackground = Color("ThemeBackground") // Adaptive background
    static let themeCardBackground = Color("ThemeCardBackground") // Slightly lighter for cards
    
    // Energetic Palette
    static let themeBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // Bright Electric Blue
    static let themeGreen = Color(red: 0.0, green: 0.8, blue: 0.4) // Neon Green
    static let themeOrange = Color(red: 1.0, green: 0.5, blue: 0.0) // Energetic Orange
    static let themeRed = Color(red: 1.0, green: 0.2, blue: 0.2) // Alert Red
    static let themeTextPrimary = Color.primary
    static let themeTextSecondary = Color.secondary
    
    // Gradients
    static let gradientBlue = LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct Theme {
    static func apply() {
        // Global appearance tweaks if needed
    }
}
