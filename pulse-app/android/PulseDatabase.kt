package com.example.pulse.android

import android.content.Context
import androidx.room.*
import kotlinx.coroutines.flow.Flow

// MARK: - Pulse Database
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
                )
                    .fallbackToDestructiveMigration()
                    .build()

                INSTANCE = instance
                instance
            }
        }
    }
}

// MARK: - DAOs

@Dao
interface UserDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(user: UserEntity)

    @Query("SELECT * FROM users WHERE id = :id")
    fun getUser(id: String): Flow<UserEntity?>

    @Query("SELECT * FROM users")
    fun getAllUsers(): Flow<List<UserEntity>>

    @Update
    suspend fun update(user: UserEntity)

    @Delete
    suspend fun delete(user: UserEntity)

    @Query("DELETE FROM users")
    suspend fun deleteAll()
}

@Dao
interface RoutineDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(routine: RoutineEntity)

    @Query("SELECT * FROM routines WHERE id = :id")
    fun getRoutine(id: String): Flow<RoutineEntity?>

    @Query("SELECT * FROM routines WHERE userId IS NULL ORDER BY createdAt DESC")
    fun getAllRoutines(): Flow<List<RoutineEntity>>

    @Query("SELECT * FROM routines WHERE userId = :userId ORDER BY createdAt DESC")
    fun getUserRoutines(userId: String): Flow<List<RoutineEntity>>

    @Query("SELECT * FROM routines WHERE completedToday = 0 ORDER BY createdAt DESC")
    fun getIncompleteRoutines(): Flow<List<RoutineEntity>>

    @Update
    suspend fun update(routine: RoutineEntity)

    @Delete
    suspend fun delete(routine: RoutineEntity)

    @Query("DELETE FROM routines")
    suspend fun deleteAll()
}

@Dao
interface TaskDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(task: RoutineTaskEntity)

    @Query("SELECT * FROM routine_tasks WHERE routineId = :routineId ORDER BY `order` ASC")
    fun getRoutineTasks(routineId: String): Flow<List<RoutineTaskEntity>>

    @Query("SELECT * FROM routine_tasks WHERE id = :taskId")
    fun getTask(taskId: String): Flow<RoutineTaskEntity?>

    @Update
    suspend fun update(task: RoutineTaskEntity)

    @Delete
    suspend fun delete(task: RoutineTaskEntity)

    @Query("DELETE FROM routine_tasks WHERE routineId = :routineId")
    suspend fun deleteRoutineTasks(routineId: String)
}

@Dao
interface PostDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(post: PostEntity)

    @Query("SELECT * FROM posts WHERE tribe = :tribe ORDER BY createdAt DESC LIMIT :limit")
    fun getPostsByTribe(tribe: String, limit: Int = 20): Flow<List<PostEntity>>

    @Query("SELECT * FROM posts ORDER BY createdAt DESC LIMIT :limit")
    fun getAllPosts(limit: Int = 50): Flow<List<PostEntity>>

    @Query("SELECT * FROM posts WHERE id = :id")
    fun getPost(id: String): Flow<PostEntity?>

    @Query("SELECT * FROM posts WHERE authorId = :authorId ORDER BY createdAt DESC")
    fun getAuthorPosts(authorId: String): Flow<List<PostEntity>>

    @Update
    suspend fun update(post: PostEntity)

    @Delete
    suspend fun delete(post: PostEntity)

    @Query("DELETE FROM posts")
    suspend fun deleteAll()
}

@Dao
interface AchievementDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(achievement: AchievementEntity)

    @Query("SELECT * FROM achievements WHERE isUnlocked = 1 ORDER BY unlockedAt DESC")
    fun getUnlockedAchievements(): Flow<List<AchievementEntity>>

    @Query("SELECT * FROM achievements WHERE isUnlocked = 0")
    fun getLockedAchievements(): Flow<List<AchievementEntity>>

    @Query("SELECT * FROM achievements ORDER BY isUnlocked DESC")
    fun getAllAchievements(): Flow<List<AchievementEntity>>

    @Query("SELECT * FROM achievements WHERE id = :id")
    fun getAchievement(id: String): Flow<AchievementEntity?>

    @Update
    suspend fun update(achievement: AchievementEntity)

    @Delete
    suspend fun delete(achievement: AchievementEntity)
}

// MARK: - Database Entities

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    val avatar: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "routines",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["userId"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index("userId")
    ]
)
data class RoutineEntity(
    @PrimaryKey val id: String = java.util.UUID.randomUUID().toString(),
    val userId: String? = null,
    val name: String,
    val emoji: String = "📋",
    val schedule: String = "daily",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val completedToday: Boolean = false,
    val synced: Boolean = false
)

@Entity(
    tableName = "routine_tasks",
    foreignKeys = [
        ForeignKey(
            entity = RoutineEntity::class,
            parentColumns = ["id"],
            childColumns = ["routineId"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index("routineId")
    ]
)
data class RoutineTaskEntity(
    @PrimaryKey val id: String = java.util.UUID.randomUUID().toString(),
    val routineId: String,
    val name: String,
    val order: Int = 0,
    val isCompleted: Boolean = false,
    val estimatedDuration: Int = 0,
    val completedAt: Long? = null
)

@Entity(
    tableName = "posts",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["authorId"],
            onDelete = ForeignKey.CASCADE,
            onUpdate = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index("authorId"),
        Index("tribe")
    ]
)
data class PostEntity(
    @PrimaryKey val id: String = java.util.UUID.randomUUID().toString(),
    val authorId: String? = null,
    val content: String,
    val tribe: String,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val likeCount: Int = 0,
    val commentCount: Int = 0,
    val likedByUser: Boolean = false,
    val synced: Boolean = false
)

@Entity(tableName = "achievements")
data class AchievementEntity(
    @PrimaryKey val id: String,
    val name: String,
    val icon: String,
    val description: String? = null,
    val isUnlocked: Boolean = false,
    val unlockedAt: Long? = null
)

// MARK: - Conversion Extensions

fun RoutineEntity.toDomain(tasks: List<RoutineTaskEntity> = emptyList()): Routine {
    return Routine(
        id = id,
        name = name,
        emoji = emoji,
        schedule = RoutineSchedule.valueOf(schedule.uppercase()),
        tasks = tasks.sortedBy { it.order }.map { taskEntity ->
            RoutineTask(
                id = taskEntity.id,
                name = taskEntity.name,
                order = taskEntity.order,
                isCompleted = taskEntity.isCompleted,
                estimatedDuration = if (taskEntity.estimatedDuration > 0) taskEntity.estimatedDuration else null
            )
        }
    )
}

fun PostEntity.toDomain(): Post {
    return Post(
        id = id,
        author = authorId ?: "Anonymous",
        content = content,
        tribe = tribe,
        createdAt = createdAt,
        likeCount = likeCount,
        commentCount = commentCount,
        totalReactions = likeCount + commentCount,
        likedByUser = likedByUser
    )
}

fun AchievementEntity.toDomain(): Achievement {
    return Achievement(
        id = id,
        name = name,
        icon = icon,
        description = description,
        isUnlocked = isUnlocked
    )
}
