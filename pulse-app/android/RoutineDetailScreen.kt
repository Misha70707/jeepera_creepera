package com.pulse.app.ui.screens

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import com.pulse.app.data.models.Routine
import com.pulse.app.data.models.RoutineTask
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.text.SimpleDateFormat
import java.util.*

// MARK: - Routine Detail Screen
@Composable
fun RoutineDetailScreen(routine: Routine, onDismiss: () -> Unit) {
    val viewModel = remember { RoutineDetailViewModel(routine) }
    val tasks by viewModel.tasks.collectAsState()
    val completedCount by viewModel.completedCount.collectAsState()
    val progress by viewModel.progressPercent.collectAsState()
    val currentTaskIndex by viewModel.currentTaskIndex.collectAsState()
    val showConfetti by viewModel.showConfetti.collectAsState()

    val allTasksComplete = completedCount == tasks.size && tasks.isNotEmpty()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PulseColors.darkBg)
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp, vertical = 20.dp)
        ) {
            // Header
            item {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.Top
                    ) {
                        Text(routine.emoji, fontSize = 36.sp)

                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                routine.name,
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold,
                                color = PulseColors.text
                            )

                            Text(
                                "Started at ${viewModel.startTime}",
                                fontSize = 12.sp,
                                color = PulseColors.secondary
                            )
                        }
                    }

                    // Progress Section
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                "Progress: $completedCount/${tasks.size} tasks",
                                fontSize = 12.sp,
                                color = PulseColors.secondary
                            )

                            Text(
                                "${(progress * 100).toInt()}%",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = PulseColors.accent
                            )
                        }

                        LinearProgressIndicator(
                            progress = { progress.toFloat() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp),
                            color = PulseColors.accent,
                            trackColor = PulseColors.separator,
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
            }

            // Tasks List
            itemsIndexed(tasks) { index, task ->
                TaskItemContent(
                    task = task,
                    isCurrentTask = index == currentTaskIndex,
                    onToggle = { viewModel.toggleTask(task) }
                )
            }

            // Timer for current task (if applicable)
            if (currentTaskIndex < tasks.size) {
                val currentTask = tasks[currentTaskIndex]
                if (!currentTask.isCompleted && currentTask.estimatedDuration != null) {
                    item {
                        Spacer(modifier = Modifier.height(16.dp))
                        TimerCardContent(
                            taskName = currentTask.name,
                            duration = currentTask.estimatedDuration!!,
                            onComplete = { viewModel.toggleTask(currentTask) }
                        )
                    }
                }
            }

            // Action Buttons
            item {
                Spacer(modifier = Modifier.height(20.dp))

                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Button(
                            onClick = { viewModel.skipCurrentTask() },
                            modifier = Modifier
                                .weight(1f)
                                .height(44.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = PulseColors.surface)
                        ) {
                            Text("Skip Task", color = PulseColors.secondary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                        }

                        if (allTasksComplete) {
                            Button(
                                onClick = {
                                    viewModel.completeRoutine()
                                    onDismiss()
                                },
                                modifier = Modifier
                                    .weight(1f)
                                    .height(44.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = PulseColors.success)
                            ) {
                                Text("🎉 Finish", color = PulseColors.darkBg, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                            }
                        } else {
                            Button(
                                onClick = { viewModel.skipCurrentTask() },
                                modifier = Modifier
                                    .weight(1f)
                                    .height(44.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = PulseColors.accent)
                            ) {
                                Text("Next Task", color = PulseColors.darkBg, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }

                    Button(
                        onClick = { onDismiss() },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(44.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = PulseColors.surface)
                    ) {
                        Text("Close", color = PulseColors.secondary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
            }
        }

        // Confetti Animation
        if (showConfetti) {
            ConfettiAnimationContent()
        }
    }
}

// MARK: - Routine Detail ViewModel
class RoutineDetailViewModel(private val routine: Routine) : ViewModel() {
    private val _tasks = MutableStateFlow(routine.tasks)
    val tasks: StateFlow<List<RoutineTask>> = _tasks

    private val _completedCount = MutableStateFlow(routine.tasks.count { it.isCompleted })
    val completedCount: StateFlow<Int> = _completedCount

    private val _progressPercent = MutableStateFlow(
        if (routine.tasks.isEmpty()) 0.0
        else routine.tasks.count { it.isCompleted }.toDouble() / routine.tasks.size
    )
    val progressPercent: StateFlow<Double> = _progressPercent

    private val _currentTaskIndex = MutableStateFlow(
        routine.tasks.indexOfFirst { !it.isCompleted }.let { if (it == -1) 0 else it }
    )
    val currentTaskIndex: StateFlow<Int> = _currentTaskIndex

    private val _showConfetti = MutableStateFlow(false)
    val showConfetti: StateFlow<Boolean> = _showConfetti

    val startTime: String
        get() = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date())

    fun toggleTask(task: RoutineTask) {
        val index = _tasks.value.indexOfFirst { it.id == task.id }
        if (index >= 0) {
            val updated = _tasks.value.toMutableList()
            updated[index] = updated[index].copy(
                isCompleted = !updated[index].isCompleted,
                completedAt = if (!updated[index].isCompleted) System.currentTimeMillis() else null
            )
            _tasks.value = updated

            // Update counters
            _completedCount.value = updated.count { it.isCompleted }
            _progressPercent.value = if (updated.isEmpty()) 0.0
            else updated.count { it.isCompleted }.toDouble() / updated.size

            // Move to next incomplete task
            val nextIncomplete = updated.indexOfFirst { !it.isCompleted }
            if (nextIncomplete >= 0) {
                _currentTaskIndex.value = nextIncomplete
            }
        }
    }

    fun skipCurrentTask() {
        val currentIndex = _currentTaskIndex.value
        if (currentIndex < _tasks.value.size - 1) {
            _currentTaskIndex.value = currentIndex + 1
        }
    }

    fun completeRoutine() {
        val updated = _tasks.value.toMutableList()
        for (i in updated.indices) {
            if (!updated[i].isCompleted) {
                updated[i] = updated[i].copy(
                    isCompleted = true,
                    completedAt = System.currentTimeMillis()
                )
            }
        }
        _tasks.value = updated
        _completedCount.value = updated.size
        _progressPercent.value = 1.0
        _showConfetti.value = true
    }
}

// MARK: - Task Item
@Composable
fun TaskItemContent(
    task: RoutineTask,
    isCurrentTask: Boolean,
    onToggle: () -> Void
) {
    val backgroundColor by animateColorAsState(
        targetValue = if (isCurrentTask) PulseColors.surface else PulseColors.surface.copy(alpha = 0.6f),
        label = "taskBgColor"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp)
            .clickable { onToggle() },
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        border = if (isCurrentTask) {
            BorderStroke(2.dp, PulseColors.accent)
        } else {
            null
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Checkbox
            Icon(
                imageVector = if (task.isCompleted) Icons.Filled.CheckCircle else Icons.Filled.Circle,
                contentDescription = null,
                modifier = Modifier.size(22.dp),
                tint = if (task.isCompleted) PulseColors.success
                else if (isCurrentTask) PulseColors.accent
                else PulseColors.separator
            )

            // Task info
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    task.name,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = PulseColors.text,
                    textDecoration = if (task.isCompleted) androidx.compose.ui.text.TextDecoration.LineThrough else androidx.compose.ui.text.TextDecoration.None
                )

                if (task.estimatedDuration != null) {
                    Text(
                        "Est. ${task.estimatedDuration / 60} min",
                        fontSize = 12.sp,
                        color = PulseColors.secondary
                    )
                }
            }

            // Completion time
            if (task.completedAt != null) {
                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    Text("✓", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = PulseColors.success)
                    Text(
                        SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(task.completedAt!!)),
                        fontSize = 10.sp,
                        color = PulseColors.secondary
                    )
                }
            }
        }
    }
}

// MARK: - Timer Card
@Composable
fun TimerCardContent(
    taskName: String,
    duration: Long,
    onComplete: () -> Void
) {
    var timeRemaining by remember { mutableStateOf(duration) }
    var isRunning by remember { mutableStateOf(false) }

    LaunchedEffect(isRunning) {
        if (isRunning) {
            while (isRunning && timeRemaining > 0) {
                kotlinx.coroutines.delay(1000)
                timeRemaining -= 1000
            }
            if (timeRemaining <= 0) {
                isRunning = false
                onComplete()
            }
        }
    }

    val minutes = (timeRemaining / 1000) / 60
    val seconds = (timeRemaining / 1000) % 60
    val formattedTime = String.format("%02d:%02d", minutes, seconds)

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = PulseColors.surface)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                "Timer for $taskName",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = PulseColors.secondary
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Time Remaining", fontSize = 12.sp, color = PulseColors.secondary)
                    Text(
                        formattedTime,
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        color = PulseColors.accent,
                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        onClick = { isRunning = !isRunning },
                        modifier = Modifier.size(44.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = PulseColors.accent),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Icon(
                            imageVector = if (isRunning) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                            contentDescription = null,
                            tint = PulseColors.darkBg,
                            modifier = Modifier.size(16.dp)
                        )
                    }

                    Button(
                        onClick = { timeRemaining = duration },
                        modifier = Modifier
                            .width(44.dp)
                            .height(32.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = PulseColors.surface),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text("Reset", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.secondary)
                    }
                }
            }

            Button(
                onClick = { onComplete() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PulseColors.success)
            ) {
                Text("Done", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.darkBg)
            }
        }
    }
}

// MARK: - Confetti Animation
@Composable
fun ConfettiAnimationContent() {
    // Simplified confetti - in production would use more sophisticated animation
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.2f))
    ) {
        // Show celebration emojis
        val emojis = listOf("🎉", "🎊", "⭐", "✨", "🎈")
        val positions = remember {
            List(15) {
                Pair(
                    kotlin.random.Random.nextFloat() * 400,
                    kotlin.random.Random.nextFloat() * 800
                )
            }
        }

        positions.forEachIndexed { index, (x, y) ->
            Text(
                emojis[index % emojis.size],
                fontSize = (20..32).random().sp,
                modifier = Modifier
                    .offset(
                        x.dp,
                        y.dp
                    )
            )
        }
    }
}
