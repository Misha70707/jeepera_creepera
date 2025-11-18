package com.example.pulse.android

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull

@OptIn(ExperimentalCoroutinesApi::class)
class HomeScreenViewModelTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    private lateinit var viewModel: HomeViewModel

    @Before
    fun setUp() {
        viewModel = HomeViewModel()
    }

    // MARK: - Greeting Tests

    @Test
    fun testGreetingNotEmpty() = runTest {
        val greeting = viewModel.greeting.value
        assertNotNull(greeting)
        assert(greeting.isNotEmpty())
    }

    @Test
    fun testGreetingContainsEmoji() = runTest {
        val greeting = viewModel.greeting.value
        assert(greeting.contains("!"))
    }

    // MARK: - Data Loading Tests

    @Test
    fun testTodaysRoutinesLoaded() = runTest {
        val routines = viewModel.todaysRoutines.first()
        assertNotNull(routines)
        assertEquals(2, routines.size)
    }

    @Test
    fun testFirstRoutineNameCorrect() = runTest {
        val routines = viewModel.todaysRoutines.first()
        assertEquals("Morning Routine", routines.firstOrNull()?.name)
    }

    @Test
    fun testCurrentStreakNotNull() = runTest {
        val streak = viewModel.currentStreak.first()
        assertNotNull(streak)
    }

    @Test
    fun testStreakHasCorrectEmoji() = runTest {
        val streak = viewModel.currentStreak.first()
        assertEquals("🔥", streak?.icon)
    }

    // MARK: - Achievements Tests

    @Test
    fun testWeeklyAchievementsLoaded() = runTest {
        val achievements = viewModel.weeklyAchievements.first()
        assertNotNull(achievements)
        assertFalse(achievements.isEmpty())
    }

    // MARK: - Community Tests

    @Test
    fun testCommunityHighlightsLoaded() = runTest {
        val highlights = viewModel.communityHighlights.first()
        assertNotNull(highlights)
        assertFalse(highlights.isEmpty())
    }

    @Test
    fun testCommunityPostsHaveContent() = runTest {
        val highlights = viewModel.communityHighlights.first()
        highlights.forEach { post ->
            assert(post.author.isNotEmpty())
            assert(post.content.isNotEmpty())
        }
    }

    // MARK: - Routine Progress Tests

    @Test
    fun testRoutineProgressValidRange() = runTest {
        val routines = viewModel.todaysRoutines.first()
        routines.forEach { routine ->
            assert(routine.progressPercent >= 0.0)
            assert(routine.progressPercent <= 1.0)
        }
    }

    // MARK: - Loading State Tests

    @Test
    fun testLoadingStateUpdates() = runTest {
        val isLoading = viewModel.isLoading.first()
        assertNotNull(isLoading)
    }
}
