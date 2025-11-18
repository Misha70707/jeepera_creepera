import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var routineService: RoutineService
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseDarkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header with Greeting
                        HeaderView(greeting: viewModel.greeting)

                        // MARK: - Streak Card
                        if let streak = viewModel.currentStreak {
                            StreakCardView(streak: streak)
                        }

                        // MARK: - Today's Routines Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "📋 TODAY'S ROUTINES", icon: nil)

                            if viewModel.todaysRoutines.isEmpty {
                                EmptyStateView(
                                    emoji: "📅",
                                    title: "No Routines Yet",
                                    subtitle: "Create your first routine to get started!"
                                )
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.todaysRoutines) { routine in
                                        RoutineCardView(
                                            routine: routine,
                                            onTap: { viewModel.selectedRoutine = routine }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // MARK: - This Week's Achievements
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "🎖️ THIS WEEK'S ACHIEVEMENTS", icon: nil)

                            if viewModel.weeklyAchievements.isEmpty {
                                Text("No achievements yet. Complete routines to unlock badges!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.pulseSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color.pulseSurface)
                                    .cornerRadius(8)
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                    ForEach(viewModel.weeklyAchievements) { achievement in
                                        AchievementBadgeView(achievement: achievement)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // MARK: - Community Highlights
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "👥 COMMUNITY HIGHLIGHTS", icon: nil)

                            if viewModel.communityHighlights.isEmpty {
                                Text("Join the community to see what others are achieving!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.pulseSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color.pulseSurface)
                                    .cornerRadius(8)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.communityHighlights.prefix(3)) { post in
                                        CommunityHighlightCardView(post: post)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Pulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundColor(.pulseAccent)
                    }
                }
            }
            .sheet(item: $viewModel.selectedRoutine) { routine in
                RoutineDetailView(routine: routine)
            }
            .onAppear {
                viewModel.loadData()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.loadData()
                }
            }
        }
        .background(Color.pulseDarkBg)
    }
}

// MARK: - Home View Model
class HomeViewModel: ObservableObject {
    @Published var greeting: String = ""
    @Published var currentStreak: Streak?
    @Published var todaysRoutines: [Routine] = []
    @Published var weeklyAchievements: [Achievement] = []
    @Published var communityHighlights: [Post] = []
    @Published var selectedRoutine: Routine?
    @Published var isLoading = false

    init() {
        updateGreeting()
        loadData()
    }

    func loadData() {
        isLoading = true
        updateGreeting()

        // Load today's routines
        let mockRoutines: [Routine] = [
            Routine(name: "Morning Routine")
                .with { routine in
                    routine.emoji = "📅"
                    routine.tasks = [
                        RoutineTask(name: "Exercise", order: 0),
                        RoutineTask(name: "Breakfast", order: 1),
                        RoutineTask(name: "Meditation", order: 2),
                    ]
                },
            Routine(name: "Productivity Boost")
                .with { routine in
                    routine.emoji = "🎯"
                    routine.tasks = [
                        RoutineTask(name: "Focus Session", order: 0),
                        RoutineTask(name: "Break", order: 1),
                    ]
                },
        ]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.todaysRoutines = mockRoutines
            self.currentStreak = Streak(id: "streak_1", name: "Daily Active", icon: "🔥", currentCount: 4, bestCount: 12)
            self.weeklyAchievements = Achievement.allCases.prefix(5).map { $0 }
            self.communityHighlights = Post.mockPosts
            self.isLoading = false
            AnalyticsService.shared.logEvent("home_loaded")
        }
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            greeting = "Good morning! 🌅"
        case 12..<17:
            greeting = "Good afternoon! ☀️"
        case 17..<21:
            greeting = "Good evening! 🌙"
        default:
            greeting = "Burning the midnight oil? 🌃"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let greeting: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.pulseText)

            Text("Let's crush today's goals! 💪")
                .font(.system(size: 14))
                .foregroundColor(.pulseSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

// MARK: - Streak Card View
struct StreakCardView: View {
    let streak: Streak

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(streak.icon)
                            .font(.system(size: 32))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(streak.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pulseText)

                            Text("\(streak.currentCount) days")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.pulseAccent)
                        }
                    }

                    Text("Best: \(streak.bestCount) days")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(Double(streak.currentCount) / Double(max(streak.bestCount, 1)) * 100))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.pulseAccent)

                    Text("of best")
                        .font(.system(size: 10))
                        .foregroundColor(.pulseSecondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pulseSeparator)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pulseAccent)
                        .frame(width: geometry.size.width * CGFloat(Double(streak.currentCount) / Double(max(streak.bestCount, 1))))
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.pulseSurface)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Routine Card View
struct RoutineCardView: View {
    let routine: Routine
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(routine.emoji)
                            .font(.system(size: 24))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(routine.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pulseText)

                            Text("\(routine.completedTasks)/\(routine.totalTasks) tasks")
                                .font(.system(size: 12))
                                .foregroundColor(.pulseSecondary)
                        }
                    }
                }

                Spacer()

                Button(action: onTap) {
                    Text("Open")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.pulseDarkBg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.pulseAccent)
                        .cornerRadius(6)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pulseSeparator)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pulseAccent)
                        .frame(width: geometry.size.width * routine.progressPercent)
                }
            }
            .frame(height: 6)

            Text("\(Int(routine.progressPercent * 100))% Complete")
                .font(.system(size: 11))
                .foregroundColor(.pulseSecondary)
        }
        .padding(12)
        .background(Color.pulseSurface)
        .cornerRadius(8)
    }
}

// MARK: - Achievement Badge View
struct AchievementBadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 4) {
            Text(achievement.icon)
                .font(.system(size: 20))

            if achievement.isUnlocked {
                Text("Unlocked")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.pulseSuccess)
            } else {
                Text("Locked")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.pulseSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(achievement.isUnlocked ? Color.pulseSurface : Color.pulseSeparator.opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(achievement.isUnlocked ? Color.pulseAccent : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Community Highlight Card
struct CommunityHighlightCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.pulseSeparator)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(post.author.prefix(1))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.pulseAccent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pulseText)

                    Text(post.createdAt.timeUntilNow)
                        .font(.system(size: 11))
                        .foregroundColor(.pulseSecondary)
                }

                Spacer()
            }

            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(.pulseText)
                .lineLimit(3)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseWarning)

                    Text("\(post.totalReactions)")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseError)

                    Text("\(post.commentCount)")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseSecondary)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(Color.pulseSurface)
        .cornerRadius(8)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 40))

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.pulseText)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.pulseSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.pulseSurface)
        .cornerRadius(8)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pulseSecondary)

            Spacer()

            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.pulseAccent)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(RoutineService.shared)
}
