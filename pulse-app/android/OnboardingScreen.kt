package com.pulse.app.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

// MARK: - Onboarding Container
@Composable
fun OnboardingScreen(authViewModel: AuthViewModel) {
    val onboardingViewModel = remember { OnboardingViewModel() }
    val currentStep by onboardingViewModel.currentStep.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PulseColors.darkBg)
    ) {
        // Progress indicator
        Column(modifier = Modifier.fillMaxSize()) {
            // Step indicator
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Step ${currentStep + 1} of 4",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = PulseColors.secondary
                )

                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    repeat(4) { index ->
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .background(
                                    color = if (index <= currentStep) PulseColors.accent else PulseColors.separator,
                                    shape = RectangleShape
                                )
                        )
                    }
                }
            }

            // Current screen
            Box(modifier = Modifier
                .fillMaxSize()
                .padding(bottom = 0.dp)
            ) {
                when (currentStep) {
                    0 -> WelcomeScreenComposeContent(
                        onboardingViewModel = onboardingViewModel,
                        authViewModel = authViewModel
                    )
                    1 -> ProfileSetupScreenComposeContent(onboardingViewModel = onboardingViewModel)
                    2 -> RoutineSelectionScreenComposeContent(onboardingViewModel = onboardingViewModel)
                    3 -> NotificationPreferencesScreenComposeContent(onboardingViewModel = onboardingViewModel)
                }
            }
        }
    }
}

// MARK: - Onboarding View Model
class OnboardingViewModel : ViewModel() {
    private val _currentStep = MutableStateFlow(0)
    val currentStep: StateFlow<Int> = _currentStep

    private val _userName = MutableStateFlow("")
    val userName: StateFlow<String> = _userName

    private val _userEmail = MutableStateFlow("")
    val userEmail: StateFlow<String> = _userEmail

    private val _primaryFocus = MutableStateFlow("productivity")
    val primaryFocus: StateFlow<String> = _primaryFocus

    private val _selectedRoutines = MutableStateFlow<Set<String>>(emptySet())
    val selectedRoutines: StateFlow<Set<String>> = _selectedRoutines

    private val _notificationFrequency = MutableStateFlow("balanced")
    val notificationFrequency: StateFlow<String> = _notificationFrequency

    fun nextStep() {
        if (_currentStep.value < 3) {
            _currentStep.value += 1
        }
    }

    fun previousStep() {
        if (_currentStep.value > 0) {
            _currentStep.value -= 1
        }
    }

    fun updateUserName(name: String) {
        _userName.value = name
    }

    fun updatePrimaryFocus(focus: String) {
        _primaryFocus.value = focus
    }

    fun toggleRoutine(name: String) {
        val updated = _selectedRoutines.value.toMutableSet()
        if (updated.contains(name)) {
            updated.remove(name)
        } else {
            updated.add(name)
        }
        _selectedRoutines.value = updated
    }

    fun updateNotificationFrequency(frequency: String) {
        _notificationFrequency.value = frequency
    }
}

// MARK: - Welcome Screen
@Composable
fun WelcomeScreenComposeContent(
    onboardingViewModel: OnboardingViewModel,
    authViewModel: AuthViewModel
) {
    var isSigningIn by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceEvenly
    ) {
        Spacer(modifier = Modifier.height(20.dp))

        // Logo
        Text(
            "Pulse",
            fontSize = 56.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.accent
        )

        // Title & Subtitle
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(vertical = 24.dp)
        ) {
            Text(
                "Your Personal AI Assistant\nfor Daily Excellence",
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
                color = PulseColors.text,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                lineHeight = 28.sp
            )

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                "Automate habits, connect with\ncommunities, unlock your potential—\nall on your device.",
                fontSize = 16.sp,
                fontWeight = FontWeight.Normal,
                color = PulseColors.secondary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                lineHeight = 22.sp
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Sign In Buttons
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            // Apple Button
            Button(
                onClick = {
                    isSigningIn = true
                    authViewModel.signInWithApple()
                    onboardingViewModel.nextStep()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.Black),
                shape = RoundedCornerShape(8.dp),
                enabled = !isSigningIn
            ) {
                Icon(
                    Icons.Filled.Face,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Color.White
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text("Sign in with Apple", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }

            // Google Button
            Button(
                onClick = {
                    isSigningIn = true
                    authViewModel.signInWithGoogle()
                    onboardingViewModel.nextStep()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent),
                shape = RoundedCornerShape(8.dp),
                border = androidx.compose.foundation.border(1.dp, PulseColors.separator, RoundedCornerShape(8.dp)),
                enabled = !isSigningIn
            ) {
                Icon(
                    Icons.Filled.Search,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = PulseColors.text
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text("Sign in with Google", color = PulseColors.text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }

            // Guest Button
            TextButton(
                onClick = { onboardingViewModel.nextStep() },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Continue as Guest", color = PulseColors.secondary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Privacy Notice
        Text(
            "Privacy-first. On-device. Yours.",
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = PulseColors.secondary
        )
    }
}

// MARK: - Profile Setup Screen
@Composable
fun ProfileSetupScreenComposeContent(onboardingViewModel: OnboardingViewModel) {
    val userName by onboardingViewModel.userName.collectAsState()
    val primaryFocus by onboardingViewModel.primaryFocus.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp, vertical = 20.dp)
    ) {
        // Header
        Text(
            "Let's Set Up Your Profile",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )

        Text(
            "Just a few quick questions",
            fontSize = 14.sp,
            color = PulseColors.secondary,
            modifier = Modifier.padding(vertical = 8.dp)
        )

        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Profile Photo
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(96.dp)
                            .background(PulseColors.surface, shape = RoundedCornerShape(50.dp))
                            .border(2.dp, PulseColors.accent, shape = RoundedCornerShape(50.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Filled.Person, null, modifier = Modifier.size(36.dp), tint = PulseColors.accent)
                    }

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.align(Alignment.BottomCenter)
                    ) {
                        Text("Tap to upload photo", fontSize = 12.sp, color = PulseColors.secondary)
                    }
                }
            }

            // Name Input
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Full Name", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)

                    TextField(
                        value = userName,
                        onValueChange = { onboardingViewModel.updateUserName(it) },
                        placeholder = { Text("e.g., Alex Chen", color = PulseColors.secondary) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(PulseColors.surface, shape = RoundedCornerShape(8.dp)),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = PulseColors.surface,
                            unfocusedContainerColor = PulseColors.surface,
                            focusedTextColor = PulseColors.text,
                            unfocusedTextColor = PulseColors.text
                        )
                    )
                }
            }

            // Primary Focus Picker
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Primary Focus", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)

                    var expanded by remember { mutableStateOf(false) }

                    Box {
                        Button(
                            onClick = { expanded = true },
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(PulseColors.surface, shape = RoundedCornerShape(8.dp)),
                            colors = ButtonDefaults.buttonColors(containerColor = PulseColors.surface)
                        ) {
                            Text(primaryFocus.replaceFirstChar { it.uppercase() }, color = PulseColors.text, modifier = Modifier.weight(1f))
                            Icon(Icons.Filled.KeyboardArrowDown, null, tint = PulseColors.text)
                        }

                        DropdownMenu(
                            expanded = expanded,
                            onDismissRequest = { expanded = false },
                            modifier = Modifier.background(PulseColors.surface)
                        ) {
                            listOf("productivity", "creative", "fitness", "family", "hobbies").forEach { option ->
                                DropdownMenuItem(
                                    text = { Text(option.replaceFirstChar { it.uppercase() }) },
                                    onClick = {
                                        onboardingViewModel.updatePrimaryFocus(option)
                                        expanded = false
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }

        // Navigation Buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 20.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = { /* previous */ },
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PulseColors.surface)
            ) {
                Text("Back", color = PulseColors.secondary)
            }

            Button(
                onClick = { /* next */ },
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PulseColors.accent)
            ) {
                Text("Continue", color = PulseColors.darkBg, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// MARK: - Routine Selection Screen
@Composable
fun RoutineSelectionScreenComposeContent(onboardingViewModel: OnboardingViewModel) {
    val selectedRoutines by onboardingViewModel.selectedRoutines.collectAsState()

    val routineTemplates = listOf(
        Triple("Morning Routine", "📅", "Exercise → Breakfast → Meditation → Work"),
        Triple("Productivity Boost", "🎯", "Focus Session → Break → Review Progress"),
        Triple("Evening Wind-down", "🌙", "Review Day → Reflection → Sleep Prep"),
        Triple("Fitness Challenge", "💪", "Warmup → Workout → Cool Down → Hydrate"),
        Triple("Creative Time", "🎨", "Brainstorm → Create → Review → Iterate"),
        Triple("Family Time", "👨‍👩‍👧", "Dinner → Games → Bedtime Stories → Sleep"),
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp, vertical = 20.dp)
    ) {
        Text(
            "Choose Your First Routines",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )

        Text(
            "Pick one or more to get started",
            fontSize = 14.sp,
            color = PulseColors.secondary,
            modifier = Modifier.padding(vertical = 8.dp)
        )

        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(routineTemplates.size) { index ->
                val (name, emoji, description) = routineTemplates[index]
                val isSelected = selectedRoutines.contains(name)

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            PulseColors.surface,
                            shape = RoundedCornerShape(12.dp)
                        )
                        .border(
                            width = if (isSelected) 2.dp else 0.dp,
                            color = if (isSelected) PulseColors.accent else Color.Transparent,
                            shape = RoundedCornerShape(12.dp)
                        )
                        .clickable { onboardingViewModel.toggleRoutine(name) }
                        .padding(16.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(emoji, fontSize = 24.sp)
                                Spacer(modifier = Modifier.width(12.dp))

                                Column {
                                    Text(name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)
                                    Text("15 min", fontSize = 12.sp, color = PulseColors.secondary)
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))
                            Text(description, fontSize = 13.sp, color = PulseColors.secondary, maxLines = 2)
                        }

                        Icon(
                            imageVector = if (isSelected) Icons.Filled.CheckCircle else Icons.Filled.Circle,
                            contentDescription = null,
                            tint = if (isSelected) PulseColors.accent else PulseColors.separator,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        }

        // Navigation Buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 20.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = { /* previous */ },
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PulseColors.surface)
            ) {
                Text("Back", color = PulseColors.secondary)
            }

            Button(
                onClick = { /* next */ },
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PulseColors.accent)
            ) {
                Text("Continue", color = PulseColors.darkBg, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// MARK: - Notification Preferences Screen
@Composable
fun NotificationPreferencesScreenComposeContent(onboardingViewModel: OnboardingViewModel) {
    val frequency by onboardingViewModel.notificationFrequency.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp, vertical = 20.dp)
    ) {
        Text(
            "Notification Preferences",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )

        Text(
            "Choose how Pulse reminds you",
            fontSize = 14.sp,
            color = PulseColors.secondary,
            modifier = Modifier.padding(vertical = 8.dp)
        )

        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Text("Reminder Frequency", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PulseColors.text)
            }

            items(3) { index ->
                val options = listOf(
                    "gentle" to "Gentle (1 reminder/day)",
                    "balanced" to "Balanced (3-5/day)",
                    "assertive" to "Assertive (10+/day)"
                )
                val (value, label) = options[index]
                val isSelected = frequency == value

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onboardingViewModel.updateNotificationFrequency(value) }
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        imageVector = if (isSelected) Icons.Filled.RadioButtonChecked else Icons.Filled.RadioButtonUnchecked,
                        contentDescription = null,
                        tint = if (isSelected) PulseColors.accent else PulseColors.separator,
                        modifier = Modifier.size(24.dp)
                    )

                    Text(label, fontSize = 14.sp, color = PulseColors.text)
                }
            }
        }

        // Complete Button
        Button(
            onClick = { /* complete */ },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            colors = ButtonDefaults.buttonColors(containerColor = PulseColors.accent)
        ) {
            Text("🎉 Complete Setup!", color = PulseColors.darkBg, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}
