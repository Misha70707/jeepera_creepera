# Firebase Setup & Integration - Complete Implementation Guide

**Status:** Phase 3 Implementation Guide
**Date:** November 18, 2025
**Target:** Full Firebase integration for iOS and Android

---

## Table of Contents

1. [Firebase Project Setup](#firebase-project-setup)
2. [iOS Core Data Integration](#ios-core-data-integration)
3. [Android Room Integration](#android-room-integration)
4. [Firestore Sync Strategy](#firestore-sync-strategy)
5. [Authentication Implementation](#authentication-implementation)
6. [Testing & Verification](#testing--verification)

---

## Firebase Project Setup

### Step 1: Create Firebase Project

```bash
# Using Firebase CLI
firebase init

# Or manually at: https://console.firebase.google.com
```

**Configuration:**
- **Project Name:** pulse-app-dev (development), pulse-app-prod (production)
- **Default Region:** us-central1
- **Enable Firestore:** Yes
- **Enable Authentication:** Yes
- **Enable Cloud Functions:** Yes
- **Enable Storage:** Yes (for profile photos)

### Step 2: Enable Required Services

In Firebase Console, enable:

1. **Firestore Database**
   - Location: us-central1
   - Start in production mode (we'll set rules)
   - Collections: users, routines, tasks, posts, comments, tribes, achievements, leaderboard

2. **Authentication**
   - Enable: Apple Sign-In
   - Enable: Google Sign-In
   - Enable: Email/Password (optional, for testing)

3. **Cloud Functions**
   - Runtime: Node.js 18+
   - Region: us-central1

4. **Cloud Storage**
   - Location: us-central1
   - For user profile images

5. **Realtime Database (Optional)**
   - For real-time features like notifications

### Step 3: Download Service Account Key

```bash
# For backend/Cloud Functions
# Firebase Console → Project Settings → Service Accounts → Generate New Private Key
# Save as: backend/serviceAccountKey.json
```

**⚠️ IMPORTANT:** Add `serviceAccountKey.json` to `.gitignore`!

```bash
echo "backend/serviceAccountKey.json" >> .gitignore
```

### Step 4: Get Configuration Files

**For iOS:**
```bash
# Firebase Console → Project Settings → iOS app
# Download GoogleService-Info.plist
# Add to: ios/Pulse/GoogleService-Info.plist
```

**For Android:**
```bash
# Firebase Console → Project Settings → Android app
# Download google-services.json
# Add to: android/app/google-services.json
```

---

## iOS Core Data Integration

### Step 1: Install Firebase SDK

```bash
cd ios
pod install --repo-update
```

**Podfile additions:**
```ruby
pod 'Firebase/Core'
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
pod 'Firebase/Storage'
```

### Step 2: Create Core Data Model

Create `ios/Pulse/Pulse.xcdatamodeld/Pulse.xcdatamodel`:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel"
       documentVersion="1.0"
       lastSavedToolsVersion="20.1"
       systemVersion="13.0"
       minimumToolsVersion="Automatic"
       sourceLanguage="Swift"
       userDefinedModelVersionIdentifier="">

    <!-- User Entity -->
    <entity name="UserEntity" representedClassName="UserEntity" syncable="YES" codeGenerationType="class">
        <attribute name="id" attributeType="String" required="YES"/>
        <attribute name="name" attributeType="String" required="YES"/>
        <attribute name="email" attributeType="String" required="YES"/>
        <attribute name="avatar" attributeType="String" optional="YES"/>
        <attribute name="createdAt" attributeType="Date" defaultDateTimeInterval="0" usesScalarValueType="NO"/>
        <attribute name="updatedAt" attributeType="Date" defaultDateTimeInterval="0" usesScalarValueType="NO"/>
        <relationship name="routines" toMany="YES" deletionRule="Cascade" destinationEntity="RoutineEntity" inverseName="user" inverseEntity="RoutineEntity"/>
        <relationship name="posts" toMany="YES" deletionRule="Cascade" destinationEntity="PostEntity" inverseName="author" inverseEntity="PostEntity"/>
    </entity>

    <!-- Routine Entity -->
    <entity name="RoutineEntity" representedClassName="RoutineEntity" syncable="YES" codeGenerationType="class">
        <attribute name="id" attributeType="String" required="YES"/>
        <attribute name="name" attributeType="String" required="YES"/>
        <attribute name="emoji" attributeType="String" required="YES"/>
        <attribute name="schedule" attributeType="String" required="YES"/>
        <attribute name="createdAt" attributeType="Date" defaultDateTimeInterval="0" usesScalarValueType="NO"/>
        <attribute name="completedToday" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
        <relationship name="user" maxCount="1" deletionRule="Nullify" destinationEntity="UserEntity" inverseName="routines" inverseEntity="UserEntity"/>
        <relationship name="tasks" toMany="YES" deletionRule="Cascade" destinationEntity="RoutineTaskEntity" inverseName="routine" inverseEntity="RoutineTaskEntity"/>
    </entity>

    <!-- Routine Task Entity -->
    <entity name="RoutineTaskEntity" representedClassName="RoutineTaskEntity" syncable="YES" codeGenerationType="class">
        <attribute name="id" attributeType="String" required="YES"/>
        <attribute name="name" attributeType="String" required="YES"/>
        <attribute name="order" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="isCompleted" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
        <attribute name="estimatedDuration" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES"/>
        <relationship name="routine" maxCount="1" deletionRule="Nullify" destinationEntity="RoutineEntity" inverseName="tasks" inverseEntity="RoutineEntity"/>
    </entity>

    <!-- Post Entity -->
    <entity name="PostEntity" representedClassName="PostEntity" syncable="YES" codeGenerationType="class">
        <attribute name="id" attributeType="String" required="YES"/>
        <attribute name="content" attributeType="String" required="YES"/>
        <attribute name="tribe" attributeType="String" required="YES"/>
        <attribute name="createdAt" attributeType="Date" defaultDateTimeInterval="0" usesScalarValueType="NO"/>
        <attribute name="likeCount" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="commentCount" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="likedByUser" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
        <relationship name="author" maxCount="1" deletionRule="Nullify" destinationEntity="UserEntity" inverseName="posts" inverseEntity="UserEntity"/>
    </entity>

    <!-- Achievement Entity -->
    <entity name="AchievementEntity" representedClassName="AchievementEntity" syncable="YES" codeGenerationType="class">
        <attribute name="id" attributeType="String" required="YES"/>
        <attribute name="name" attributeType="String" required="YES"/>
        <attribute name="icon" attributeType="String" required="YES"/>
        <attribute name="description" attributeType="String" optional="YES"/>
        <attribute name="isUnlocked" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
        <attribute name="unlockedAt" attributeType="Date" optional="YES" usesScalarValueType="NO"/>
    </entity>

</model>
```

### Step 3: Implement CoreDataManager

Create `ios/Pulse/Persistence/CoreDataManager.swift`:

```swift
import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Pulse")

        // Enable history tracking for sync
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
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

    func save() {
        let context = mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func delete(_ object: NSManagedObject) {
        mainContext.delete(object)
        save()
    }
}
```

### Step 4: Implement Repositories

Create `ios/Pulse/Repositories/RoutineRepository.swift`:

```swift
import CoreData
import Foundation
import FirebaseFirestore

class RoutineRepository {
    private let coreDataManager = CoreDataManager.shared
    private let db = Firestore.firestore()

    // MARK: - Local Operations

    func saveRoutine(_ routine: Routine) {
        let context = coreDataManager.mainContext
        let entity = RoutineEntity(context: context)

        entity.id = routine.id
        entity.name = routine.name
        entity.emoji = routine.emoji
        entity.schedule = routine.schedule.rawValue
        entity.createdAt = Date()

        coreDataManager.save()

        // Sync to Firestore
        syncToFirestore(entity)
    }

    func fetchRoutines() -> [Routine] {
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()

        do {
            let entities = try coreDataManager.mainContext.fetch(request)
            return entities.map { toDomain($0) }
        } catch {
            print("Error fetching routines: \(error)")
            return []
        }
    }

    func deleteRoutine(id: String) {
        let request: NSFetchRequest<RoutineEntity> = RoutineEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try coreDataManager.mainContext.fetch(request)
            entities.forEach { coreDataManager.delete($0) }

            // Delete from Firestore
            db.collection("routines").document(id).delete()
        } catch {
            print("Error deleting routine: \(error)")
        }
    }

    // MARK: - Firestore Sync

    private func syncToFirestore(_ entity: RoutineEntity) {
        guard let id = entity.id else { return }

        let data: [String: Any] = [
            "name": entity.name ?? "",
            "emoji": entity.emoji ?? "📋",
            "schedule": entity.schedule ?? "daily",
            "createdAt": Timestamp(date: entity.createdAt ?? Date()),
            "updatedAt": Timestamp(date: Date())
        ]

        db.collection("routines").document(id).setData(data, merge: true) { error in
            if let error = error {
                print("Error syncing to Firestore: \(error)")
            }
        }
    }

    // MARK: - Helper

    private func toDomain(_ entity: RoutineEntity) -> Routine {
        Routine(
            id: entity.id ?? UUID().uuidString,
            name: entity.name ?? "Untitled",
            emoji: entity.emoji ?? "📋",
            schedule: RoutineSchedule(rawValue: entity.schedule ?? "daily") ?? .daily
        )
    }
}
```

---

## Android Room Integration

### Step 1: Add Room Dependencies

Add to `android/build.gradle`:

```gradle
dependencies {
    def room_version = "2.6.1"

    implementation "androidx.room:room-runtime:$room_version"
    implementation "androidx.room:room-ktx:$room_version"
    kapt "androidx.room:room-compiler:$room_version"

    // Firebase
    implementation "com.google.firebase:firebase-firestore-ktx:24.10.2"
    implementation "com.google.firebase:firebase-auth-ktx:22.3.1"
}
```

### Step 2: Define Room Entities

Create `android/app/src/main/java/com/pulse/app/database/Entities.kt`:

```kotlin
package com.pulse.app.database

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.PrimaryKey
import com.google.firebase.Timestamp

// User Entity
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    val avatar: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

// Routine Entity
@Entity(
    tableName = "routines",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["userId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class RoutineEntity(
    @PrimaryKey val id: String,
    val userId: String? = null,
    val name: String,
    val emoji: String = "📋",
    val schedule: String = "daily",
    val createdAt: Long = System.currentTimeMillis(),
    val completedToday: Boolean = false,
    val synced: Boolean = false
)

// Routine Task Entity
@Entity(
    tableName = "routine_tasks",
    foreignKeys = [
        ForeignKey(
            entity = RoutineEntity::class,
            parentColumns = ["id"],
            childColumns = ["routineId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class RoutineTaskEntity(
    @PrimaryKey val id: String,
    val routineId: String,
    val name: String,
    val order: Int = 0,
    val isCompleted: Boolean = false,
    val estimatedDuration: Int = 0
)

// Post Entity
@Entity(
    tableName = "posts",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["authorId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class PostEntity(
    @PrimaryKey val id: String,
    val authorId: String? = null,
    val content: String,
    val tribe: String,
    val createdAt: Long = System.currentTimeMillis(),
    val likeCount: Int = 0,
    val commentCount: Int = 0,
    val likedByUser: Boolean = false,
    val synced: Boolean = false
)

// Achievement Entity
@Entity(tableName = "achievements")
data class AchievementEntity(
    @PrimaryKey val id: String,
    val name: String,
    val icon: String,
    val description: String? = null,
    val isUnlocked: Boolean = false,
    val unlockedAt: Long? = null
)
```

### Step 3: Create DAOs

Create `android/app/src/main/java/com/pulse/app/database/AppDatabase.kt`:

```kotlin
package com.pulse.app.database

import android.content.Context
import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Database(
    entities = [
        UserEntity::class,
        RoutineEntity::class,
        RoutineTaskEntity::class,
        PostEntity::class,
        AchievementEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class PulseDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun routineDao(): RoutineDao
    abstract fun taskDao(): TaskDao
    abstract fun postDao(): PostDao
    abstract fun achievementDao(): AchievementDao

    companion object {
        @Volatile
        private var INSTANCE: PulseDatabase? = null

        fun getDatabase(context: Context): PulseDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    PulseDatabase::class.java,
                    "pulse_db"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}

@Dao
interface UserDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(user: UserEntity)

    @Query("SELECT * FROM users WHERE id = :id")
    fun getUser(id: String): Flow<UserEntity?>

    @Query("SELECT * FROM users")
    fun getAllUsers(): Flow<List<UserEntity>>

    @Delete
    suspend fun delete(user: UserEntity)
}

@Dao
interface RoutineDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(routine: RoutineEntity)

    @Query("SELECT * FROM routines WHERE id = :id")
    fun getRoutine(id: String): Flow<RoutineEntity?>

    @Query("SELECT * FROM routines WHERE userId = :userId")
    fun getUserRoutines(userId: String): Flow<List<RoutineEntity>>

    @Query("SELECT * FROM routines WHERE completedToday = 0")
    fun getIncompleteRoutines(): Flow<List<RoutineEntity>>

    @Update
    suspend fun update(routine: RoutineEntity)

    @Delete
    suspend fun delete(routine: RoutineEntity)
}

@Dao
interface TaskDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(task: RoutineTaskEntity)

    @Query("SELECT * FROM routine_tasks WHERE routineId = :routineId ORDER BY `order`")
    fun getRoutineTasks(routineId: String): Flow<List<RoutineTaskEntity>>

    @Update
    suspend fun update(task: RoutineTaskEntity)

    @Delete
    suspend fun delete(task: RoutineTaskEntity)
}

@Dao
interface PostDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(post: PostEntity)

    @Query("SELECT * FROM posts WHERE tribe = :tribe ORDER BY createdAt DESC")
    fun getPostsByTribe(tribe: String): Flow<List<PostEntity>>

    @Query("SELECT * FROM posts ORDER BY createdAt DESC")
    fun getAllPosts(): Flow<List<PostEntity>>

    @Update
    suspend fun update(post: PostEntity)

    @Delete
    suspend fun delete(post: PostEntity)
}

@Dao
interface AchievementDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(achievement: AchievementEntity)

    @Query("SELECT * FROM achievements WHERE isUnlocked = 1")
    fun getUnlockedAchievements(): Flow<List<AchievementEntity>>

    @Query("SELECT * FROM achievements")
    fun getAllAchievements(): Flow<List<AchievementEntity>>

    @Update
    suspend fun update(achievement: AchievementEntity)
}
```

---

## Firestore Sync Strategy

### Optimistic Updates + Background Sync

```kotlin
// In RoutineRepository
suspend fun syncRoutineToCloud(routine: Routine) {
    // 1. Update local immediately (optimistic)
    saveRoutine(routine)

    // 2. Sync to Firestore asynchronously
    try {
        val routineData = mapOf(
            "name" to routine.name,
            "emoji" to routine.emoji,
            "schedule" to routine.schedule,
            "updatedAt" to FieldValue.serverTimestamp()
        )

        db.collection("routines")
            .document(routine.id)
            .set(routineData, SetOptions.merge())
            .await()

        // Mark as synced
        updateSyncStatus(routine.id, synced = true)
    } catch (e: Exception) {
        // Mark for retry later
        updateSyncStatus(routine.id, synced = false)
    }
}
```

### Conflict Resolution: Last-Write-Wins

```kotlin
// When syncing from cloud
fun applyCloudChanges(cloudData: Map<String, Any>, localEntity: RoutineEntity) {
    val cloudUpdatedAt = (cloudData["updatedAt"] as? Timestamp)?.toDate()?.time ?: 0L

    if (cloudUpdatedAt > localEntity.updatedAt) {
        // Cloud version is newer, apply it
        updateLocal(cloudData)
    } else {
        // Local version is newer or equal, keep local
    }
}
```

---

## Authentication Implementation

### iOS AuthService Update

```swift
import FirebaseAuth
import AuthenticationServices

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var error: String?

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            error = "Unable to fetch identity token"
            return
        }

        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                         idToken: tokenString,
                                                         rawNonce: UUID().uuidString)

        Auth.auth().signIn(with: firebaseCredential) { [weak self] authResult, error in
            if let error = error {
                self?.error = error.localizedDescription
                return
            }

            self?.isAuthenticated = true
            self?.currentUser = User(
                id: authResult?.user.uid ?? "",
                name: credential.fullName?.givenName ?? "User",
                email: credential.email ?? ""
            )
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
        } catch let error {
            self.error = error.localizedDescription
        }
    }
}
```

### Android AuthViewModel Update

```kotlin
class AuthViewModel : ViewModel() {
    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated

    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser

    fun signInWithGoogle(idToken: String) {
        viewModelScope.launch {
            try {
                val credential = GoogleAuthProvider.getCredential(idToken, null)
                FirebaseAuth.getInstance()
                    .signInWithCredential(credential)
                    .await()

                val firebaseUser = FirebaseAuth.getInstance().currentUser
                _currentUser.value = User(
                    id = firebaseUser?.uid ?: "",
                    name = firebaseUser?.displayName ?: "User",
                    email = firebaseUser?.email ?: ""
                )
                _isAuthenticated.value = true
            } catch (e: Exception) {
                // Handle error
            }
        }
    }

    fun signOut() {
        FirebaseAuth.getInstance().signOut()
        _isAuthenticated.value = false
        _currentUser.value = null
    }
}
```

---

## Testing & Verification

### Phase 3 Verification Checklist

- [ ] Firebase project created and configured
- [ ] iOS Core Data model created
- [ ] iOS CoreDataManager implemented
- [ ] iOS RoutineRepository implemented
- [ ] iOS Authentication working with Firebase
- [ ] Android Room database created with all entities
- [ ] Android DAOs fully implemented
- [ ] Android syncing logic implemented
- [ ] Android Authentication working with Firebase
- [ ] Local → Cloud sync working bidirectionally
- [ ] Offline-first behavior verified
- [ ] Firestore rules deployed
- [ ] Cloud Functions deployed
- [ ] End-to-end testing completed

### Test Scenarios

**Offline Behavior:**
1. Disable network
2. Create routine
3. Complete tasks
4. Re-enable network
5. Verify sync

**Real-time Sync:**
1. Create post on device A
2. Verify appears on device B immediately
3. Like on device B
4. Verify like count updates on device A

**Authentication:**
1. Sign in with Apple (iOS) / Google (Android)
2. Verify user saved in Core Data / Room
3. Verify Firestore user document created
4. Sign out and verify local data persisted

---

## Summary

This implementation provides:

✅ **Local-first architecture** with Core Data (iOS) and Room (Android)
✅ **Automatic cloud sync** with Firestore
✅ **Offline support** with optimistic updates
✅ **Real-time collaboration** with Firestore listeners
✅ **Secure authentication** with Firebase Auth
✅ **Conflict resolution** with last-write-wins strategy

**Next Steps:**
- Deploy Firestore Security Rules
- Deploy Cloud Functions
- Run integration tests
- Performance testing
- Launch preparation

---

**Document Version:** 1.0
**Last Updated:** November 18, 2025
**Next Phase:** Testing & Launch Preparation
