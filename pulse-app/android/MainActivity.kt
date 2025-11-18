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

// MARK: - Placeholder Screens (Phase 2 Implementation)

@Composable
fun HomeScreen(routineViewModel: RoutineViewModel) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(PulseColors.darkBg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "🏠 Home",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Routines & Quick Stats Coming Soon",
            color = PulseColors.secondary
        )
    }
}

@Composable
fun RoutinesListScreen(routineViewModel: RoutineViewModel) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(PulseColors.darkBg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "📋 Routines",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Routine Management Coming Soon",
            color = PulseColors.secondary
        )
    }
}

@Composable
fun CommunityFeedScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(PulseColors.darkBg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "👥 Community",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Community Feed Coming Soon",
            color = PulseColors.secondary
        )
    }
}

@Composable
fun AchievementsScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(PulseColors.darkBg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "🏆 Achievements",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Badges & Streaks Coming Soon",
            color = PulseColors.secondary
        )
    }
}

@Composable
fun SettingsScreen(authViewModel: AuthViewModel) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(PulseColors.darkBg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "⚙️ Settings",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = PulseColors.text
        )
        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = { authViewModel.signOut() },
            colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
            modifier = Modifier
                .width(200.dp)
                .height(48.dp)
        ) {
            Text("Sign Out", color = Color.White)
        }

        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Settings Coming Soon",
            color = PulseColors.secondary
        )
    }
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
