package com.pulse.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModelProvider
import com.pulse.app.ui.screens.*
import com.pulse.app.ui.theme.PulseTheme
import com.pulse.app.viewmodel.AuthViewModel
import com.pulse.app.viewmodel.RoutineViewModel

class MainActivity : ComponentActivity() {
    private lateinit var authViewModel: AuthViewModel
    private lateinit var routineViewModel: RoutineViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize ViewModels
        authViewModel = ViewModelProvider(this).get(AuthViewModel::class.java)
        routineViewModel = ViewModelProvider(this).get(RoutineViewModel::class.java)

        setContent {
            PulseTheme {
                PulseApp(
                    authViewModel = authViewModel,
                    routineViewModel = routineViewModel
                )
            }
        }
    }
}

// MARK: - Main App Composable
@Composable
fun PulseApp(
    authViewModel: AuthViewModel,
    routineViewModel: RoutineViewModel
) {
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()

    if (isAuthenticated) {
        MainTabScreen(
            authViewModel = authViewModel,
            routineViewModel = routineViewModel
        )
    } else {
        OnboardingScreen(authViewModel = authViewModel)
    }
}

// MARK: - Main Tab Navigation
@Composable
fun MainTabScreen(
    authViewModel: AuthViewModel,
    routineViewModel: RoutineViewModel
) {
    var selectedTab by remember { mutableStateOf(NavigationTab.Home) }

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = PulseColors.darkBg,
                contentColor = PulseColors.text
            ) {
                NavigationTab.values().forEach { tab ->
                    NavigationBarItem(
                        icon = {
                            when (tab) {
                                NavigationTab.Home -> Icon(Icons.Filled.Home, contentDescription = "Home")
                                NavigationTab.Routines -> Icon(Icons.Filled.List, contentDescription = "Routines")
                                NavigationTab.Community -> Icon(Icons.Filled.Group, contentDescription = "Community")
                                NavigationTab.Achievements -> Icon(Icons.Filled.Star, contentDescription = "Achievements")
                                NavigationTab.Settings -> Icon(Icons.Filled.Settings, contentDescription = "Settings")
                            }
                        },
                        label = { Text(tab.label) },
                        selected = selectedTab == tab,
                        onClick = { selectedTab = tab },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = PulseColors.accent,
                            selectedTextColor = PulseColors.accent,
                            unselectedIconColor = PulseColors.secondary,
                            unselectedTextColor = PulseColors.secondary,
                            indicatorColor = Color.Transparent
                        )
                    )
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(PulseColors.darkBg)
        ) {
            when (selectedTab) {
                NavigationTab.Home -> HomeScreen(routineViewModel = routineViewModel)
                NavigationTab.Routines -> RoutinesListScreen(routineViewModel = routineViewModel)
                NavigationTab.Community -> CommunityFeedScreen()
                NavigationTab.Achievements -> AchievementsScreen()
                NavigationTab.Settings -> SettingsScreen(authViewModel = authViewModel)
            }
        }
    }
}

enum class NavigationTab(val label: String) {
    Home("Home"),
    Routines("Routines"),
    Community("Community"),
    Achievements("Achievements"),
    Settings("Settings")
}

// MARK: - Screen Implementations (Phase 2 Complete)

@Composable
fun HomeScreen(routineViewModel: RoutineViewModel) {
    HomeScreenContent()
}

@Composable
fun RoutinesListScreen(routineViewModel: RoutineViewModel) {
    RoutinesListScreenContent()
}

@Composable
fun CommunityFeedScreen() {
    CommunityScreenContent()
}

@Composable
fun AchievementsScreen() {
    AchievementsScreenContent()
}

@Composable
fun SettingsScreen(authViewModel: AuthViewModel) {
    SettingsScreenContent(authService = authViewModel)
}

// MARK: - Theme & Colors
object PulseColors {
    val accent = Color(0xFF00D4FF)  // Cyan
    val darkBg = Color(0xFF0A1428)   // Dark Navy
    val surface = Color(0xFF1A1F2E)  // Charcoal
    val text = Color(0xFFE8ECEF)     // Off-white
    val secondary = Color(0xFFA0A8B2) // Silver
    val separator = Color(0xFF2D3748) // Slate

    // Semantic
    val success = Color(0xFF4AEE6F)   // Lime Green
    val warning = Color(0xFFFFA500)   // Amber
    val error = Color(0xFFFF6B6B)     // Coral Red
}
