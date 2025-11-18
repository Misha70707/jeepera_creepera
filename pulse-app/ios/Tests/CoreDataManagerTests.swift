import XCTest
import CoreData
@testable import Pulse

class CoreDataManagerTests: XCTestCase {
    var sut: CoreDataManager!

    override func setUp() {
        super.setUp()
        sut = CoreDataManager.shared
    }

    override func tearDown() {
        super.tearDown()
        try? sut.deleteAll("RoutineEntity")
        try? sut.deleteAll("RoutineTaskEntity")
    }

    // MARK: - Save Tests

    func testSaveRoutine() {
        let routine = Routine(
            name: "Morning Routine",
            emoji: "🌅",
            schedule: .daily,
            tasks: [
                RoutineTask(name: "Exercise", order: 0),
                RoutineTask(name: "Breakfast", order: 1)
            ]
        )

        sut.mainContext.perform {
            let entity = RoutineEntity(context: sut.mainContext)
            entity.id = routine.id
            entity.name = routine.name
            entity.emoji = routine.emoji
            entity.schedule = routine.schedule.rawValue

            sut.save()
        }

        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        let result = try? sut.fetch(request)

        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?.first?.name, "Morning Routine")
    }

    func testFetchRoutines() {
        // Create test data
        let context = sut.mainContext
        for i in 0..<3 {
            let entity = RoutineEntity(context: context)
            entity.id = "routine_\(i)"
            entity.name = "Routine \(i)"
            entity.emoji = "📋"
            entity.schedule = "daily"
        }
        sut.save()

        // Fetch
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        let result = try? sut.fetch(request)

        XCTAssertEqual(result?.count, 3)
    }

    func testDeleteRoutine() {
        // Create test data
        let context = sut.mainContext
        let entity = RoutineEntity(context: context)
        entity.id = "test_routine"
        entity.name = "Test"
        entity.emoji = "📋"
        entity.schedule = "daily"
        sut.save()

        // Delete
        sut.delete(entity)

        // Verify deletion
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        let result = try? sut.fetch(request)

        XCTAssertEqual(result?.count, 0)
    }

    // MARK: - Concurrency Tests

    func testBackgroundContextOperations() {
        let backgroundContext = sut.backgroundContext()

        backgroundContext.perform {
            let entity = RoutineEntity(context: backgroundContext)
            entity.id = "bg_routine"
            entity.name = "Background Test"
            entity.emoji = "🔄"
            entity.schedule = "daily"

            try? backgroundContext.save()
        }

        // Verify in main context
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", "bg_routine")
        let result = try? sut.fetch(request)

        XCTAssertEqual(result?.first?.name, "Background Test")
    }

    // MARK: - Error Handling Tests

    func testInvalidFetchRequest() {
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        request.returnsObjectsAsFaults = false

        let result = try? sut.fetch(request)
        XCTAssertNotNil(result)
    }
}
