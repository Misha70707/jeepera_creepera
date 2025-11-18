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

// MARK: - HomeView is now in HomeView.swift

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

// CommunityFeedView and AchievementsView moved to separate files

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
    var body: some View {
        OnboardingContainerView()
    }
}

// MARK: - Preview
#Preview {
    PulseApp()
}
