import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// Pulse Brand Colors
    static let pulseAccent = Color(red: 0.0, green: 0.835, blue: 1.0)  // #00D4FF
    static let pulseDarkBg = Color(red: 0.04, green: 0.08, blue: 0.16)  // #0A1428
    static let pulseSurface = Color(red: 0.1, green: 0.122, blue: 0.18)  // #1A1F2E
    static let pulseText = Color(red: 0.91, green: 0.925, blue: 0.94)  // #E8ECEF
    static let pulseSecondary = Color(red: 0.627, green: 0.659, blue: 0.7)  // #A0A8B2
    static let pulseSeparator = Color(red: 0.176, green: 0.22, blue: 0.282)  // #2D3748

    // Semantic Colors
    static let pulseSuccess = Color(red: 0.29, green: 0.933, blue: 0.435)  // #4AEE6F
    static let pulseWarning = Color(red: 1.0, green: 0.647, blue: 0.0)  // #FFA500
    static let pulseError = Color(red: 1.0, green: 0.42, blue: 0.42)  // #FF6B6B
}

// MARK: - View Extensions

extension View {
    /// Apply Pulse card styling
    func pulseCard() -> some View {
        self
            .padding(16)
            .background(Color.pulseSurface)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
    }

    /// Apply Pulse button styling
    func pulseButton(style: PulseButtonStyle = .primary) -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .padding(12)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(8)
    }

    /// Fade in animation
    func fadeIn(duration: Double = 0.3) -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration)) {
                    // Will animate once placed in view hierarchy
                }
            }
    }

    /// Scale on tap animation
    func scaleOnTap() -> some View {
        self
            .scaleEffect(1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Trigger scale animation
                }
            }
    }

    /// Add horizontal spacing
    func horizontalPadding(_ value: CGFloat = 16) -> some View {
        self.padding(.horizontal, value)
    }

    /// Add vertical spacing
    func verticalPadding(_ value: CGFloat = 16) -> some View {
        self.padding(.vertical, value)
    }
}

enum PulseButtonStyle {
    case primary
    case secondary
    case danger

    var backgroundColor: Color {
        switch self {
        case .primary:
            return Color.pulseAccent
        case .secondary:
            return Color.pulseSurface
        case .danger:
            return Color.pulseError
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            return Color.pulseDarkBg
        case .secondary:
            return Color.pulseText
        case .danger:
            return Color.white
        }
    }

    var borderColor: Color {
        switch self {
        case .primary:
            return Color.clear
        case .secondary:
            return Color.pulseSeparator
        case .danger:
            return Color.clear
        }
    }
}

// MARK: - Text Extensions

extension View {
    /// Apply heading style (24pt bold)
    func headingStyle() -> some View {
        self
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.pulseText)
    }

    /// Apply title style (20pt semibold)
    func titleStyle() -> some View {
        self
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.pulseText)
    }

    /// Apply body style (16pt regular)
    func bodyStyle() -> some View {
        self
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.pulseText)
    }

    /// Apply caption style (12pt regular)
    func captionStyle() -> some View {
        self
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.pulseSecondary)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format date for display
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }

    /// Format time for display (HH:mm)
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Time until date from now
    var timeUntilNow: String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24

        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else if days < 7 {
            return "\(days)d ago"
        } else {
            return formatted(style: .short)
        }
    }
}

// MARK: - Double Extensions

extension Double {
    /// Format as percentage
    var percentageString: String {
        String(format: "%.0f%%", self * 100)
    }

    /// Format as duration
    var durationString: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Format as readable duration
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? "0m"
    }
}

// MARK: - String Extensions

extension String {
    /// Capitalized first letter
    var capitalizedFirst: String {
        guard !self.isEmpty else { return self }
        return prefix(1).capitalized + dropFirst()
    }

    /// Safe URL
    var asURL: URL? {
        URL(string: self)
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safe subscript access
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Binding Extensions

extension Binding {
    /// Convert optional binding to non-optional
    func withDefault<T>(_ default: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? `default` },
            set: { self.wrappedValue = $0 }
        )
    }
}

// MARK: - Previews

#Preview("Color Palette") {
    VStack(spacing: 16) {
        Color.pulseAccent
            .frame(height: 80)
            .overlay(Text("Accent").font(.headline))

        Color.pulseDarkBg
            .frame(height: 80)
            .overlay(Text("Dark BG").font(.headline))

        Color.pulseSurface
            .frame(height: 80)
            .overlay(Text("Surface").font(.headline))

        Color.pulseSuccess
            .frame(height: 80)
            .overlay(Text("Success").font(.headline))

        Color.pulseWarning
            .frame(height: 80)
            .overlay(Text("Warning").font(.headline))

        Color.pulseError
            .frame(height: 80)
            .overlay(Text("Error").font(.headline))
    }
    .padding()
}
