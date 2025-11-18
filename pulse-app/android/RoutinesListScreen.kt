package com.example.pulse.android

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow

// MARK: - Routines List Screen
@Composable
fun RoutinesListScreenContent(viewModel: RoutinesListViewModel = remember { RoutinesListViewModel() }) {
    val routines by viewModel.routines.collectAsState(initial = emptyList())
    val showCreateRoutine by viewModel.showCreateRoutine.collectAsState(initial = false)
    val selectedRoutine by viewModel.selectedRoutine.collectAsState(initial = null)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PulseColors.darkBg)
    ) {
        // Top Bar with Title
        TopAppBar(
            title = {
                Text(
                    "Routines",
                    color = PulseColors.text,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
            },
            actions = {
                IconButton(onClick = { viewModel.toggleCreateRoutine() }) {
                    Icon(
                        imageVector = Icons.Filled.Add,
                        contentDescription = "Create Routine",
                        tint = PulseColors.accent,
                        modifier = Modifier.size(24.dp)
                    )
                }
            },
            backgroundColor = PulseColors.darkBg,
            elevation = 0.dp
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (routines.isEmpty()) {
                item {
                    EmptyStateContent(
                        emoji = "📋",
                        title = "No Routines Yet",
                        subtitle = "Create your first routine to get started!"
                    )
                }
            } else {
                items(routines) { routine ->
                    RoutineListItemContent(
                        routine = routine,
                        onTap = { viewModel.selectRoutine(routine) },
                        onEdit = { viewModel.editRoutine(routine) },
                        onDelete = { viewModel.deleteRoutine(routine.id) }
                    )
                }
            }

            item { Spacer(modifier = Modifier.height(20.dp)) }
        }
    }

    // Create Routine Modal
    if (showCreateRoutine) {
        CreateRoutineModalContent(
            onDismiss = { viewModel.toggleCreateRoutine() },
            onCreate = { name, emoji, schedule, tasks ->
                viewModel.createRoutine(name, emoji, schedule, tasks)
                viewModel.toggleCreateRoutine()
            }
        )
    }

    // Edit Routine Modal
    if (selectedRoutine != null) {
        EditRoutineModalContent(
            routine = selectedRoutine!!,
            onDismiss = { viewModel.selectRoutine(null) },
            onUpdate = { name, emoji, schedule, tasks ->
                viewModel.updateRoutine(selectedRoutine!!.id, name, emoji, schedule, tasks)
                viewModel.selectRoutine(null)
            }
        )
    }
}

// MARK: - Routine List Item
@Composable
fun RoutineListItemContent(
    routine: Routine,
    onTap: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    var showDeleteConfirm by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onTap),
        colors = CardDefaults.cardColors(
            containerColor = PulseColors.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = routine.emoji,
                        fontSize = 24.sp
                    )

                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = routine.name,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = PulseColors.text
                        )

                        Text(
                            text = "${routine.tasks.size} tasks • ${routine.schedule.label}",
                            fontSize = 12.sp,
                            color = PulseColors.secondary
                        )
                    }
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    IconButton(
                        onClick = onEdit,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Edit,
                            contentDescription = "Edit",
                            tint = PulseColors.accent,
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    IconButton(
                        onClick = { showDeleteConfirm = true },
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Delete,
                            contentDescription = "Delete",
                            tint = Color(0xFFFF4757),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            // Task List Preview
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(PulseColors.darkBg, shape = RoundedCornerShape(8.dp))
                    .padding(8.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                routine.tasks.take(3).forEach { task ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(4.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (task.isCompleted) Icons.Filled.CheckCircle
                            else Icons.Filled.Circle,
                            contentDescription = null,
                            tint = if (task.isCompleted) PulseColors.accent else PulseColors.separator,
                            modifier = Modifier.size(16.dp)
                        )

                        Text(
                            text = task.name,
                            fontSize = 12.sp,
                            color = PulseColors.text,
                            textDecoration = if (task.isCompleted) TextDecoration.LineThrough
                            else TextDecoration.None
                        )
                    }
                }

                if (routine.tasks.size > 3) {
                    Text(
                        text = "+ ${routine.tasks.size - 3} more tasks",
                        fontSize = 11.sp,
                        color = PulseColors.secondary,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
    }

    // Delete Confirmation
    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("Delete Routine?", color = PulseColors.text) },
            text = { Text("This cannot be undone.", color = PulseColors.secondary) },
            confirmButton = {
                Button(
                    onClick = {
                        onDelete()
                        showDeleteConfirm = false
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFF4757),
                        contentColor = Color.White
                    )
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) {
                    Text("Cancel", color = PulseColors.accent)
                }
            },
            containerColor = PulseColors.surface
        )
    }
}

// MARK: - Create Routine Modal
@Composable
fun CreateRoutineModalContent(
    onDismiss: () -> Unit,
    onCreate: (String, String, RoutineSchedule, List<RoutineTask>) -> Unit
) {
    var routineName by remember { mutableStateOf("") }
    var selectedEmoji by remember { mutableStateOf("📋") }
    var selectedSchedule by remember { mutableStateOf(RoutineSchedule.DAILY) }
    var taskInput by remember { mutableStateOf("") }
    var tasks by remember { mutableStateOf<List<RoutineTask>>(emptyList()) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create Routine", color = PulseColors.text) },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(PulseColors.darkBg),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Emoji Selector
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("📋", "🎯", "💪", "🎨", "📚", "🏃").forEach { emoji ->
                        Button(
                            onClick = { selectedEmoji = emoji },
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(8.dp)),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (selectedEmoji == emoji) PulseColors.accent
                                else PulseColors.surface,
                                contentColor = PulseColors.text
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(emoji, fontSize = 20.sp)
                        }
                    }
                }

                // Routine Name
                TextField(
                    value = routineName,
                    onValueChange = { routineName = it },
                    label = { Text("Routine Name") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = TextFieldDefaults.textFieldColors(
                        containerColor = PulseColors.surface,
                        textColor = PulseColors.text
                    )
                )

                // Schedule Dropdown
                ExposedDropdownMenuBox(
                    expanded = false,
                    onExpandedChange = {}
                ) {
                    TextField(
                        value = selectedSchedule.label,
                        onValueChange = {},
                        label = { Text("Schedule") },
                        readOnly = true,
                        modifier = Modifier.fillMaxWidth(),
                        colors = TextFieldDefaults.textFieldColors(
                            containerColor = PulseColors.surface,
                            textColor = PulseColors.text
                        )
                    )
                }

                // Tasks Input
                TextField(
                    value = taskInput,
                    onValueChange = { taskInput = it },
                    label = { Text("Add Task") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 40.dp),
                    colors = TextFieldDefaults.textFieldColors(
                        containerColor = PulseColors.surface,
                        textColor = PulseColors.text
                    )
                )

                // Add Task Button
                if (taskInput.isNotBlank()) {
                    Button(
                        onClick = {
                            tasks = tasks + RoutineTask(
                                name = taskInput,
                                order = tasks.size
                            )
                            taskInput = ""
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = PulseColors.accent,
                            contentColor = PulseColors.darkBg
                        )
                    ) {
                        Text("Add Task")
                    }
                }

                // Tasks List
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    tasks.forEach { task ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(PulseColors.surface, shape = RoundedCornerShape(6.dp))
                                .padding(8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(task.name, fontSize = 12.sp, color = PulseColors.text)
                            IconButton(
                                onClick = { tasks = tasks.filterNot { it.name == task.name } },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Close,
                                    contentDescription = "Remove",
                                    tint = Color(0xFFFF4757),
                                    modifier = Modifier.size(14.dp)
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onCreate(routineName, selectedEmoji, selectedSchedule, tasks) },
                colors = ButtonDefaults.buttonColors(
                    containerColor = PulseColors.accent,
                    contentColor = PulseColors.darkBg
                ),
                enabled = routineName.isNotBlank() && tasks.isNotEmpty()
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = PulseColors.accent)
            }
        },
        containerColor = PulseColors.surface
    )
}

// MARK: - Edit Routine Modal
@Composable
fun EditRoutineModalContent(
    routine: Routine,
    onDismiss: () -> Unit,
    onUpdate: (String, String, RoutineSchedule, List<RoutineTask>) -> Unit
) {
    var routineName by remember { mutableStateOf(routine.name) }
    var selectedEmoji by remember { mutableStateOf(routine.emoji) }
    var selectedSchedule by remember { mutableStateOf(routine.schedule) }
    var tasks by remember { mutableStateOf(routine.tasks) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Routine", color = PulseColors.text) },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(PulseColors.darkBg),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Emoji Selector
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("📋", "🎯", "💪", "🎨", "📚", "🏃").forEach { emoji ->
                        Button(
                            onClick = { selectedEmoji = emoji },
                            modifier = Modifier.size(44.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (selectedEmoji == emoji) PulseColors.accent
                                else PulseColors.surface,
                                contentColor = PulseColors.text
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(emoji, fontSize = 20.sp)
                        }
                    }
                }

                // Routine Name
                TextField(
                    value = routineName,
                    onValueChange = { routineName = it },
                    label = { Text("Routine Name") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = TextFieldDefaults.textFieldColors(
                        containerColor = PulseColors.surface,
                        textColor = PulseColors.text
                    )
                )

                // Tasks List
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    tasks.forEach { task ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(PulseColors.surface, shape = RoundedCornerShape(6.dp))
                                .padding(8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(task.name, fontSize = 12.sp, color = PulseColors.text)
                            IconButton(
                                onClick = { tasks = tasks.filterNot { it.name == task.name } },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Close,
                                    contentDescription = "Remove",
                                    tint = Color(0xFFFF4757),
                                    modifier = Modifier.size(14.dp)
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onUpdate(routineName, selectedEmoji, selectedSchedule, tasks) },
                colors = ButtonDefaults.buttonColors(
                    containerColor = PulseColors.accent,
                    contentColor = PulseColors.darkBg
                ),
                enabled = routineName.isNotBlank() && tasks.isNotEmpty()
            ) {
                Text("Update")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = PulseColors.accent)
            }
        },
        containerColor = PulseColors.surface
    )
}

// MARK: - Routines List View Model
class RoutinesListViewModel : androidx.lifecycle.ViewModel() {
    private val _routines = MutableStateFlow<List<Routine>>(emptyList())
    val routines: StateFlow<List<Routine>> = _routines

    private val _showCreateRoutine = MutableStateFlow(false)
    val showCreateRoutine: StateFlow<Boolean> = _showCreateRoutine

    private val _selectedRoutine = MutableStateFlow<Routine?>(null)
    val selectedRoutine: StateFlow<Routine?> = _selectedRoutine

    init {
        loadRoutines()
    }

    private fun loadRoutines() {
        // Mock routines
        _routines.value = listOf(
            Routine(
                name = "Morning Routine",
                emoji = "📅",
                tasks = listOf(
                    RoutineTask(name = "Exercise", order = 0),
                    RoutineTask(name = "Breakfast", order = 1),
                    RoutineTask(name = "Meditation", order = 2)
                )
            ),
            Routine(
                name = "Productivity Boost",
                emoji = "🎯",
                tasks = listOf(
                    RoutineTask(name = "Focus Session", order = 0),
                    RoutineTask(name = "Break", order = 1)
                )
            )
        )
        AnalyticsService.shared.logEvent("routines_loaded")
    }

    fun toggleCreateRoutine() {
        _showCreateRoutine.value = !_showCreateRoutine.value
    }

    fun selectRoutine(routine: Routine?) {
        _selectedRoutine.value = routine
    }

    fun createRoutine(name: String, emoji: String, schedule: RoutineSchedule, tasks: List<RoutineTask>) {
        val newRoutine = Routine(
            name = name,
            emoji = emoji,
            schedule = schedule,
            tasks = tasks
        )
        _routines.value = _routines.value + newRoutine
        AnalyticsService.shared.logEvent("routine_created")
    }

    fun updateRoutine(id: String, name: String, emoji: String, schedule: RoutineSchedule, tasks: List<RoutineTask>) {
        _routines.value = _routines.value.map { routine ->
            if (routine.id == id) {
                routine.copy(
                    name = name,
                    emoji = emoji,
                    schedule = schedule,
                    tasks = tasks
                )
            } else routine
        }
        AnalyticsService.shared.logEvent("routine_updated")
    }

    fun deleteRoutine(id: String) {
        _routines.value = _routines.value.filterNot { it.id == id }
        AnalyticsService.shared.logEvent("routine_deleted")
    }

    fun editRoutine(routine: Routine) {
        selectRoutine(routine)
    }
}

// MARK: - Routine Schedule Enum
enum class RoutineSchedule(val label: String) {
    DAILY("Daily"),
    WEEKLY("Weekly"),
    MONTHLY("Monthly"),
    CUSTOM("Custom")
}
