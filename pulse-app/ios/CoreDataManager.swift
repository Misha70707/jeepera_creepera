import CoreData
import Foundation
import Combine

// MARK: - Core Data Manager
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Pulse")

        // Enable history tracking for sync
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func backgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    func save(context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? mainContext
        if contextToSave.hasChanges {
            do {
                try contextToSave.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func delete(_ object: NSManagedObject, in context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? mainContext
        contextToUse.delete(object)
        save(context: contextToUse)
    }

    func fetch<T: NSFetchRequestResult>(_ request: NSFetchRequest<T>, in context: NSManagedObjectContext? = nil) throws -> [T] {
        let contextToUse = context ?? mainContext
        return try contextToUse.fetch(request)
    }

    func deleteAll(_ entityName: String) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try mainContext.execute(deleteRequest)
        save()
    }
}

// MARK: - Managed Object Extensions

extension NSManagedObject {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        for attribute in entity.attributesByName {
            if let value = value(forKey: attribute.key) {
                dict[attribute.key] = value
            }
        }

        return dict
    }
}

// MARK: - Core Data Error Handler
enum CoreDataError: Error {
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case invalidData(String)

    var description: String {
        switch self {
        case .fetchFailed(let error):
            return "Fetch failed: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
