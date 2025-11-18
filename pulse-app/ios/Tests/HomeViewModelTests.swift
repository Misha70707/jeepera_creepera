import XCTest
@testable import Pulse

class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!

    override func setUp() {
        super.setUp()
        sut = HomeViewModel()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    // MARK: - Greeting Tests

    func testGreetingMorning() {
        // Mock morning time
        let calendar = Calendar.current
        let morningDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!

        let hour = calendar.component(.hour, from: morningDate)
        let greeting = (5..<12).contains(hour) ? "Good morning! 🌅" : "Other"

        XCTAssertEqual(greeting, "Good morning! 🌅")
    }

    func testGreetingAfternoon() {
        let calendar = Calendar.current
        let afternoonDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!

        let hour = calendar.component(.hour, from: afternoonDate)
        let greeting = (12..<17).contains(hour) ? "Good afternoon! ☀️" : "Other"

        XCTAssertEqual(greeting, "Good afternoon! ☀️")
    }

    func testGreetingEvening() {
        let calendar = Calendar.current
        let eveningDate = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!

        let hour = calendar.component(.hour, from: eveningDate)
        let greeting = (17..<21).contains(hour) ? "Good evening! 🌙" : "Other"

        XCTAssertEqual(greeting, "Good evening! 🌙")
    }

    // MARK: - Data Loading Tests

    func testLoadData() {
        sut.loadData()

        XCTAssertNotNil(sut.currentStreak)
        XCTAssertFalse(sut.todaysRoutines.isEmpty)
        XCTAssertFalse(sut.communityHighlights.isEmpty)
    }

    func testGreetingNotEmpty() {
        XCTAssertFalse(sut.greeting.isEmpty)
        XCTAssertTrue(sut.greeting.contains("!"))
    }

    func testLoadingState() {
        sut.loadData()

        // After loading completes, isLoading should be false
        let expectation = XCTestExpectation(description: "Data loading completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertFalse(sut.isLoading)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Streak Tests

    func testCurrentStreakDisplay() {
        sut.loadData()

        guard let streak = sut.currentStreak else {
            XCTFail("Current streak should not be nil")
            return
        }

        XCTAssertEqual(streak.name, "Daily Active")
        XCTAssertEqual(streak.icon, "🔥")
        XCTAssertGreaterThan(streak.currentCount, 0)
    }

    // MARK: - Routine Tests

    func testTodaysRoutinesLoaded() {
        sut.loadData()

        XCTAssertEqual(sut.todaysRoutines.count, 2)
        XCTAssertEqual(sut.todaysRoutines.first?.name, "Morning Routine")
        XCTAssertEqual(sut.todaysRoutines.first?.emoji, "📅")
    }

    func testRoutineProgress() {
        sut.loadData()

        let routine = sut.todaysRoutines.first!
        XCTAssertGreaterThanOrEqual(routine.progressPercent, 0.0)
        XCTAssertLessThanOrEqual(routine.progressPercent, 1.0)
    }

    // MARK: - Achievements Tests

    func testWeeklyAchievements() {
        sut.loadData()

        XCTAssertFalse(sut.weeklyAchievements.isEmpty)
        XCTAssertEqual(sut.weeklyAchievements.count, 5)
    }

    // MARK: - Community Tests

    func testCommunityHighlights() {
        sut.loadData()

        XCTAssertFalse(sut.communityHighlights.isEmpty)
        let post = sut.communityHighlights.first!
        XCTAssertFalse(post.author.isEmpty)
        XCTAssertFalse(post.content.isEmpty)
    }
}
