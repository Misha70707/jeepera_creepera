import Foundation

// MARK: - Data Models

/// User Profile
struct User: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var avatar: URL?
    var bio: String?
    var joinedTribes: [String] = []
    var createdAt: Date
    var preferences: UserPreferences = .default

    init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = Date()
    }
}

struct UserPreferences: Codable {
    var notificationFrequency: NotificationFrequency = .balanced
    var notificationStyle: NotificationStyle = .textAndEmoji
    var darkMode: Bool = true
    var soundEnabled: Bool = true
    var doNotDisturbStart: Date? = nil
    var doNotDisturbEnd: Date? = nil

    static let `default` = UserPreferences()

    enum NotificationFrequency: String, Codable, CaseIterable {
        case gentle = "Gentle (1/day)"
        case balanced = "Balanced (3-5/day)"
        case assertive = "Assertive (10+/day)"
    }

    enum NotificationStyle: String, Codable, CaseIterable {
        case textAndEmojiAndSound = "Text + Emoji + Sound"
        case textAndEmoji = "Text + Emoji"
        case silent = "Silent (badge only)"
    }
}

// MARK: - Routine & Task

struct Routine: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var emoji: String = "📋"
    var tasks: [RoutineTask] = []
    var schedule: RoutineSchedule = .daily
    var startTime: Date?
    var estimatedDuration: TimeInterval = 1800 // 30 min default
    var isActive: Bool = true
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    enum RoutineSchedule: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekdays = "Weekdays"
        case weekends = "Weekends"
        case weekly = "Weekly"
        case custom = "Custom"
    }

    var totalTasks: Int { tasks.count }
    var completedTasks: Int { tasks.filter { $0.isCompleted }.count }
    var progressPercent: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

struct RoutineTask: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var estimatedDuration: TimeInterval?
    var isCompleted: Bool = false
    var completedAt: Date?
    var order: Int = 0

    init(id: String = UUID().uuidString, name: String, order: Int = 0) {
        self.id = id
        self.name = name
        self.order = order
    }

    mutating func complete() {
        isCompleted = true
        completedAt = Date()
    }

    mutating func reset() {
        isCompleted = false
        completedAt = nil
    }
}

// MARK: - Community

struct Post: Codable, Identifiable {
    let id: String
    let authorId: String
    var author: String // Username
    var content: String
    var imageURL: URL?
    var tribeId: String?
    var createdAt: Date
    var updatedAt: Date

    var reactions: [String: Int] = [:]  // emoji -> count
    var comments: [Comment] = []

    init(
        id: String = UUID().uuidString,
        authorId: String,
        author: String,
        content: String,
        tribeId: String? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.author = author
        self.content = content
        self.tribeId = tribeId
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var totalReactions: Int {
        reactions.values.reduce(0, +)
    }
}

struct Comment: Codable, Identifiable {
    let id: String
    let authorId: String
    var author: String
    var content: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        authorId: String,
        author: String,
        content: String
    ) {
        self.id = id
        self.authorId = authorId
        self.author = author
        self.content = content
        self.createdAt = Date()
    }
}

struct Tribe: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var icon: String = "👥"
    var memberCount: Int = 0
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String = "👥"
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = Date()
    }

    // Predefined tribes
    static let productivity = Tribe(id: "tribe_productivity", name: "Productivity", icon: "📊")
    static let creators = Tribe(id: "tribe_creators", name: "Creators", icon: "🎨")
    static let fitness = Tribe(id: "tribe_fitness", name: "Fitness", icon: "💪")
    static let parents = Tribe(id: "tribe_parents", name: "Parents", icon: "👨‍👩‍👧")
    static let gamers = Tribe(id: "tribe_gamers", name: "Gamers", icon: "🎮")

    static let allTribes = [productivity, creators, fitness, parents, gamers]
}

// MARK: - Achievements

struct Achievement: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    var icon: String
    var rarity: Rarity = .common
    var unlockedAt: Date?
    var progress: Double? // 0-1 for in-progress achievements

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        icon: String,
        rarity: Rarity = .common
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.rarity = rarity
    }

    var isUnlocked: Bool { unlockedAt != nil }

    enum Rarity: String, Codable {
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
    }

    // Predefined achievements
    static let firstRoutine = Achievement(
        id: "ach_first_routine",
        name: "Getting Started",
        description: "Complete your first routine",
        icon: "🎯",
        rarity: .common
    )

    static let sevenDayStreak = Achievement(
        id: "ach_7day_streak",
        name: "Week Warrior",
        description: "Maintain a 7-day streak",
        icon: "🔥",
        rarity: .rare
    )

    static let thirtyDayStreak = Achievement(
        id: "ach_30day_streak",
        name: "Monthly Champion",
        description: "Maintain a 30-day streak",
        icon: "👑",
        rarity: .epic
    )
}

struct Streak: Codable, Identifiable {
    let id: String
    var name: String
    var icon: String
    var currentCount: Int = 0
    var bestCount: Int = 0
    var lastCompletedDate: Date?
    var startDate: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.startDate = Date()
    }

    var isActive: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastCompleted, to: Date())
        return (components.day ?? 0) <= 1
    }

    mutating func recordCompletion() {
        lastCompletedDate = Date()
        currentCount += 1
        if currentCount > bestCount {
            bestCount = currentCount
        }
    }

    mutating func reset() {
        currentCount = 0
        lastCompletedDate = nil
    }
}

// MARK: - Notifications

struct NotificationSchedule: Codable {
    var enabled: Bool = true
    var time: Date?
    var repeatDaily: Bool = false
    var customDays: [DayOfWeek] = []

    enum DayOfWeek: String, Codable, CaseIterable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    }
}

// MARK: - View Models

struct OnboardingStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
}

// MARK: - Mock Data

extension User {
    static let mockUser = User(
        id: "user_123",
        name: "Alex",
        email: "alex@example.com"
    )
}

extension Routine {
    static let mockRoutines = [
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
}

extension Post {
    static let mockPosts = [
        Post(
            authorId: "user_456",
            author: "maya_creates",
            content: "Just hit my 30-day streak! 🔥 Feeling amazing and motivated!",
            tribeId: "tribe_creators"
        ),
        Post(
            authorId: "user_789",
            author: "jordan_family",
            content: "Family chore system is working great! Kids are earning badges and loving it.",
            tribeId: "tribe_parents"
        ),
    ]
}

// MARK: - Helpers

extension Routine {
    func with(_ modifier: (inout Routine) -> Void) -> Routine {
        var copy = self
        modifier(&copy)
        return copy
    }
}
