package com.pulse.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pulse.app.data.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// MARK: - Auth ViewModel
class AuthViewModel : ViewModel() {
    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    init {
        // Check for existing session
        restoreSession()
    }

    fun signInWithApple() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // TODO: Integrate with Firebase & Apple Sign-In
                // Mock for MVP
                val mockUser = User(
                    id = "user_" + System.currentTimeMillis(),
                    name = "Alex",
                    email = "alex@example.com"
                )
                _currentUser.value = mockUser
                _isAuthenticated.value = true
                _isLoading.value = false
                AnalyticsService.logEvent("user_signed_in", "apple")
            } catch (e: Exception) {
                _errorMessage.value = "Sign in failed"
                _isLoading.value = false
                AnalyticsService.logError("sign_in_failed", e)
            }
        }
    }

    fun signInWithGoogle() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // TODO: Integrate with Firebase & Google Sign-In
                // Mock for MVP
                val mockUser = User(
                    id = "user_" + System.currentTimeMillis(),
                    name = "Alex",
                    email = "alex@example.com"
                )
                _currentUser.value = mockUser
                _isAuthenticated.value = true
                _isLoading.value = false
                AnalyticsService.logEvent("user_signed_in", "google")
            } catch (e: Exception) {
                _errorMessage.value = "Sign in failed"
                _isLoading.value = false
                AnalyticsService.logError("sign_in_failed", e)
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            try {
                // TODO: Sign out from Firebase & OAuth
                _currentUser.value = null
                _isAuthenticated.value = false
                AnalyticsService.logEvent("user_signed_out")
            } catch (e: Exception) {
                _errorMessage.value = "Sign out failed"
                AnalyticsService.logError("sign_out_failed", e)
            }
        }
    }

    private fun restoreSession() {
        viewModelScope.launch {
            try {
                // TODO: Check local storage for saved session
                // For now, start unauthenticated
                _isAuthenticated.value = false
            } catch (e: Exception) {
                AnalyticsService.logError("restore_session_failed", e)
            }
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }
}

// MARK: - Routine ViewModel
class RoutineViewModel : ViewModel() {
    private val _routines = MutableStateFlow<List<Routine>>(emptyList())
    val routines: StateFlow<List<Routine>> = _routines.asStateFlow()

    private val _selectedRoutine = MutableStateFlow<Routine?>(null)
    val selectedRoutine: StateFlow<Routine?> = _selectedRoutine.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    init {
        loadRoutines()
    }

    fun loadRoutines() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // TODO: Load from Room database
                // Mock data for MVP
                val mockRoutines = MockData.mockRoutines
                _routines.value = mockRoutines
                _isLoading.value = false
                AnalyticsService.logEvent("routines_loaded", "count" to mockRoutines.size)
            } catch (e: Exception) {
                _errorMessage.value = "Failed to load routines"
                _isLoading.value = false
                AnalyticsService.logError("load_routines_failed", e)
            }
        }
    }

    fun createRoutine(routine: Routine) {
        viewModelScope.launch {
            try {
                // TODO: Save to Room database
                val updated = _routines.value + routine
                _routines.value = updated
                AnalyticsService.logEvent("routine_created", "name" to routine.name)
            } catch (e: Exception) {
                _errorMessage.value = "Failed to create routine"
                AnalyticsService.logError("create_routine_failed", e)
            }
        }
    }

    fun updateRoutine(routine: Routine) {
        viewModelScope.launch {
            try {
                // TODO: Update in Room database
                val updated = _routines.value.map { if (it.id == routine.id) routine else it }
                _routines.value = updated
                if (_selectedRoutine.value?.id == routine.id) {
                    _selectedRoutine.value = routine
                }
                AnalyticsService.logEvent("routine_updated", "name" to routine.name)
            } catch (e: Exception) {
                _errorMessage.value = "Failed to update routine"
                AnalyticsService.logError("update_routine_failed", e)
            }
        }
    }

    fun deleteRoutine(routineId: String) {
        viewModelScope.launch {
            try {
                // TODO: Delete from Room database
                val updated = _routines.value.filter { it.id != routineId }
                _routines.value = updated
                if (_selectedRoutine.value?.id == routineId) {
                    _selectedRoutine.value = null
                }
                AnalyticsService.logEvent("routine_deleted", "id" to routineId)
            } catch (e: Exception) {
                _errorMessage.value = "Failed to delete routine"
                AnalyticsService.logError("delete_routine_failed", e)
            }
        }
    }

    fun selectRoutine(routine: Routine) {
        _selectedRoutine.value = routine
    }

    fun completeRoutine(routine: Routine) {
        viewModelScope.launch {
            try {
                val completed = routine.copy(
                    tasks = routine.tasks.map { it.complete() }
                )
                updateRoutine(completed)
                AnalyticsService.logEvent("routine_completed", "name" to routine.name)
            } catch (e: Exception) {
                AnalyticsService.logError("complete_routine_failed", e)
            }
        }
    }

    fun completeTask(routine: Routine, taskId: String) {
        viewModelScope.launch {
            try {
                val completed = routine.copy(
                    tasks = routine.tasks.map {
                        if (it.id == taskId) it.complete() else it
                    }
                )
                updateRoutine(completed)
                AnalyticsService.logEvent("task_completed", "id" to taskId)
            } catch (e: Exception) {
                AnalyticsService.logError("complete_task_failed", e)
            }
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }
}

// MARK: - Community ViewModel
class CommunityViewModel : ViewModel() {
    private val _posts = MutableStateFlow<List<Post>>(emptyList())
    val posts: StateFlow<List<Post>> = _posts.asStateFlow()

    private val _tribes = MutableStateFlow<List<Tribe>>(Tribe.allTribes)
    val tribes: StateFlow<List<Tribe>> = _tribes.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    init {
        loadPosts()
    }

    fun loadPosts() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // TODO: Load from Firestore
                val mockPosts = MockData.mockPosts
                _posts.value = mockPosts
                _isLoading.value = false
                AnalyticsService.logEvent("posts_loaded", "count" to mockPosts.size)
            } catch (e: Exception) {
                _isLoading.value = false
                AnalyticsService.logError("load_posts_failed", e)
            }
        }
    }

    fun createPost(post: Post) {
        viewModelScope.launch {
            try {
                // TODO: Save to Firestore
                val updated = _posts.value + post
                _posts.value = updated
                AnalyticsService.logEvent("post_created")
            } catch (e: Exception) {
                AnalyticsService.logError("create_post_failed", e)
            }
        }
    }
}

// MARK: - Achievement ViewModel
class AchievementViewModel : ViewModel() {
    private val _achievements = MutableStateFlow<List<Achievement>>(Achievement.allAchievements)
    val achievements: StateFlow<List<Achievement>> = _achievements.asStateFlow()

    private val _streaks = MutableStateFlow<List<Streak>>(emptyList())
    val streaks: StateFlow<List<Streak>> = _streaks.asStateFlow()

    init {
        loadAchievements()
    }

    fun loadAchievements() {
        viewModelScope.launch {
            try {
                // TODO: Load from Room database
                val achievements = Achievement.allAchievements
                _achievements.value = achievements
                AnalyticsService.logEvent("achievements_loaded", "count" to achievements.size)
            } catch (e: Exception) {
                AnalyticsService.logError("load_achievements_failed", e)
            }
        }
    }

    fun unlockAchievement(achievement: Achievement) {
        viewModelScope.launch {
            try {
                // TODO: Save to database
                val updated = achievement.copy(unlockedAt = System.currentTimeMillis())
                val newList = _achievements.value.map {
                    if (it.id == achievement.id) updated else it
                }
                _achievements.value = newList
                AnalyticsService.logEvent("achievement_unlocked", "name" to achievement.name)
            } catch (e: Exception) {
                AnalyticsService.logError("unlock_achievement_failed", e)
            }
        }
    }
}

// MARK: - Analytics Service
object AnalyticsService {
    fun logEvent(name: String, vararg pairs: Pair<String, Any>) {
        val properties = pairs.toMap()
        var message = "📊 Analytics: $name"
        if (properties.isNotEmpty()) {
            message += " - $properties"
        }
        println(message)
        // TODO: Send to PostHog/Firebase Analytics
    }

    fun logError(context: String, error: Exception) {
        println("⚠️ Error $context: ${error.message}")
        // TODO: Send to Sentry
    }
}
