package com.example.pulse.android

import android.content.Context
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.FieldValue
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.tasks.await
import java.util.*

// MARK: - Routine Repository
class RoutineRepository(context: Context) {
    private val db = PulseDatabase.getDatabase(context)
    private val routineDao = db.routineDao()
    private val taskDao = db.taskDao()
    private val firestore = FirebaseFirestore.getInstance()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    // MARK: - Fetch Operations

    fun getAllRoutines(): Flow<List<Routine>> {
        return routineDao.getAllRoutines()
            .distinctUntilChanged()
            .map { entities ->
                entities.map { entity ->
                    val tasks = taskDao.getRoutineTasks(entity.id)
                        .firstOrNull() ?: emptyList()
                    entity.toDomain(tasks)
                }
            }
    }

    fun getIncompleteRoutines(): Flow<List<Routine>> {
        return routineDao.getIncompleteRoutines()
            .distinctUntilChanged()
            .map { entities ->
                entities.map { entity ->
                    val tasks = taskDao.getRoutineTasks(entity.id)
                        .firstOrNull() ?: emptyList()
                    entity.toDomain(tasks)
                }
            }
    }

    fun getRoutine(id: String): Flow<Routine?> {
        return routineDao.getRoutine(id)
            .distinctUntilChanged()
            .map { entity ->
                if (entity != null) {
                    val tasks = taskDao.getRoutineTasks(entity.id)
                        .firstOrNull() ?: emptyList()
                    entity.toDomain(tasks)
                } else null
            }
    }

    // MARK: - Save Operations

    suspend fun saveRoutine(routine: Routine) {
        try {
            // 1. Save to local database (optimistic update)
            val routineEntity = RoutineEntity(
                id = routine.id,
                name = routine.name,
                emoji = routine.emoji,
                schedule = routine.schedule.name.lowercase(),
                createdAt = System.currentTimeMillis(),
                synced = false
            )

            routineDao.insert(routineEntity)

            // Save tasks
            routine.tasks.forEach { task ->
                val taskEntity = RoutineTaskEntity(
                    id = task.id,
                    routineId = routine.id,
                    name = task.name,
                    order = task.order,
                    isCompleted = task.isCompleted,
                    estimatedDuration = task.estimatedDuration ?: 0
                )
                taskDao.insert(taskEntity)
            }

            // 2. Sync to Firestore asynchronously
            syncRoutineToFirestore(routine)
        } catch (e: Exception) {
            throw e
        }
    }

    // MARK: - Update Operations

    suspend fun updateRoutine(routine: Routine) {
        try {
            val routineEntity = RoutineEntity(
                id = routine.id,
                name = routine.name,
                emoji = routine.emoji,
                schedule = routine.schedule.name.lowercase(),
                updatedAt = System.currentTimeMillis(),
                synced = false
            )

            routineDao.update(routineEntity)

            // Update tasks
            taskDao.deleteRoutineTasks(routine.id)
            routine.tasks.forEach { task ->
                val taskEntity = RoutineTaskEntity(
                    id = task.id,
                    routineId = routine.id,
                    name = task.name,
                    order = task.order,
                    isCompleted = task.isCompleted,
                    estimatedDuration = task.estimatedDuration ?: 0
                )
                taskDao.insert(taskEntity)
            }

            syncRoutineToFirestore(routine)
        } catch (e: Exception) {
            throw e
        }
    }

    // MARK: - Delete Operations

    suspend fun deleteRoutine(id: String) {
        try {
            routineDao.delete(
                RoutineEntity(
                    id = id,
                    name = "",
                    emoji = ""
                )
            )

            // Delete from Firestore
            try {
                firestore.collection("routines").document(id).delete().await()
            } catch (e: Exception) {
                // Firestore deletion failed, mark for retry
            }
        } catch (e: Exception) {
            throw e
        }
    }

    // MARK: - Task Operations

    suspend fun completeTask(routineId: String, taskId: String) {
        try {
            val taskFlow = taskDao.getTask(taskId).firstOrNull()
            if (taskFlow != null) {
                val updated = taskFlow.copy(
                    isCompleted = true,
                    completedAt = System.currentTimeMillis()
                )
                taskDao.update(updated)

                // Sync to Firestore
                val routine = routineDao.getRoutine(routineId).firstOrNull()
                if (routine != null) {
                    val tasks = taskDao.getRoutineTasks(routineId).firstOrNull() ?: emptyList()
                    syncRoutineToFirestore(routine.toDomain(tasks))
                }
            }
        } catch (e: Exception) {
            throw e
        }
    }

    // MARK: - Firestore Sync

    private suspend fun syncRoutineToFirestore(routine: Routine) {
        _isSyncing.value = true

        try {
            val tasksData = routine.tasks.map { task ->
                mapOf(
                    "id" to task.id,
                    "name" to task.name,
                    "order" to task.order,
                    "isCompleted" to task.isCompleted,
                    "estimatedDuration" to (task.estimatedDuration ?: 0)
                )
            }

            val routineData = mapOf(
                "name" to routine.name,
                "emoji" to routine.emoji,
                "schedule" to routine.schedule.name.lowercase(),
                "tasks" to tasksData,
                "updatedAt" to FieldValue.serverTimestamp()
            )

            firestore.collection("routines")
                .document(routine.id)
                .set(routineData, SetOptions.merge())
                .await()

            // Mark as synced in local database
            val routineEntity = routineDao.getRoutine(routine.id).firstOrNull()
            if (routineEntity != null) {
                routineDao.update(routineEntity.copy(synced = true))
            }
        } catch (e: Exception) {
            // Mark for retry on next sync
            val routineEntity = routineDao.getRoutine(routine.id).firstOrNull()
            if (routineEntity != null) {
                routineDao.update(routineEntity.copy(synced = false))
            }
            throw e
        } finally {
            _isSyncing.value = false
        }
    }

    // MARK: - Firestore Listener

    fun setupFirestoreListener(userId: String? = null) {
        val query = if (userId != null) {
            firestore.collection("routines").whereEqualTo("userId", userId)
        } else {
            firestore.collection("routines")
        }

        query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                return@addSnapshotListener
            }

            snapshot?.documentChanges?.forEach { change ->
                when {
                    change.type.name == "ADDED" || change.type.name == "MODIFIED" -> {
                        val data = change.document.data
                        mergeFirestoreData(data, change.document.id)
                    }
                    change.type.name == "REMOVED" -> {
                        // Handle deleted routine
                    }
                }
            }
        }
    }

    private fun mergeFirestoreData(data: Map<String, Any>, documentId: String) {
        // Check if local version is more recent
        val localRoutine = routineDao.getRoutine(documentId)

        // If local is newer or equal, don't overwrite
        // Otherwise merge remote changes
    }

    // MARK: - Conflict Resolution

    private fun hasLocalChanges(localRoutine: RoutineEntity, remoteData: Map<String, Any>): Boolean {
        return localRoutine.synced.not()
    }
}

// MARK: - Post Repository

class PostRepository(context: Context) {
    private val db = PulseDatabase.getDatabase(context)
    private val postDao = db.postDao()
    private val firestore = FirebaseFirestore.getInstance()

    suspend fun createPost(post: Post) {
        try {
            val postEntity = PostEntity(
                id = post.id,
                content = post.content,
                tribe = post.tribe,
                createdAt = System.currentTimeMillis(),
                synced = false
            )

            postDao.insert(postEntity)
            syncPostToFirestore(post)
        } catch (e: Exception) {
            throw e
        }
    }

    fun getPostsByTribe(tribe: String): Flow<List<Post>> {
        return postDao.getPostsByTribe(tribe)
            .map { entities -> entities.map { it.toDomain() } }
    }

    fun getAllPosts(): Flow<List<Post>> {
        return postDao.getAllPosts()
            .map { entities -> entities.map { it.toDomain() } }
    }

    suspend fun likePost(postId: String) {
        try {
            val post = postDao.getPost(postId).firstOrNull()
            if (post != null) {
                val updated = post.copy(
                    likeCount = post.likeCount + 1,
                    likedByUser = true
                )
                postDao.update(updated)
                syncPostToFirestore(updated.toDomain())
            }
        } catch (e: Exception) {
            throw e
        }
    }

    private suspend fun syncPostToFirestore(post: Post) {
        try {
            val postData = mapOf(
                "content" to post.content,
                "tribe" to post.tribe,
                "likeCount" to post.likeCount,
                "commentCount" to post.commentCount,
                "updatedAt" to FieldValue.serverTimestamp()
            )

            firestore.collection("posts")
                .document(post.id)
                .set(postData, SetOptions.merge())
                .await()

            val postEntity = postDao.getPost(post.id).firstOrNull()
            if (postEntity != null) {
                postDao.update(postEntity.copy(synced = true))
            }
        } catch (e: Exception) {
            // Mark for retry
        }
    }
}

// MARK: - Achievement Repository

class AchievementRepository(context: Context) {
    private val db = PulseDatabase.getDatabase(context)
    private val achievementDao = db.achievementDao()

    fun getUnlockedAchievements(): Flow<List<Achievement>> {
        return achievementDao.getUnlockedAchievements()
            .map { entities -> entities.map { it.toDomain() } }
    }

    fun getAllAchievements(): Flow<List<Achievement>> {
        return achievementDao.getAllAchievements()
            .map { entities -> entities.map { it.toDomain() } }
    }

    suspend fun unlockAchievement(achievementId: String) {
        try {
            val achievement = achievementDao.getAchievement(achievementId).firstOrNull()
            if (achievement != null) {
                val updated = achievement.copy(
                    isUnlocked = true,
                    unlockedAt = System.currentTimeMillis()
                )
                achievementDao.update(updated)
            }
        } catch (e: Exception) {
            throw e
        }
    }
}
