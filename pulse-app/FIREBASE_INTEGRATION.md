# Firebase & Local Persistence Integration Guide

**This is the critical bridge between the UI and real data**

---

## **Overview**

The Pulse App uses a **hybrid persistence strategy**:
- **Local**: Core Data (iOS) + Room (Android) for offline-first operation
- **Cloud**: Firebase Firestore for real-time sync and community features
- **Auth**: Firebase Authentication with Apple/Google Sign-In
- **Functions**: Cloud Functions for server-side logic (routine suggestions, achievements, notifications)

---

## **Part 1: Firebase Project Setup**

### **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Name: "Pulse App MVP"
4. Region: `us-central1`
5. Enable Google Analytics (optional)
6. Create project

### **Step 2: Enable Services**

#### **Authentication**
1. Authentication → Sign-in method
2. Enable:
   - Apple (iOS only, requires Apple Developer account)
   - Google (requires OAuth credentials)
3. Add test accounts for development

#### **Firestore Database**
1. Firestore Database → Create Database
2. Location: `us-central1`
3. Security rules: **Start in test mode** (secure later)
4. Create

#### **Cloud Storage** (for profile photos, future use)
1. Cloud Storage → Create Bucket
2. Location: `us-central1`
3. Access: Private (require authentication)

#### **Cloud Functions**
1. Cloud Functions → Create Function
2. Runtime: Node.js 18
3. Trigger: Firestore
4. Deploy our Cloud Functions code

### **Step 3: Get Firebase Config**

#### **iOS**
1. Project Settings → Your apps
2. Add iOS app
3. Bundle ID: `com.pulse.app`
4. Download `GoogleService-Info.plist`
5. Add to Xcode project (Copy if needed, Add to targets)

#### **Android**
1. Project Settings → Your apps
2. Add Android app
3. Package name: `com.pulse.app`
4. SHA-1: Get from `./gradlew signingReport`
5. Download `google-services.json`
6. Place in `android/app/` directory

---

## **Part 2: iOS - Core Data Setup**

### **Create Core Data Model**

Create `Pulse.xcdatamodeld` in Xcode:

```
Entities:
├── UserEntity
│   ├── id (String)
│   ├── name (String)
│   ├── email (String)
│   ├── createdAt (Date)
│   └── preferences (String) [JSON]
│
├── RoutineEntity
│   ├── id (String)
│   ├── name (String)
│   ├── emoji (String)
│   ├── tasks (String) [JSON array]
│   ├── isCompleted (Bool)
│   ├── completedDate (Date)
│   └── user (UserEntity) [relationship]
│
├── PostEntity
│   ├── id (String)
│   ├── author (String)
│   ├── content (String)
│   ├── tribeId (String)
│   ├── createdAt (Date)
│   └── reactions (String) [JSON]
│
└── AchievementEntity
    ├── id (String)
    ├── name (String)
    ├── unlockedAt (Date)
    └── user (UserEntity) [relationship]
```

### **Implement Core Data Manager**

```swift
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentCloudKitContainer

    init() {
        persistentContainer = NSPersistentCloudKitContainer(name: "Pulse")

        // Enable CloudKit sync
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.pulse.app")
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Core Data Error: \(error)")
            }
        }

        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromTheKeyWindow = true
    }

    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved")
            } catch {
                print("❌ Save failed: \(error)")
            }
        }
    }
}
```

### **Implement Routine Repository**

```swift
import CoreData

class RoutineRepository {
    static let shared = RoutineRepository()
    let coreDataManager = CoreDataManager.shared

    func saveRoutine(_ routine: Routine) {
        let context = coreDataManager.persistentContainer.viewContext

        let routineEntity = NSEntityDescription.insertNewObject(
            forEntityName: "RoutineEntity",
            into: context
        ) as! RoutineEntity

        routineEntity.id = routine.id
        routineEntity.name = routine.name
        routineEntity.emoji = routine.emoji
        routineEntity.tasks = try? JSONEncoder().encode(routine.tasks)
        routineEntity.isCompleted = routine.tasks.allSatisfy { $0.isCompleted }

        coreDataManager.save()
    }

    func fetchRoutines() -> [Routine] {
        let context = coreDataManager.persistentContainer.viewContext
        let request = NSFetchRequest<RoutineEntity>(entityName: "RoutineEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RoutineEntity.createdAt, ascending: false)]

        do {
            let entities = try context.fetch(request)
            return entities.map { entity in
                var routine = Routine(name: entity.name ?? "")
                routine.id = entity.id ?? ""
                if let tasksData = entity.tasks {
                    routine.tasks = (try? JSONDecoder().decode([RoutineTask].self, from: tasksData)) ?? []
                }
                return routine
            }
        } catch {
            print("❌ Fetch failed: \(error)")
            return []
        }
    }

    func deleteRoutine(_ id: String) {
        let context = coreDataManager.persistentContainer.viewContext
        let request = NSFetchRequest<RoutineEntity>(entityName: "RoutineEntity")
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
            coreDataManager.save()
        } catch {
            print("❌ Delete failed: \(error)")
        }
    }
}
```

### **Update Services to Use Core Data**

```swift
// In RoutineService.swift
class RoutineService: NSObject, ObservableObject {
    // ... existing code ...

    func loadRoutines() {
        routines = RoutineRepository.shared.fetchRoutines()
        isLoading = false
    }

    func createRoutine(_ routine: Routine) {
        RoutineRepository.shared.saveRoutine(routine)
        loadRoutines()
    }
}
```

---

## **Part 3: Android - Room Database Setup**

### **Create Room Entities**

Already created in `Models.kt` with `@Entity` annotations.

### **Implement DAOs (Data Access Objects)**

```kotlin
// File: android/app/src/main/java/com/pulse/app/data/dao/RoutineDao.kt

import androidx.room.*
import com.pulse.app.data.models.Routine
import kotlinx.coroutines.flow.Flow

@Dao
interface RoutineDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRoutine(routine: Routine)

    @Query("SELECT * FROM routines ORDER BY createdAt DESC")
    fun getAllRoutines(): Flow<List<Routine>>

    @Query("SELECT * FROM routines WHERE id = :id")
    suspend fun getRoutineById(id: String): Routine?

    @Update
    suspend fun updateRoutine(routine: Routine)

    @Delete
    suspend fun deleteRoutine(routine: Routine)

    @Query("DELETE FROM routines WHERE id = :id")
    suspend fun deleteRoutineById(id: String)
}
```

### **Create Room Database**

```kotlin
// File: android/app/src/main/java/com/pulse/app/data/database/PulseDatabase.kt

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.pulse.app.data.dao.RoutineDao
import com.pulse.app.data.dao.AchievementDao
import com.pulse.app.data.models.*

@Database(
    entities = [
        User::class,
        Routine::class,
        RoutineTask::class,
        Post::class,
        Achievement::class,
        Streak::class
    ],
    version = 1,
    exportSchema = false
)
abstract class PulseDatabase : RoomDatabase() {
    abstract fun routineDao(): RoutineDao
    abstract fun achievementDao(): AchievementDao

    companion object {
        @Volatile
        private var INSTANCE: PulseDatabase? = null

        fun getInstance(context: Context): PulseDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    PulseDatabase::class.java,
                    "pulse_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
```

### **Update Repository Pattern**

```kotlin
// File: android/app/src/main/java/com/pulse/app/data/repository/RoutineRepository.kt

import com.pulse.app.data.dao.RoutineDao
import com.pulse.app.data.models.Routine
import kotlinx.coroutines.flow.Flow

class RoutineRepository(private val routineDao: RoutineDao) {
    fun getAllRoutines(): Flow<List<Routine>> = routineDao.getAllRoutines()

    suspend fun insertRoutine(routine: Routine) {
        routineDao.insertRoutine(routine)
    }

    suspend fun updateRoutine(routine: Routine) {
        routineDao.updateRoutine(routine)
    }

    suspend fun deleteRoutine(id: String) {
        routineDao.deleteRoutineById(id)
    }
}
```

### **Update ViewModel to Use Repository**

```kotlin
// In RoutineViewModel.kt
class RoutineViewModel(private val repository: RoutineRepository) : ViewModel() {
    private val _routines = MutableStateFlow<List<Routine>>(emptyList())
    val routines: StateFlow<List<Routine>> = _routines.asStateFlow()

    init {
        loadRoutines()
    }

    private fun loadRoutines() {
        viewModelScope.launch {
            repository.getAllRoutines().collect { routines ->
                _routines.value = routines
            }
        }
    }

    fun createRoutine(routine: Routine) {
        viewModelScope.launch {
            repository.insertRoutine(routine)
        }
    }
}
```

---

## **Part 4: Firebase Firestore Sync**

### **iOS: Firestore Listener**

```swift
import Firebase

class FirestoreService: NSObject, ObservableObject {
    @Published var routines: [Routine] = []
    @Published var posts: [Post] = []

    let db = Firestore.firestore()

    func startListeningToRoutines(userId: String) {
        db.collection("users").document(userId).collection("routines")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Firestore error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.routines = documents.compactMap { doc in
                    let data = doc.data()
                    var routine = Routine(name: data["name"] as? String ?? "")
                    routine.id = doc.documentID
                    return routine
                }

                print("✅ Synced \(self.routines.count) routines from Firestore")
            }
    }

    func saveRoutineToFirestore(routine: Routine, userId: String) {
        db.collection("users").document(userId).collection("routines").document(routine.id)
            .setData([
                "name": routine.name,
                "emoji": routine.emoji,
                "tasks": try? JSONEncoder().encode(routine.tasks),
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("❌ Save error: \(error)")
                } else {
                    print("✅ Routine saved to Firestore")
                }
            }
    }
}
```

### **Android: Firestore Integration**

```kotlin
// File: android/app/src/main/java/com/pulse/app/data/service/FirestoreService.kt

import com.google.firebase.firestore.FirebaseFirestore
import com.pulse.app.data.models.Routine
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.tasks.await

class FirestoreService {
    private val db = FirebaseFirestore.getInstance()

    suspend fun uploadRoutine(userId: String, routine: Routine) {
        try {
            db.collection("users").document(userId)
                .collection("routines").document(routine.id)
                .set(routine)
                .await()
            println("✅ Routine uploaded to Firestore")
        } catch (e: Exception) {
            println("❌ Upload error: ${e.message}")
        }
    }

    fun getRoutinesFromFirestore(userId: String): Flow<List<Routine>> = flowOf()
    // Implementation with Firestore listeners
}
```

---

## **Part 5: Offline-First Strategy**

### **Sync Logic Flow**

```
User Action (Create Routine)
    ↓
Save to Local DB immediately (Core Data / Room)
    ↓
Update UI (optimistic update)
    ↓
Queue sync job
    ↓
[When online] Sync to Firebase
    ↓
Resolve conflicts (last-write-wins)
    ↓
Download other users' data
```

### **Conflict Resolution**

```swift
// iOS Example
func syncRoutines(userId: String) {
    let localRoutines = RoutineRepository.shared.fetchRoutines()

    for routine in localRoutines {
        FirestoreService().saveRoutineToFirestore(routine: routine, userId: userId)
    }

    // Listen for remote changes
    FirestoreService().startListeningToRoutines(userId: userId)
}
```

---

## **Part 6: Authentication Integration**

### **iOS: Apple Sign-In + Firebase**

```swift
// Update AuthService.swift
import AuthenticationServices

func signInWithApple(completion: @escaping (Result<User, AuthError>) -> Void) {
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
}

// Handle Apple Sign-In response
func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
        let idToken = appleIDCredential.identityToken
        let nonce = appleIDCredential.nonce

        // Exchange for Firebase token
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: String(data: idToken!, encoding: .utf8)!,
            rawNonce: nonce
        )

        Auth.auth().signIn(with: credential) { result, error in
            if let user = result?.user {
                // User authenticated!
                let pulseUser = User(id: user.uid, name: user.displayName ?? "", email: user.email ?? "")
                self.currentUser = pulseUser
                self.isAuthenticated = true
            }
        }
    }
}
```

### **Android: Firebase Auth**

```kotlin
// File: android/app/src/main/java/com/pulse/app/service/AuthService.kt

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.pulse.app.data.models.User

class AuthService {
    private val auth = FirebaseAuth.getInstance()

    fun signInWithGoogle(idToken: String, onSuccess: (User) -> Unit, onError: (Exception) -> Unit) {
        val credential = GoogleAuthProvider.getCredential(idToken, null)

        auth.signInWithCredential(credential)
            .addOnSuccessListener { result ->
                val firebaseUser = result.user
                if (firebaseUser != null) {
                    val user = User(
                        id = firebaseUser.uid,
                        name = firebaseUser.displayName ?: "",
                        email = firebaseUser.email ?: ""
                    )
                    onSuccess(user)
                }
            }
            .addOnFailureListener { onError(it) }
    }

    fun getCurrentUser(): User? {
        val firebaseUser = auth.currentUser
        return firebaseUser?.let {
            User(
                id = it.uid,
                name = it.displayName ?: "",
                email = it.email ?: ""
            )
        }
    }

    fun signOut() {
        auth.signOut()
    }
}
```

---

## **Part 7: Testing the Integration**

### **iOS: Test Core Data + Firestore**

```swift
func testRoutinePersistence() {
    // 1. Save locally
    let routine = Routine(name: "Test Routine")
    RoutineRepository.shared.saveRoutine(routine)

    // 2. Verify local storage
    let fetched = RoutineRepository.shared.fetchRoutines()
    assert(fetched.contains { $0.name == "Test Routine" }, "❌ Local save failed")

    // 3. Sync to Firestore
    FirestoreService().saveRoutineToFirestore(routine: routine, userId: "test_user")

    // 4. Verify remote storage
    // Check Firestore console
}
```

### **Android: Test Room + Firestore**

```kotlin
@RunWith(AndroidJUnit4::class)
class RoutineRepositoryTest {
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()

    private lateinit var database: PulseDatabase
    private lateinit var repository: RoutineRepository

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(
            InstrumentationRegistry.getInstrumentation().context,
            PulseDatabase::class.java
        ).build()
        repository = RoutineRepository(database.routineDao())
    }

    @Test
    fun testInsertAndRetrieveRoutine() = runBlocking {
        val routine = Routine(name = "Test")
        repository.insertRoutine(routine)

        repository.getAllRoutines().collect { routines ->
            assert(routines.isNotEmpty())
            assert(routines.first().name == "Test")
        }
    }
}
```

---

## **Deployment Checklist**

- [ ] Firebase project created and configured
- [ ] Firestore security rules secured (not in test mode)
- [ ] OAuth credentials configured (Apple + Google)
- [ ] Cloud Functions deployed
- [ ] iOS: GoogleService-Info.plist added to Xcode
- [ ] Android: google-services.json added to app/
- [ ] Core Data model created and entities defined
- [ ] Room entities created with DAOs
- [ ] Both platforms pass offline-first tests
- [ ] Sync logic tested with intermittent connectivity
- [ ] Authentication tested end-to-end

---

## **Next Steps**

1. ✅ Create Firebase project
2. ✅ Set up Core Data (iOS)
3. ✅ Set up Room (Android)
4. ✅ Implement repositories
5. ✅ Create Firestore sync logic
6. ✅ Test offline-first behavior
7. → Launch app with persistence!

---

**The persistence layer is the foundation of MVP success. Get this right!** 🚀
