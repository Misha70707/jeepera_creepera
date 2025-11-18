package com.pulse.app.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.*

// MARK: - Data Models

// User Profile
@Entity(tableName = "users")
data class User(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    val avatarUrl: String? = null,
    val bio: String? = null,
    val joinedTribes: String = "", // Comma-separated list
    val createdAt: Long = System.currentTimeMillis(),
    val preferences: String = "" // JSON serialized preferences
)

data class UserPreferences(
    val notificationFrequency: String = "balanced",
    val notificationStyle: String = "textAndEmoji",
    val darkMode: Boolean = true,
    val soundEnabled: Boolean = true,
    val doNotDisturbStart: Long? = null,
    val doNotDisturbEnd: Long? = null
)

// MARK: - Routine & Task

@Entity(tableName = "routines")
data class Routine(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val description: String? = null,
    val emoji: String = "📋",
    val schedule: String = "daily",
    val startTime: Long? = null,
    val estimatedDuration: Long = 1800000, // 30 min in ms
    val isActive: Boolean = true,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    fun getTasks(): List<RoutineTask> = emptyList() // Populated from Room

    var tasks: List<RoutineTask> = emptyList()

    val totalTasks: Int get() = tasks.size
    val completedTasks: Int get() = tasks.count { it.isCompleted }
    val progressPercent: Double get() =
        if (totalTasks > 0) completedTasks.toDouble() / totalTasks else 0.0

    companion object {
        val scheduleOptions = listOf("daily", "weekdays", "weekends", "weekly", "custom")
    }
}

@Entity(
    tableName = "routine_tasks",
    foreignKeys = [
        androidx.room.ForeignKey(
            entity = Routine::class,
            parentColumns = ["id"],
            childColumns = ["routineId"],
            onDelete = androidx.room.ForeignKey.CASCADE
        )
    ]
)
data class RoutineTask(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val routineId: String,
    val name: String,
    val description: String? = null,
    val estimatedDuration: Long? = null, // in milliseconds
    val isCompleted: Boolean = false,
    val completedAt: Long? = null,
    val order: Int = 0
) {
    fun complete(): RoutineTask = this.copy(
        isCompleted = true,
        completedAt = System.currentTimeMillis()
    )

    fun reset(): RoutineTask = this.copy(
        isCompleted = false,
        completedAt = null
    )
}

// MARK: - Community

@Entity(tableName = "posts")
data class Post(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val authorId: String,
    val author: String,
    val content: String,
    val imageUrl: String? = null,
    val tribeId: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val reactions: String = "{}", // JSON serialized {emoji -> count}
    val commentCount: Int = 0,
    val viewCount: Int = 0
) {
    fun getTotalReactions(): Int {
        // Parse reactions JSON and sum
        return 0 // TODO: Implement
    }
}

@Entity(tableName = "comments")
data class Comment(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val postId: String,
    val authorId: String,
    val author: String,
    val content: String,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "tribes")
data class Tribe(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val description: String? = null,
    val icon: String = "👥",
    val memberCount: Int = 0,
    val createdAt: Long = System.currentTimeMillis()
) {
    companion object {
        val productivity = Tribe(
            id = "tribe_productivity",
            name = "Productivity",
            icon = "📊"
        )
        val creators = Tribe(
            id = "tribe_creators",
            name = "Creators",
            icon = "🎨"
        )
        val fitness = Tribe(
            id = "tribe_fitness",
            name = "Fitness",
            icon = "💪"
        )
        val parents = Tribe(
            id = "tribe_parents",
            name = "Parents",
            icon = "👨‍👩‍👧"
        )
        val gamers = Tribe(
            id = "tribe_gamers",
            name = "Gamers",
            icon = "🎮"
        )

        val allTribes = listOf(productivity, creators, fitness, parents, gamers)
    }
}

// MARK: - Achievements

@Entity(tableName = "achievements")
data class Achievement(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val description: String,
    val icon: String,
    val rarity: String = "common", // common, rare, epic, legendary
    val unlockedAt: Long? = null,
    val progress: Float? = null // 0-1 for in-progress
) {
    val isUnlocked: Boolean get() = unlockedAt != null

    companion object {
        val firstRoutine = Achievement(
            id = "ach_first_routine",
            name = "Getting Started",
            description = "Complete your first routine",
            icon = "🎯",
            rarity = "common"
        )

        val sevenDayStreak = Achievement(
            id = "ach_7day_streak",
            name = "Week Warrior",
            description = "Maintain a 7-day streak",
            icon = "🔥",
            rarity = "rare"
        )

        val thirtyDayStreak = Achievement(
            id = "ach_30day_streak",
            name = "Monthly Champion",
            description = "Maintain a 30-day streak",
            icon = "👑",
            rarity = "epic"
        )

        val allAchievements = listOf(firstRoutine, sevenDayStreak, thirtyDayStreak)
    }
}

// MARK: - Streaks

@Entity(tableName = "streaks")
data class Streak(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val icon: String,
    val currentCount: Int = 0,
    val bestCount: Int = 0,
    val lastCompletedDate: Long? = null,
    val startDate: Long = System.currentTimeMillis()
) {
    val isActive: Boolean
        get() {
            lastCompletedDate ?: return false
            val dayInMs = 24 * 60 * 60 * 1000
            val daysSinceLastCompletion = (System.currentTimeMillis() - lastCompletedDate!!) / dayInMs
            return daysSinceLastCompletion <= 1
        }

    fun recordCompletion(): Streak = this.copy(
        currentCount = currentCount + 1,
        bestCount = maxOf(currentCount + 1, bestCount),
        lastCompletedDate = System.currentTimeMillis()
    )

    fun reset(): Streak = this.copy(
        currentCount = 0,
        lastCompletedDate = null
    )
}

// MARK: - UI Models

data class RoutineWithTasks(
    val routine: Routine,
    val tasks: List<RoutineTask>
)

data class PostWithAuthor(
    val post: Post,
    val author: User
)

// MARK: - Mock Data

object MockData {
    val mockUser = User(
        id = "user_123",
        name = "Alex",
        email = "alex@example.com"
    )

    val mockRoutines = listOf(
        Routine(name = "Morning Routine").copy(emoji = "📅"),
        Routine(name = "Productivity Boost").copy(emoji = "🎯"),
        Routine(name = "Evening Wind-down").copy(emoji = "🌙")
    )

    val mockPosts = listOf(
        Post(
            authorId = "user_456",
            author = "maya_creates",
            content = "Just hit my 30-day streak! 🔥 Feeling amazing and motivated!",
            tribeId = "tribe_creators"
        ),
        Post(
            authorId = "user_789",
            author = "jordan_family",
            content = "Family chore system is working great! Kids are earning badges.",
            tribeId = "tribe_parents"
        )
    )
}
