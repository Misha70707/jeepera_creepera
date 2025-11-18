import SwiftUI
import Combine

// MARK: - App Entry Point
@main
struct PulseApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(appCoordinator)
                    .environmentObject(authService)
            } else {
                OnboardingView()
                    .environmentObject(authService)
            }
        }
    }
}

// MARK: - App Coordinator (Navigation)
class AppCoordinator: ObservableObject {
    @Published var currentTab: MainTab = .home
    @Published var presentedSheet: SheetPresentation? = nil

    enum MainTab {
        case home
        case routines
        case community
        case achievements
        case settings
    }

    enum SheetPresentation: Identifiable {
        var id: String {
            switch self {
            case .routineDetail: return "routineDetail"
            case .createRoutine: return "createRoutine"
            case .postDetail: return "postDetail"
            }
        }

        case routineDetail(Routine)
        case createRoutine
        case postDetail(Post)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppCoordinator.MainTab.home)

            // Routines Tab
            RoutinesListView()
                .tabItem {
                    Label("Routines", systemImage: "checklist")
                }
                .tag(AppCoordinator.MainTab.routines)

            // Community Tab
            CommunityFeedView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                .tag(AppCoordinator.MainTab.community)

            // Achievements Tab
            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "star.fill")
                }
                .tag(AppCoordinator.MainTab.achievements)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppCoordinator.MainTab.settings)
        }
        .accentColor(Color.pulseAccent)
    }
}

// MARK: - Placeholder Views (Phase 2 Implementation)

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("🏠 Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Routines & Quick Stats Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Pulse")
        }
    }
}

struct RoutinesListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("📋 Routines")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Routine Management Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Routines")
        }
    }
}

struct CommunityFeedView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("👥 Community")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Community Feed Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Community")
        }
    }
}

struct AchievementsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("🏆 Achievements")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Badges & Streaks Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Achievements")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            VStack {
                Text("⚙️ Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button(action: { authService.signOut() }) {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                Text("Settings Coming Soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo & Title
            VStack(spacing: 16) {
                Text("Pulse")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.pulseAccent)

                Text("Your Personal AI Assistant\nfor Daily Excellence")
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text("Automate habits, connect with\ncommunities, unlock your potential.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Sign In Buttons
            VStack(spacing: 12) {
                Button(action: { handleAppleSignIn() }) {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading)

                Button(action: { handleGoogleSignIn() }) {
                    HStack {
                        Image(systemName: "g.circle")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
            }

            // Privacy Notice
            Text("Privacy-first. On-device. Yours.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)

            Spacer()
        }
        .padding(24)
    }

    private func handleAppleSignIn() {
        isLoading = true
        authService.signInWithApple { result in
            isLoading = false
            if case .success = result {
                // Navigation handled by @EnvironmentObject
            }
        }
    }

    private func handleGoogleSignIn() {
        isLoading = true
        authService.signInWithGoogle { result in
            isLoading = false
            if case .success = result {
                // Navigation handled by @EnvironmentObject
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PulseApp()
}
