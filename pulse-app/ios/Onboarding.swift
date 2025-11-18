import SwiftUI
import Combine

// MARK: - Onboarding Container
struct OnboardingContainerView: View {
    @StateObject private var onboardingFlow = OnboardingFlow()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        ZStack {
            // Background
            Color.pulseDarkBg.ignoresSafeArea()

            // Step indicator
            VStack {
                HStack {
                    Text("Step \(onboardingFlow.currentStep + 1) of 4")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.pulseSecondary)

                    Spacer()

                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index <= onboardingFlow.currentStep ? Color.pulseAccent : Color.pulseSeparator)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Current screen
                Group {
                    switch onboardingFlow.currentStep {
                    case 0:
                        WelcomeScreen(onboardingFlow: onboardingFlow, authService: authService)
                    case 1:
                        ProfileSetupScreen(onboardingFlow: onboardingFlow)
                    case 2:
                        RoutineSelectionScreen(onboardingFlow: onboardingFlow)
                    case 3:
                        NotificationPreferencesScreen(onboardingFlow: onboardingFlow)
                    default:
                        WelcomeScreen(onboardingFlow: onboardingFlow, authService: authService)
                    }
                }

                Spacer()
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Onboarding Flow State Manager
class OnboardingFlow: ObservableObject {
    @Published var currentStep = 0
    @Published var userProfile = UserProfile()
    @Published var selectedRoutines: [String] = []
    @Published var notificationPreferences = NotificationPreferences()

    func nextStep() {
        if currentStep < 3 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        }
    }

    func previousStep() {
        if currentStep > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }

    func skip() {
        currentStep = 3 // Jump to last step
    }

    func complete() {
        // Create user with collected data
        // TODO: Call AuthService to save profile
    }
}

struct UserProfile {
    var name: String = ""
    var photoURL: URL? = nil
    var primaryFocus: String = "productivity"
    var tags: Set<String> = []
}

struct NotificationPreferences {
    var frequency: String = "balanced"
    var style: String = "textAndEmoji"
    var soundEnabled: Bool = true
    var doNotDisturbStart: Date? = nil
    var doNotDisturbEnd: Date? = nil
}

// MARK: - Screen 1: Welcome
struct WelcomeScreen: View {
    @ObservedObject var onboardingFlow: OnboardingFlow
    @EnvironmentObject var authService: AuthService
    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo & Branding
            VStack(spacing: 24) {
                Text("Pulse")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.pulseAccent)
                    .scaleEffect(1.0)

                VStack(spacing: 12) {
                    Text("Your Personal AI Assistant\nfor Daily Excellence")
                        .font(.system(size: 22, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.pulseText)

                    Text("Automate habits, connect with\ncommunities, unlock your potential—\nall on your device.")
                        .font(.system(size: 16, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.pulseSecondary)
                        .lineSpacing(2)
                }
            }

            Spacer()

            // Sign In Buttons
            VStack(spacing: 12) {
                // Apple Sign-In
                Button(action: {
                    isSigningIn = true
                    authService.signInWithApple { result in
                        isSigningIn = false
                        if case .success = result {
                            onboardingFlow.nextStep()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Sign in with Apple")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                .disabled(isSigningIn)

                // Google Sign-In
                Button(action: {
                    isSigningIn = true
                    authService.signInWithGoogle { result in
                        isSigningIn = false
                        if case .success = result {
                            onboardingFlow.nextStep()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Sign in with Google")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.pulseSurface)
                    .foregroundColor(.pulseText)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.pulseSeparator, lineWidth: 1)
                    )
                }
                .disabled(isSigningIn)

                // Skip Button
                Button(action: { onboardingFlow.skip() }) {
                    Text("Continue as Guest")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pulseSecondary)
                }
                .padding(.top, 8)
            }

            // Privacy Notice
            VStack(spacing: 8) {
                Text("Privacy-first. On-device. Yours.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.pulseSecondary)

                HStack(spacing: 4) {
                    Text("By signing in, you agree to our")
                        .font(.system(size: 11))
                        .foregroundColor(.pulseSecondary)

                    Link("Privacy Policy", destination: URL(string: "https://pulseapp.io/privacy")!)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.pulseAccent)
                }
            }
            .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Screen 2: Profile Setup
struct ProfileSetupScreen: View {
    @ObservedObject var onboardingFlow: OnboardingFlow
    @State private var showImagePicker = false

    var isComplete: Bool {
        !onboardingFlow.userProfile.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Let's Set Up Your Profile")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pulseText)

                Text("Just a few quick questions")
                    .font(.system(size: 14))
                    .foregroundColor(.pulseSecondary)
            }

            ScrollView {
                VStack(spacing: 20) {
                    // Profile Photo
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.pulseSurface)
                            .frame(width: 96, height: 96)
                            .overlay(
                                Circle()
                                    .stroke(Color.pulseAccent, lineWidth: 2)
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.pulseAccent)
                            )
                            .onTapGesture {
                                showImagePicker = true
                            }

                        Text("Tap to upload photo")
                            .font(.system(size: 12))
                            .foregroundColor(.pulseSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pulseText)

                        TextField("e.g., Alex Chen", text: $onboardingFlow.userProfile.name)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.pulseSurface)
                            .cornerRadius(8)
                            .foregroundColor(.pulseText)
                    }

                    // Primary Focus Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary Focus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pulseText)

                        Picker("", selection: $onboardingFlow.userProfile.primaryFocus) {
                            Text("🎯 Productivity").tag("productivity")
                            Text("🎨 Creative/Content").tag("creative")
                            Text("💪 Health & Fitness").tag("fitness")
                            Text("👨‍👩‍👧 Family & Parenting").tag("family")
                            Text("🎮 Hobbies & Gaming").tag("hobbies")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.pulseSurface)
                        .cornerRadius(8)
                        .foregroundColor(.pulseText)
                    }

                    // Tag Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What else describes you? (Optional)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pulseText)

                        let tags = ["Creator", "Parent", "Entrepreneur", "Student", "Remote Worker"]
                        VStack(spacing: 8) {
                            ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                                HStack(spacing: 12) {
                                    Image(systemName: onboardingFlow.userProfile.tags.contains(tag) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(onboardingFlow.userProfile.tags.contains(tag) ? .pulseAccent : .pulseSecondary)

                                    Text(tag)
                                        .font(.system(size: 14))
                                        .foregroundColor(.pulseText)

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if onboardingFlow.userProfile.tags.contains(tag) {
                                        onboardingFlow.userProfile.tags.remove(tag)
                                    } else {
                                        onboardingFlow.userProfile.tags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }

            Spacer()

            // Navigation Buttons
            HStack(spacing: 12) {
                Button(action: { onboardingFlow.previousStep() }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.pulseSecondary)
                        .background(Color.pulseSurface)
                        .cornerRadius(8)
                }

                Button(action: { onboardingFlow.nextStep() }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.pulseDarkBg)
                        .background(isComplete ? Color.pulseAccent : Color.pulseSeparator)
                        .cornerRadius(8)
                }
                .disabled(!isComplete)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

// MARK: - Screen 3: Routine Selection
struct RoutineSelectionScreen: View {
    @ObservedObject var onboardingFlow: OnboardingFlow

    let routineTemplates = [
        ("Morning Routine", "📅", "Exercise → Breakfast → Meditation → Work", "15 min"),
        ("Productivity Boost", "🎯", "Focus Session → Break → Review Progress", "25 min"),
        ("Evening Wind-down", "🌙", "Review Day → Reflection → Sleep Prep", "20 min"),
        ("Fitness Challenge", "💪", "Warmup → Workout → Cool Down → Hydrate", "45 min"),
        ("Creative Time", "🎨", "Brainstorm → Create → Review → Iterate", "60 min"),
        ("Family Time", "👨‍👩‍👧", "Dinner → Games → Bedtime Stories → Sleep", "90 min"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Choose Your First Routines")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pulseText)

                Text("Pick one or more to get started")
                    .font(.system(size: 14))
                    .foregroundColor(.pulseSecondary)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(routineTemplates, id: \.0) { name, emoji, description, duration in
                        RoutineCard(
                            name: name,
                            emoji: emoji,
                            description: description,
                            duration: duration,
                            isSelected: onboardingFlow.selectedRoutines.contains(name),
                            action: {
                                if onboardingFlow.selectedRoutines.contains(name) {
                                    onboardingFlow.selectedRoutines.removeAll { $0 == name }
                                } else {
                                    onboardingFlow.selectedRoutines.append(name)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 16)
            }

            Spacer()

            // Navigation Buttons
            HStack(spacing: 12) {
                Button(action: { onboardingFlow.previousStep() }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.pulseSecondary)
                        .background(Color.pulseSurface)
                        .cornerRadius(8)
                }

                Button(action: { onboardingFlow.nextStep() }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.pulseDarkBg)
                        .background(Color.pulseAccent)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

struct RoutineCard: View {
    let name: String
    let emoji: String
    let description: String
    let duration: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(emoji)
                            .font(.system(size: 24))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pulseText)

                            Text(duration)
                                .font(.system(size: 12))
                                .foregroundColor(.pulseSecondary)
                        }
                    }

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.pulseSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .pulseAccent : .pulseSeparator)
            }
        }
        .padding(16)
        .background(Color.pulseSurface)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.pulseAccent : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Screen 4: Notification Preferences
struct NotificationPreferencesScreen: View {
    @ObservedObject var onboardingFlow: OnboardingFlow
    @State private var startTime = Date()
    @State private var endTime = Date()

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Notification Preferences")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pulseText)

                Text("Choose how Pulse reminds you")
                    .font(.system(size: 14))
                    .foregroundColor(.pulseSecondary)
            }

            ScrollView {
                VStack(spacing: 24) {
                    // Frequency
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminder Frequency")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pulseText)

                        VStack(spacing: 8) {
                            FrequencyOption(
                                title: "Gentle (1 reminder/day)",
                                emoji: "🌤️",
                                isSelected: onboardingFlow.notificationPreferences.frequency == "gentle",
                                action: { onboardingFlow.notificationPreferences.frequency = "gentle" }
                            )

                            FrequencyOption(
                                title: "Balanced (3-5/day)",
                                emoji: "⚖️",
                                isSelected: onboardingFlow.notificationPreferences.frequency == "balanced",
                                action: { onboardingFlow.notificationPreferences.frequency = "balanced" }
                            )

                            FrequencyOption(
                                title: "Assertive (10+/day)",
                                emoji: "🚀",
                                isSelected: onboardingFlow.notificationPreferences.frequency == "assertive",
                                action: { onboardingFlow.notificationPreferences.frequency = "assertive" }
                            )
                        }
                    }

                    // Style
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notification Style")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pulseText)

                        VStack(spacing: 8) {
                            StyleOption(
                                title: "Text + Emoji + Sound",
                                icon: "speaker.wave.2",
                                isSelected: onboardingFlow.notificationPreferences.style == "textAndEmoji",
                                action: { onboardingFlow.notificationPreferences.style = "textAndEmoji" }
                            )

                            StyleOption(
                                title: "Text + Emoji",
                                icon: "text.bubble",
                                isSelected: onboardingFlow.notificationPreferences.style == "silent",
                                action: { onboardingFlow.notificationPreferences.style = "silent" }
                            )
                        }
                    }

                    // Do Not Disturb
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Do Not Disturb")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pulseText)

                        HStack {
                            DatePicker(
                                "From",
                                selection: $startTime,
                                displayedComponents: .hourAndMinute
                            )
                            .colorScheme(.dark)

                            Spacer()

                            DatePicker(
                                "To",
                                selection: $endTime,
                                displayedComponents: .hourAndMinute
                            )
                            .colorScheme(.dark)
                        }
                        .padding(12)
                        .background(Color.pulseSurface)
                        .cornerRadius(8)
                    }

                    // Sound Toggle
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.pulseAccent)

                        Text("Allow sound notifications")
                            .font(.system(size: 14))
                            .foregroundColor(.pulseText)

                        Spacer()

                        Toggle("", isOn: $onboardingFlow.notificationPreferences.soundEnabled)
                            .tint(.pulseAccent)
                    }
                    .padding(12)
                    .background(Color.pulseSurface)
                    .cornerRadius(8)
                }
                .padding(.vertical, 16)
            }

            Spacer()

            // Complete Button
            HStack(spacing: 12) {
                Button(action: { onboardingFlow.previousStep() }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.pulseSecondary)
                        .background(Color.pulseSurface)
                        .cornerRadius(8)
                }

                Button(action: { onboardingFlow.complete() }) {
                    HStack(spacing: 8) {
                        Text("🎉 Complete Setup!")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(.pulseDarkBg)
                    .background(Color.pulseAccent)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

struct FrequencyOption: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? .pulseAccent : .pulseSeparator)
                .font(.system(size: 18))

            HStack {
                Text(emoji)
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.pulseText)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }
}

struct StyleOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .pulseAccent : .pulseSeparator)
                .font(.system(size: 18))

            Image(systemName: icon)
                .foregroundColor(.pulseAccent)
                .font(.system(size: 14, weight: .semibold))

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.pulseText)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AuthService())
}
