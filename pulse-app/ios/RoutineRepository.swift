import CoreData
import Foundation
import Combine
import FirebaseFirestore

// MARK: - Routine Repository
class RoutineRepository: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    private let db = Firestore.firestore()
    @Published var routines: [Routine] = []
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?

    init() {
        loadRoutinesFromLocal()
        setupFirestoreListener()
    }

    // MARK: - Local Operations

    func saveRoutine(_ routine: Routine) {
        let context = coreDataManager.mainContext
        let routineEntity = RoutineEntity(context: context)

        routineEntity.id = routine.id
        routineEntity.name = routine.name
        routineEntity.emoji = routine.emoji
        routineEntity.schedule = routine.schedule.rawValue
        routineEntity.createdAt = routine.createdAt

        // Save tasks
        routine.tasks.forEach { task in
            let taskEntity = RoutineTaskEntity(context: context)
            taskEntity.id = task.id
            taskEntity.name = task.name
            taskEntity.order = Int32(task.order)
            taskEntity.isCompleted = task.isCompleted
            taskEntity.estimatedDuration = Int32(task.estimatedDuration ?? 0)
            taskEntity.routine = routineEntity
        }

        coreDataManager.save()
        loadRoutinesFromLocal()

        // Sync to Firestore
        syncRoutineToFirestore(routine)
    }

    func fetchRoutines() -> [Routine] {
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RoutineEntity.createdAt, ascending: false)]

        do {
            let entities = try coreDataManager.fetch(request)
            return entities.map { entity in
                let tasks = (entity.tasks as? Set<RoutineTaskEntity> ?? [])
                    .sorted { $0.order < $1.order }
                    .map { Routine.Task(id: $0.id ?? "", name: $0.name ?? "", isCompleted: $0.isCompleted, order: Int($0.order)) }

                return Routine(
                    id: entity.id ?? UUID().uuidString,
                    name: entity.name ?? "Untitled",
                    emoji: entity.emoji ?? "📋",
                    schedule: RoutineSchedule(rawValue: entity.schedule ?? "daily") ?? .daily,
                    tasks: tasks,
                    createdAt: entity.createdAt ?? Date()
                )
            }
        } catch {
            print("Error fetching routines: \(error)")
            return []
        }
    }

    func updateRoutine(_ routine: Routine) {
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", routine.id)

        do {
            let entities = try coreDataManager.fetch(request)
            if let entity = entities.first {
                entity.name = routine.name
                entity.emoji = routine.emoji
                entity.schedule = routine.schedule.rawValue

                // Update tasks
                entity.tasks?.forEach { coreDataManager.mainContext.delete($0 as! NSManagedObject) }

                routine.tasks.forEach { task in
                    let taskEntity = RoutineTaskEntity(context: coreDataManager.mainContext)
                    taskEntity.id = task.id
                    taskEntity.name = task.name
                    taskEntity.order = Int32(task.order)
                    taskEntity.isCompleted = task.isCompleted
                    taskEntity.routine = entity
                }

                coreDataManager.save()
                loadRoutinesFromLocal()
                syncRoutineToFirestore(routine)
            }
        } catch {
            print("Error updating routine: \(error)")
        }
    }

    func deleteRoutine(id: String) {
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try coreDataManager.fetch(request)
            entities.forEach { entity in
                coreDataManager.delete(entity)
            }
            loadRoutinesFromLocal()

            // Delete from Firestore
            db.collection("routines").document(id).delete { [weak self] error in
                if let error = error {
                    print("Error deleting from Firestore: \(error)")
                } else {
                    self?.lastSyncTime = Date()
                }
            }
        } catch {
            print("Error deleting routine: \(error)")
        }
    }

    func completeTask(routineId: String, taskId: String) {
        let request: NSFetchRequest<RoutineTaskEntity> = RoutineTaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", taskId)

        do {
            let entities = try coreDataManager.fetch(request)
            if let taskEntity = entities.first {
                taskEntity.isCompleted = true
                coreDataManager.save()
                loadRoutinesFromLocal()

                // Sync to Firestore
                if let routine = routines.first(where: { $0.id == routineId }) {
                    syncRoutineToFirestore(routine)
                }
            }
        } catch {
            print("Error completing task: \(error)")
        }
    }

    // MARK: - Firestore Sync

    private func syncRoutineToFirestore(_ routine: Routine) {
        isSyncing = true

        let tasksData = routine.tasks.map { task -> [String: Any] in
            [
                "id": task.id,
                "name": task.name,
                "order": task.order,
                "isCompleted": task.isCompleted,
                "estimatedDuration": task.estimatedDuration ?? 0
            ]
        }

        let data: [String: Any] = [
            "name": routine.name,
            "emoji": routine.emoji,
            "schedule": routine.schedule.rawValue,
            "tasks": tasksData,
            "createdAt": Timestamp(date: routine.createdAt),
            "updatedAt": Timestamp(date: Date())
        ]

        db.collection("routines").document(routine.id).setData(data, merge: true) { [weak self] error in
            self?.isSyncing = false
            if let error = error {
                print("Error syncing to Firestore: \(error)")
            } else {
                self?.lastSyncTime = Date()
            }
        }
    }

    private func setupFirestoreListener() {
        db.collection("routines")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching Firestore documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Merge with local data
                for doc in documents {
                    let data = doc.data()
                    self?.mergeFirestoreData(data, documentId: doc.documentID)
                }
            }
    }

    private func mergeFirestoreData(_ data: [String: Any], documentId: String) {
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", documentId)

        do {
            let entities = try coreDataManager.fetch(request)

            if let entity = entities.first {
                // Local version is more recent, don't overwrite
                if let localUpdatedAt = entity.updatedAt,
                   let remoteUpdatedAt = (data["updatedAt"] as? Timestamp)?.dateValue(),
                   localUpdatedAt > remoteUpdatedAt {
                    return
                }

                // Apply remote changes
                if let name = data["name"] as? String {
                    entity.name = name
                }
                if let emoji = data["emoji"] as? String {
                    entity.emoji = emoji
                }
                if let schedule = data["schedule"] as? String {
                    entity.schedule = schedule
                }
                if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
                    entity.createdAt = createdAt
                }

                coreDataManager.save()
                loadRoutinesFromLocal()
            } else {
                // Create new routine from Firestore
                if let routine = routineFromFirestore(data, id: documentId) {
                    saveRoutine(routine)
                }
            }
        } catch {
            print("Error merging Firestore data: \(error)")
        }
    }

    private func routineFromFirestore(_ data: [String: Any], id: String) -> Routine? {
        guard let name = data["name"] as? String else { return nil }

        let emoji = data["emoji"] as? String ?? "📋"
        let scheduleStr = data["schedule"] as? String ?? "daily"
        let schedule = RoutineSchedule(rawValue: scheduleStr) ?? .daily
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        var tasks: [RoutineTask] = []
        if let tasksData = data["tasks"] as? [[String: Any]] {
            tasks = tasksData.compactMap { taskData in
                guard let id = taskData["id"] as? String,
                      let name = taskData["name"] as? String else { return nil }

                let order = taskData["order"] as? Int ?? 0
                let isCompleted = taskData["isCompleted"] as? Bool ?? false
                let duration = taskData["estimatedDuration"] as? Int

                return RoutineTask(
                    id: id,
                    name: name,
                    order: order,
                    isCompleted: isCompleted,
                    estimatedDuration: duration
                )
            }
        }

        return Routine(
            id: id,
            name: name,
            emoji: emoji,
            schedule: schedule,
            tasks: tasks,
            createdAt: createdAt
        )
    }

    // MARK: - Private Helpers

    private func loadRoutinesFromLocal() {
        DispatchQueue.main.async {
            self.routines = self.fetchRoutines()
        }
    }
}

// MARK: - Core Data Entities

@NSManaged class RoutineEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var emoji: String
    @NSManaged var schedule: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var completedToday: Bool
    @NSManaged var tasks: NSSet

    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue(Date(), forKey: "updatedAt")
    }
}

@NSManaged class RoutineTaskEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var order: Int32
    @NSManaged var isCompleted: Bool
    @NSManaged var estimatedDuration: Int32
    @NSManaged var routine: RoutineEntity
}
