import SwiftUI

// MARK: - Achievements View
struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var selectedTab: AchievementTab = .badges

    enum AchievementTab {
        case badges, streaks, leaderboard
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseDarkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        TabSelectorButton(
                            label: "🏆 Badges",
                            isSelected: selectedTab == .badges,
                            action: { selectedTab = .badges }
                        )

                        TabSelectorButton(
                            label: "🔥 Streaks",
                            isSelected: selectedTab == .streaks,
                            action: { selectedTab = .streaks }
                        )

                        TabSelectorButton(
                            label: "📊 Leaderboard",
                            isSelected: selectedTab == .leaderboard,
                            action: { selectedTab = .leaderboard }
                        )
                    }
                    .background(Color.pulseSurface)
                    .padding(.bottom, 12)

                    // Content
                    ScrollView {
                        Group {
                            switch selectedTab {
                            case .badges:
                                BadgesView(achievements: viewModel.achievements)
                            case .streaks:
                                StreaksView(streaks: viewModel.streaks)
                            case .leaderboard:
                                LeaderboardView(entries: viewModel.leaderboardEntries)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadData()
            }
        }
        .background(Color.pulseDarkBg)
    }
}

// MARK: - View Model
class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var streaks: [Streak] = []
    @Published var leaderboardEntries: [LeaderboardEntry] = []

    func loadData() {
        // Mock achievements
        self.achievements = Achievement.allCases

        // Mock streaks
        self.streaks = [
            Streak(id: "streak_1", name: "Daily Active", icon: "🔥", currentCount: 4, bestCount: 12),
            Streak(id: "streak_2", name: "Productivity", icon: "🎯", currentCount: 2, bestCount: 8),
            Streak(id: "streak_3", name: "Health", icon: "💪", currentCount: 6, bestCount: 20),
        ]

        // Mock leaderboard
        self.leaderboardEntries = [
            LeaderboardEntry(rank: 1, username: "alex_productivity", points: 2450),
            LeaderboardEntry(rank: 2, username: "maya_creates", points: 2180),
            LeaderboardEntry(rank: 3, username: "jordan_family", points: 1890),
            LeaderboardEntry(rank: 4, username: "casey_gamer", points: 1650),
            LeaderboardEntry(rank: 5, username: "you", points: 1245, isCurrentUser: true),
        ]

        AnalyticsService.shared.logEvent("achievements_loaded")
    }
}

struct LeaderboardEntry {
    let rank: Int
    let username: String
    let points: Int
    var isCurrentUser: Bool = false
}

// MARK: - Tab Selector Button
struct TabSelectorButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .pulseAccent : .pulseSecondary)

                if isSelected {
                    Capsule()
                        .fill(Color.pulseAccent)
                        .frame(height: 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Badges View
struct BadgesView: View {
    let achievements: [Achievement]

    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !unlockedAchievements.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🎉 Unlocked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pulseSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(unlockedAchievements) { achievement in
                            BadgeView(achievement: achievement, isUnlocked: true)
                        }
                    }
                }
            }

            if !lockedAchievements.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🔒 Locked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pulseSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(lockedAchievements) { achievement in
                            BadgeView(achievement: achievement, isUnlocked: false)
                        }
                    }
                }
            }
        }
    }
}

struct BadgeView: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.icon)
                .font(.system(size: 24))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(achievement.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.pulseText)
                .lineLimit(2)
                .textAlignment(.center)
        }
        .padding(8)
        .background(isUnlocked ? Color.pulseSurface : Color.pulseSeparator.opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isUnlocked ? Color.pulseAccent : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Streaks View
struct StreaksView: View {
    let streaks: [Streak]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(streaks) { streak in
                StreakRowView(streak: streak)
            }
        }
    }
}

struct StreakRowView: View {
    let streak: Streak

    var percentage: Double {
        streak.bestCount > 0 ? Double(streak.currentCount) / Double(streak.bestCount) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(streak.icon)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(streak.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.pulseText)

                    HStack(spacing: 8) {
                        Text("\(streak.currentCount) days")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.pulseAccent)

                        Divider()

                        Text("Best: \(streak.bestCount) days")
                            .font(.system(size: 12))
                            .foregroundColor(.pulseSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 18, weight: .bold))
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
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.pulseSurface)
        .cornerRadius(8)
    }
}

// MARK: - Leaderboard View
struct LeaderboardView: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(entries, id: \.rank) { entry in
                LeaderboardRowView(entry: entry)
            }
        }
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry

    var medalEmoji: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(entry.rank)"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(medalEmoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pulseText)

                Text("Rank #\(entry.rank)")
                    .font(.system(size: 12))
                    .foregroundColor(.pulseSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.points)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.pulseAccent)

                Text("points")
                    .font(.system(size: 10))
                    .foregroundColor(.pulseSecondary)
            }
        }
        .padding(12)
        .background(entry.isCurrentUser ? Color.pulseAccent.opacity(0.1) : Color.pulseSurface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(entry.isCurrentUser ? Color.pulseAccent : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    AchievementsView()
}
