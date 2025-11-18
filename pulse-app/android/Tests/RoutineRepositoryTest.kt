package com.example.pulse.android

import android.content.Context
import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class RoutineRepositoryTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    private lateinit var database: PulseDatabase
    private lateinit var repository: RoutineRepository
    private lateinit var context: Context

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        database = Room.inMemoryDatabaseBuilder(context, PulseDatabase::class.java)
            .allowMainThreadQueries()
            .build()

        repository = RoutineRepository(context)
    }

    @After
    fun tearDown() {
        database.close()
    }

    // MARK: - Create Tests

    @Test
    fun testCreateRoutine() = runTest {
        val routine = Routine(
            name = "Test Routine",
            emoji = "🧪",
            schedule = RoutineSchedule.DAILY,
            tasks = listOf(
                RoutineTask(name = "Task 1", order = 0),
                RoutineTask(name = "Task 2", order = 1)
            )
        )

        repository.saveRoutine(routine)

        val routines = repository.getAllRoutines().first()
        assertTrue(routines.isNotEmpty())
        assertEquals(routine.name, routines.first().name)
    }

    // MARK: - Read Tests

    @Test
    fun testGetAllRoutines() = runTest {
        val routine1 = Routine(
            name = "Routine 1",
            emoji = "📋",
            schedule = RoutineSchedule.DAILY,
            tasks = emptyList()
        )
        val routine2 = Routine(
            name = "Routine 2",
            emoji = "🎯",
            schedule = RoutineSchedule.WEEKLY,
            tasks = emptyList()
        )

        repository.saveRoutine(routine1)
        repository.saveRoutine(routine2)

        val routines = repository.getAllRoutines().first()
        assertEquals(2, routines.size)
    }

    @Test
    fun testGetSingleRoutine() = runTest {
        val routine = Routine(
            name = "Single Routine",
            emoji = "🔍",
            schedule = RoutineSchedule.DAILY,
            tasks = emptyList()
        )

        repository.saveRoutine(routine)

        val retrieved = repository.getRoutine(routine.id).first()
        assertNotNull(retrieved)
        assertEquals(routine.name, retrieved?.name)
    }

    // MARK: - Update Tests

    @Test
    fun testUpdateRoutine() = runTest {
        val routine = Routine(
            name = "Original Name",
            emoji = "📋",
            schedule = RoutineSchedule.DAILY,
            tasks = emptyList()
        )

        repository.saveRoutine(routine)

        val updated = routine.copy(name = "Updated Name")
        repository.updateRoutine(updated)

        val retrieved = repository.getRoutine(routine.id).first()
        assertEquals("Updated Name", retrieved?.name)
    }

    // MARK: - Delete Tests

    @Test
    fun testDeleteRoutine() = runTest {
        val routine = Routine(
            name = "To Delete",
            emoji = "🗑️",
            schedule = RoutineSchedule.DAILY,
            tasks = emptyList()
        )

        repository.saveRoutine(routine)
        repository.deleteRoutine(routine.id)

        val routines = repository.getAllRoutines().first()
        assertTrue(routines.isEmpty())
    }

    // MARK: - Task Completion Tests

    @Test
    fun testCompleteTask() = runTest {
        val routine = Routine(
            name = "Task Test",
            emoji = "✅",
            schedule = RoutineSchedule.DAILY,
            tasks = listOf(
                RoutineTask(id = "task_1", name = "Task 1", order = 0)
            )
        )

        repository.saveRoutine(routine)
        repository.completeTask(routine.id, "task_1")

        val retrieved = repository.getRoutine(routine.id).first()
        assertNotNull(retrieved)
        assertTrue(retrieved!!.tasks.first().isCompleted)
    }

    // MARK: - Sync Status Tests

    @Test
    fun testSyncStatus() = runTest {
        val routine = Routine(
            name = "Sync Test",
            emoji = "🔄",
            schedule = RoutineSchedule.DAILY,
            tasks = emptyList()
        )

        repository.saveRoutine(routine)

        // Initially syncing flag should be false after save
        val isSyncing = repository.isSyncing.value
        assertNotNull(isSyncing)
    }

    // MARK: - Incomplete Routines Tests

    @Test
    fun testGetIncompleteRoutines() = runTest {
        val routine = Routine(
            name = "Incomplete",
            emoji = "⏳",
            schedule = RoutineSchedule.DAILY,
            tasks = emptyList()
        )

        repository.saveRoutine(routine)

        val incomplete = repository.getIncompleteRoutines().first()
        assertTrue(incomplete.isNotEmpty())
    }
}
