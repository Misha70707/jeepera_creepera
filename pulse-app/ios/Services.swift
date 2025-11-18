import Foundation
import Combine

// MARK: - Authentication Service

class AuthService: NSObject, ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        restoreSession()
    }

    // MARK: - Sign In Methods

    func signInWithApple(completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true

        // TODO: Integrate with AuthenticationServices framework
        // For MVP, we'll mock the response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let mockUser = User(id: UUID().uuidString, name: "Alex", email: "alex@example.com")
            self?.handleAuthSuccess(mockUser, completion: completion)
        }
    }

    func signInWithGoogle(completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true

        // TODO: Integrate with Google Sign-In SDK
        // For MVP, we'll mock the response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let mockUser = User(id: UUID().uuidString, name: "Alex", email: "alex@example.com")
            self?.handleAuthSuccess(mockUser, completion: completion)
        }
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        try? storageService.clearUserData()

        // TODO: Sign out from Firebase & OAuth providers
        AnalyticsService.shared.logEvent("user_signed_out")
    }

    // MARK: - Session Management

    private func restoreSession() {
        if let user = try? storageService.fetchUser() {
            currentUser = user
            isAuthenticated = true
            AnalyticsService.shared.identifyUser(user.id)
        }
    }

    private func handleAuthSuccess(_ user: User, completion: @escaping (Result<User, AuthError>) -> Void) {
        do {
            try storageService.save(user)
            DispatchQueue.main.async { [weak self] in
                self?.currentUser = user
                self?.isAuthenticated = true
                self?.isLoading = false
                AnalyticsService.shared.identifyUser(user.id)
                AnalyticsService.shared.logEvent("user_signed_in")
                completion(.success(user))
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                completion(.failure(.storageError))
            }
        }
    }

    enum AuthError: LocalizedError {
        case signInFailed
        case signOutFailed
        case storageError
        case networkError

        var errorDescription: String? {
            switch self {
            case .signInFailed:
                return "Sign in failed. Please try again."
            case .signOutFailed:
                return "Sign out failed. Please try again."
            case .storageError:
                return "Storage error. Please try again."
            case .networkError:
                return "Network error. Please check your connection."
            }
        }
    }
}

// MARK: - Routine Service

class RoutineService: NSObject, ObservableObject {
    @Published var routines: [Routine] = []
    @Published var selectedRoutine: Routine?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()

    static let shared = RoutineService()

    override init() {
        super.init()
        loadRoutines()
    }

    // MARK: - CRUD Operations

    func loadRoutines() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let routines = try self?.storageService.fetchRoutines() ?? []
                DispatchQueue.main.async {
                    self?.routines = routines.sorted { $0.createdAt > $1.createdAt }
                    self?.isLoading = false
                    AnalyticsService.shared.logEvent("routines_loaded", properties: ["count": routines.count])
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to load routines"
                    self?.isLoading = false
                }
            }
        }
    }

    func createRoutine(_ routine: Routine) {
        do {
            try storageService.save(routine)
            routines.append(routine)
            AnalyticsService.shared.logEvent("routine_created", properties: ["name": routine.name])
        } catch {
            errorMessage = "Failed to create routine"
        }
    }

    func updateRoutine(_ routine: Routine) {
        do {
            try storageService.save(routine)
            if let index = routines.firstIndex(where: { $0.id == routine.id }) {
                routines[index] = routine
            }
            AnalyticsService.shared.logEvent("routine_updated", properties: ["name": routine.name])
        } catch {
            errorMessage = "Failed to update routine"
        }
    }

    func deleteRoutine(_ routine: Routine) {
        do {
            try storageService.delete(routine)
            routines.removeAll { $0.id == routine.id }
            AnalyticsService.shared.logEvent("routine_deleted", properties: ["name": routine.name])
        } catch {
            errorMessage = "Failed to delete routine"
        }
    }

    // MARK: - Task Management

    func completeTask(_ task: RoutineTask, in routine: Routine) {
        var updatedRoutine = routine
        if let index = updatedRoutine.tasks.firstIndex(where: { $0.id == task.id }) {
            updatedRoutine.tasks[index].complete()
            updateRoutine(updatedRoutine)
            AnalyticsService.shared.logEvent("task_completed", properties: ["task": task.name])
        }
    }

    func completeRoutine(_ routine: Routine) {
        var updatedRoutine = routine
        updatedRoutine.tasks = updatedRoutine.tasks.map { task in
            var t = task
            t.complete()
            return t
        }
        updateRoutine(updatedRoutine)
        AnalyticsService.shared.logEvent("routine_completed", properties: ["name": routine.name])
    }

    // MARK: - Suggestions

    func getSuggestedRoutines() -> [Routine] {
        // TODO: Integrate with ML model for personalized suggestions
        return [
            Routine(name: "Morning Routine"),
            Routine(name: "Evening Wind-down"),
            Routine(name: "Productivity Boost"),
        ]
    }
}

// MARK: - Local Storage Service

class StorageService {
    static let shared = StorageService()

    private let userDefaultsKey = "pulse.user"
    private let routinesKey = "pulse.routines"
    private let achievementsKey = "pulse.achievements"

    // MARK: - User Storage

    func save(_ user: User) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    func fetchUser() throws -> User? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(User.self, from: data)
    }

    func clearUserData() throws {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: routinesKey)
        UserDefaults.standard.removeObject(forKey: achievementsKey)
    }

    // MARK: - Routine Storage

    func save(_ routine: Routine) throws {
        var routines = (try? fetchRoutines()) ?? []
        routines.removeAll { $0.id == routine.id }
        routines.append(routine)

        let encoder = JSONEncoder()
        let data = try encoder.encode(routines)
        UserDefaults.standard.set(data, forKey: routinesKey)
    }

    func fetchRoutines() throws -> [Routine] {
        guard let data = UserDefaults.standard.data(forKey: routinesKey) else {
            return []
        }
        let decoder = JSONDecoder()
        return try decoder.decode([Routine].self, from: data)
    }

    func delete(_ routine: Routine) throws {
        var routines = try fetchRoutines()
        routines.removeAll { $0.id == routine.id }

        let encoder = JSONEncoder()
        let data = try encoder.encode(routines)
        UserDefaults.standard.set(data, forKey: routinesKey)
    }

    // MARK: - Achievement Storage

    func save(_ achievement: Achievement) throws {
        var achievements = (try? fetchAchievements()) ?? []
        achievements.removeAll { $0.id == achievement.id }
        achievements.append(achievement)

        let encoder = JSONEncoder()
        let data = try encoder.encode(achievements)
        UserDefaults.standard.set(data, forKey: achievementsKey)
    }

    func fetchAchievements() throws -> [Achievement] {
        guard let data = UserDefaults.standard.data(forKey: achievementsKey) else {
            return Achievement.allCases
        }
        let decoder = JSONDecoder()
        return try decoder.decode([Achievement].self, from: data)
    }
}

// MARK: - Analytics Service

class AnalyticsService {
    static let shared = AnalyticsService()

    private var userId: String?

    func identifyUser(_ userId: String) {
        self.userId = userId
        print("🔍 Analytics: Identified user \(userId)")
    }

    func logEvent(_ name: String, properties: [String: Any]? = nil) {
        var logMessage = "📊 Analytics: \(name)"
        if let properties = properties {
            logMessage += " - \(properties)"
        }
        print(logMessage)

        // TODO: Send to PostHog/Firebase Analytics
    }

    func logError(_ error: Error, context: String? = nil) {
        let message = "⚠️ Error \(context ?? ""): \(error.localizedDescription)"
        print(message)

        // TODO: Send to Sentry
    }
}

// MARK: - Notification Service

class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // TODO: Request user notification permissions
        completion(true)
    }

    func scheduleNotification(
        title: String,
        body: String,
        delay: TimeInterval = 60,
        badge: Int? = nil
    ) {
        // TODO: Schedule local notification
        print("📬 Scheduled notification: \(title)")
    }

    func scheduleRoutineReminder(for routine: Routine, at time: Date) {
        let title = "Time for \(routine.name)"
        let body = "Ready to start? Let's go! 🚀"
        scheduleNotification(title: title, body: body)
    }

    func cancelAllNotifications() {
        // TODO: Cancel all pending notifications
    }
}

// MARK: - Mock Achievement Cases

extension Achievement {
    static var allCases: [Achievement] {
        [
            .firstRoutine,
            .sevenDayStreak,
            .thirtyDayStreak,
        ]
    }
}
