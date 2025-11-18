package com.example.pulse.android

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow

// MARK: - Settings Screen
@Composable
fun SettingsScreenContent(
    authService: AuthViewModel = remember { AuthViewModel() },
    viewModel: SettingsViewModel = remember { SettingsViewModel() }
) {
    val user by viewModel.user.collectAsState(initial = null)
    val notificationFrequency by viewModel.notificationFrequency.collectAsState(initial = "Balanced")
    val notificationStyle by viewModel.notificationStyle.collectAsState(initial = "Text + Emoji")
    val dndEnabled by viewModel.dndEnabled.collectAsState(initial = false)
    val darkModeEnabled by viewModel.darkModeEnabled.collectAsState(initial = true)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PulseColors.darkBg)
    ) {
        // Top Bar with Title
        TopAppBar(
            title = { Text("Settings", color = PulseColors.text, fontSize = 18.sp, fontWeight = FontWeight.Bold) },
            backgroundColor = PulseColors.darkBg,
            elevation = 0.dp
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // User Profile Section
            item {
                SettingsSectionHeader(title = "👤 Profile")
            }

            item {
                if (user != null) {
                    ProfileCardContent(
                        user = user!!,
                        onEditProfile = { viewModel.toggleEditProfile() }
                    )
                } else {
                    Text("Loading...", color = PulseColors.secondary)
                }
            }

            // Notifications Section
            item {
                SettingsSectionHeader(title = "🔔 Notifications")
            }

            item {
                SettingsDropdownItem(
                    label = "Frequency",
                    value = notificationFrequency,
                    options = listOf("Gentle", "Balanced", "Assertive"),
                    onSelect = { viewModel.setNotificationFrequency(it) }
                )
            }

            item {
                SettingsDropdownItem(
                    label = "Style",
                    value = notificationStyle,
                    options = listOf("Text + Emoji + Sound", "Text + Emoji", "Silent"),
                    onSelect = { viewModel.setNotificationStyle(it) }
                )
            }

            item {
                SettingsToggleItem(
                    label = "Do Not Disturb",
                    value = dndEnabled,
                    onToggle = { viewModel.toggleDND() }
                )
            }

            // Appearance Section
            item {
                SettingsSectionHeader(title = "🎨 Appearance")
            }

            item {
                SettingsToggleItem(
                    label = "Dark Mode",
                    value = darkModeEnabled,
                    onToggle = { viewModel.toggleDarkMode() }
                )
            }

            // Privacy & Security Section
            item {
                SettingsSectionHeader(title = "🔒 Privacy & Security")
            }

            item {
                SettingsMenuItemContent(
                    icon = Icons.Filled.Lock,
                    label = "Privacy Policy",
                    subtitle = "View our privacy policy",
                    onClick = { /* Open privacy policy */ }
                )
            }

            item {
                SettingsMenuItemContent(
                    icon = Icons.Filled.Description,
                    label = "Terms of Service",
                    subtitle = "Read our terms and conditions",
                    onClick = { /* Open terms */ }
                )
            }

            item {
                SettingsMenuItemContent(
                    icon = Icons.Filled.Security,
                    label = "Change Password",
                    subtitle = "Update your account password",
                    onClick = { /* Show password change dialog */ }
                )
            }

            // About Section
            item {
                SettingsSectionHeader(title = "ℹ️ About")
            }

            item {
                SettingsInfoItem(
                    label = "App Version",
                    value = "1.0.0"
                )
            }

            item {
                SettingsInfoItem(
                    label = "Build Number",
                    value = "2025.11.18"
                )
            }

            item {
                SettingsMenuItemContent(
                    icon = Icons.Filled.Feedback,
                    label = "Send Feedback",
                    subtitle = "Help us improve Pulse",
                    onClick = { /* Open feedback form */ }
                )
            }

            // Sign Out Section
            item {
                Spacer(modifier = Modifier.height(20.dp))
                Button(
                    onClick = { authService.signOut() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFF4757),
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text("Sign Out", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            item {
                Spacer(modifier = Modifier.height(20.dp))
            }
        }
    }
}

// MARK: - Settings Section Header
@Composable
fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        fontSize = 14.sp,
        fontWeight = FontWeight.SemiBold,
        color = PulseColors.secondary,
        modifier = Modifier.padding(vertical = 8.dp)
    )
}

// MARK: - Profile Card
@Composable
fun ProfileCardContent(
    user: User,
    onEditProfile: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp)),
        colors = CardDefaults.cardColors(
            containerColor = PulseColors.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Profile Photo
            Surface(
                modifier = Modifier
                    .size(80.dp)
                    .clip(CircleShape),
                color = PulseColors.separator
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Text(
                        text = user.name.take(2).uppercase(),
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = PulseColors.accent
                    )
                }
            }

            // User Info
            Text(
                text = user.name,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = PulseColors.text
            )

            Text(
                text = user.email,
                fontSize = 12.sp,
                color = PulseColors.secondary
            )

            // Edit Profile Button
            Button(
                onClick = onEditProfile,
                modifier = Modifier
                    .width(120.dp)
                    .height(36.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = PulseColors.accent,
                    contentColor = PulseColors.darkBg
                ),
                shape = RoundedCornerShape(6.dp)
            ) {
                Text("Edit Profile", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// MARK: - Settings Dropdown Item
@Composable
fun SettingsDropdownItem(
    label: String,
    value: String,
    options: List<String>,
    onSelect: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp)),
        colors = CardDefaults.cardColors(
            containerColor = PulseColors.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { expanded = !expanded }
                    .padding(12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = label,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = PulseColors.text
                    )
                    Text(
                        text = value,
                        fontSize = 12.sp,
                        color = PulseColors.secondary
                    )
                }

                Icon(
                    imageVector = if (expanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                    contentDescription = null,
                    tint = PulseColors.accent,
                    modifier = Modifier.size(20.dp)
                )
            }

            if (expanded) {
                Divider(color = PulseColors.separator)

                Column {
                    options.forEach { option ->
                        DropdownMenuItem(
                            text = {
                                Text(
                                    text = option,
                                    fontSize = 12.sp,
                                    color = PulseColors.text
                                )
                            },
                            onClick = {
                                onSelect(option)
                                expanded = false
                            },
                            modifier = Modifier.background(
                                if (option == value) PulseColors.accent.copy(alpha = 0.1f)
                                else Color.Transparent
                            )
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Settings Toggle Item
@Composable
fun SettingsToggleItem(
    label: String,
    value: Boolean,
    onToggle: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp)),
        colors = CardDefaults.cardColors(
            containerColor = PulseColors.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onToggle() }
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = label,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = PulseColors.text
            )

            Switch(
                checked = value,
                onCheckedChange = { onToggle() },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = PulseColors.accent,
                    checkedTrackColor = PulseColors.accent.copy(alpha = 0.3f),
                    uncheckedThumbColor = PulseColors.separator,
                    uncheckedTrackColor = PulseColors.separator.copy(alpha = 0.3f)
                )
            )
        }
    }
}

// MARK: - Settings Menu Item
@Composable
fun SettingsMenuItemContent(
    icon: ImageVector,
    label: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = PulseColors.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = PulseColors.accent,
                modifier = Modifier.size(20.dp)
            )

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = label,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = PulseColors.text
                )
                Text(
                    text = subtitle,
                    fontSize = 12.sp,
                    color = PulseColors.secondary
                )
            }

            Icon(
                imageVector = Icons.Filled.ChevronRight,
                contentDescription = null,
                tint = PulseColors.secondary,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

// MARK: - Settings Info Item
@Composable
fun SettingsInfoItem(
    label: String,
    value: String
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp)),
        colors = CardDefaults.cardColors(
            containerColor = PulseColors.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = label,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = PulseColors.text
            )

            Text(
                text = value,
                fontSize = 12.sp,
                color = PulseColors.secondary
            )
        }
    }
}

// MARK: - Settings View Model
class SettingsViewModel : androidx.lifecycle.ViewModel() {
    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user

    private val _notificationFrequency = MutableStateFlow("Balanced")
    val notificationFrequency: StateFlow<String> = _notificationFrequency

    private val _notificationStyle = MutableStateFlow("Text + Emoji")
    val notificationStyle: StateFlow<String> = _notificationStyle

    private val _dndEnabled = MutableStateFlow(false)
    val dndEnabled: StateFlow<Boolean> = _dndEnabled

    private val _darkModeEnabled = MutableStateFlow(true)
    val darkModeEnabled: StateFlow<Boolean> = _darkModeEnabled

    private val _editProfileVisible = MutableStateFlow(false)
    val editProfileVisible: StateFlow<Boolean> = _editProfileVisible

    init {
        loadUserData()
    }

    private fun loadUserData() {
        // Mock user data
        _user.value = User(
            id = "user_123",
            name = "Alex Smith",
            email = "alex@example.com",
            joinedTribes = listOf("Productivity", "Creators"),
            preferences = UserPreferences(
                notificationFrequency = "Balanced",
                notificationStyle = "Text + Emoji"
            )
        )
        AnalyticsService.shared.logEvent("settings_loaded")
    }

    fun setNotificationFrequency(frequency: String) {
        _notificationFrequency.value = frequency
        AnalyticsService.shared.logEvent("notification_frequency_changed")
    }

    fun setNotificationStyle(style: String) {
        _notificationStyle.value = style
        AnalyticsService.shared.logEvent("notification_style_changed")
    }

    fun toggleDND() {
        _dndEnabled.value = !_dndEnabled.value
        AnalyticsService.shared.logEvent("dnd_toggled")
    }

    fun toggleDarkMode() {
        _darkModeEnabled.value = !_darkModeEnabled.value
        AnalyticsService.shared.logEvent("dark_mode_toggled")
    }

    fun toggleEditProfile() {
        _editProfileVisible.value = !_editProfileVisible.value
    }
}
